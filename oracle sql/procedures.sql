
CREATE TABLE COORDINATES_SYSTEMS (
    ID NUMBER GENERATED BY DEFAULT as IDENTITY(START with 1 INCREMENT by 1),
    epsg NUMBER,
    epsg_desc VARCHAR2(200),
    label VARCHAR2(200),
    label_advance VARCHAR2(200),
    is_dms VARCHAR2(1),
    ejemplo_coords VARCHAR2(200),
    CONSTRAINT PK_COORDINATES_SYSTEMS PRIMARY KEY (ID),
    CONSTRAINT CK_COORDINATES_SYSTEMS_isdms CHECK (is_dms IN ('Y','N'))
);
COMMENT ON TABLE "SEM_CHR_GIS"."COORDINATES_SYSTEMS" IS 'Taula que recull els sistema de coordenades interoperables del sistema Chronos';

-- acordarse de hacer commit al introducir estos valores en sql developer o si no no persistirán
INSERT INTO COORDINATES_SYSTEMS VALUES (DEFAULT, 4326, 'EPSG 4326 - WGS84', 'gps grados, minutos y segundos', 'WGS84 Geograficas (4326) GMS', 'Y', '3º 42'' 36'''' E 40º 26'' 46'''' N');
INSERT INTO COORDINATES_SYSTEMS VALUES (DEFAULT, 4326, 'EPSG 4326 - WGS84', 'gps grados decimales', 'WGS84 Geograficas (4326) GD', 'N', '1.384277, 42.107393');
INSERT INTO COORDINATES_SYSTEMS VALUES (DEFAULT, 3857, 'EPSG:3857 - WGS 84', 'x e y psudomercator (metros)', 'WGS84 PsueudoMercator(3857)', 'N','99673.884884, 5185946.621036');
INSERT INTO COORDINATES_SYSTEMS VALUES (DEFAULT, 23031, 'EPSG:23031 - ED50 / UTM zone 31N', 'ed50 utm (metros)', 'ED50 / UTM zone 31N', 'N', '326243.545763, 4670603.684676');
INSERT INTO COORDINATES_SYSTEMS VALUES (DEFAULT, 4258, 'EPSG:4258 - ETRS89', 'etrs89 geograficas grados decimales', 'ETRS Geograficas (4258) GD', 'N', '0.895386, 42.166457');
INSERT INTO COORDINATES_SYSTEMS VALUES (DEFAULT, 4258, 'EPSG:4258 - ETRS89', 'etrs89 geograficas grados, minutos y segundos', 'ETRS Geograficas (4258) GMS', 'Y', '3º 42'' 36'''' E 40º 26'' 46'''' N');
INSERT INTO COORDINATES_SYSTEMS VALUES (DEFAULT, 25831, 'EPSG:25831 - ETRS89 / UTM zone 31N', 'etrs89 catalunya proyectadas (metros)', 'ETRS89 UTM huso 31N (25831)', 'N', '379615.575691, 4657515.452277');

CREATE TABLE COORDINATES_INITIAL (
    ID NUMBER GENERATED BY DEFAULT as IDENTITY(START with 1 INCREMENT by 1) NOT NULL,
    longitude NUMBER NOT NULL,
    latitude NUMBER NOT NULL,
    srid NUMBER NOT NULL,
    geom SDO_GEOMETRY,
    CONSTRAINT PK_COORDINATES_INITIAL PRIMARY KEY (ID),
    CONSTRAINT FK_COORDINATES_SYSTEMS FOREIGN KEY (srid)
        REFERENCES COORDINATES_SYSTEMS (ID)
);
COMMENT ON TABLE "SEM_CHR_GIS"."COORDINATES_INITIAL" IS 'Taula que emmagatzema les coordenades passades per l''usuari i el sistema de referència en què són passades';
-- create sequence to have autoincrement pk
--CREATE SEQUENCE COORDINATES_INITIAL_SEQ;

-- create tigger using the sequence
-- CREATE OR REPLACE TRIGGER COORDINATES_INITIAL_TRG 
-- BEFORE INSERT ON COORDINATES_INITIAL 
-- FOR EACH ROW
-- WHEN (new.id IS NULL)
-- BEGIN
--   SELECT COORDINATES_INITIAL_SEQ.NEXTVAL
--   INTO   :new.id
--   FROM   dual;
-- END;

CREATE TABLE COORDINATES_TRANSFORMED (
    ID NUMBER GENERATED BY DEFAULT as IDENTITY(START with 1 INCREMENT by 1) NOT NULL,
    initial_coordinates_id NUMBER NOT NULL,
    longitude NUMBER NOT NULL,
    latitude NUMBER NOT NULL,
    srid NUMBER NOT NULL,
    geom SDO_GEOMETRY NOT NULL,
    CONSTRAINT PK_COORDINATES_TRANSFORMED PRIMARY KEY (ID),
    CONSTRAINT FK_COORDINATES_INITIAL FOREIGN KEY (initial_coordinates_id)
        REFERENCES COORDINATES_INITIAL (ID),
    CONSTRAINT FK_COORDINATES_SYSTEM FOREIGN KEY (srid)
        REFERENCES COORDINATES_SYSTEMS (ID)
);
COMMENT ON TABLE "SEM_CHR_GIS"."COORDINATES_TRANSFORMED" IS 'Taula que emmagatzema la referència de les coordenades passades per l''usuari i la seva transformació al sistema de referència de Chronos (25831)';
-- create sequence to have autoincrement pk
--CREATE SEQUENCE COORDINATES_TRANSFORMED_SEQ;

-- create tigger using the sequence
-- CREATE OR REPLACE TRIGGER COORDINATES_TRANSFORMED_TRG 
-- BEFORE INSERT ON COORDINATES_TRANSFORMED 
-- FOR EACH ROW
-- WHEN (new.id IS NULL)
-- BEGIN
--   SELECT COORDINATES_TRANSFORMED_SEQ.NEXTVAL
--   INTO   :new.id
--   FROM   dual;
-- END;

--insertamos some initial coordinates
-- acordarse de hacer commit al introducir estos valores en sql developer o si no no persistirán
-- INSERT INTO COORDINATES_INITIAL VALUES (DEFAULT, 1.493404, 41.631894, 4258, NULL)
-- INSERT INTO COORDINATES_INITIAL VALUES (DEFAULT, 1.395264, 42.313878, 4258, NULL)
-- INSERT INTO COORDINATES_INITIAL VALUES (DEFAULT, 2.147827, 41.590797, 4258, NULL)


-- TransformPointCoodinatesAndStore procedure
create or replace PROCEDURE TransformPointCoodinatesAndStore(
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    dmsToddNeeded IN VARCHAR,
    targetSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS
    vInitialGeometry SDO_GEOMETRY;
    vTransformedGeometry SDO_GEOMETRY;
    vInitialCoordinatesId NUMBER;
    vOriginCoordSystemId NUMBER;
    vTargetCoordSystemId NUMBER;
BEGIN
    -- Get the origin coordinate system (pk)
    vOriginCoordSystemId := get_origin_coord_system_id(selectedSrid, dmsToddneeded);

    -- Get the target coordinate system (pk). 
    -- Note it uses the default parameter in the function (25831 is_dms = 0 only option)
    vTargetCoordSystemId := get_origin_coord_system_id(targetSrid);

    -- Create the point geometry with the srid sent by user
    vInitialGeometry := SDO_GEOMETRY(2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL);
    
    -- Create the point geometry with targetSrid as target srid (commonly 25831 (Chronos system)
    vTransformedGeometry := SDO_CS.TRANSFORM(
        SDO_GEOMETRY(2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        targetSrid
    );

    -- Store the initial coordinates and the srid selected by the user and get the generated primary key
    INSERT INTO COORDINATES_INITIAL
    VALUES (DEFAULT, pLongitude, pLatitude, vOriginCoordSystemId, vInitialGeometry)
    RETURNING id INTO vInitialCoordinatesId;

    -- Store the transformed coordinates, referencing the foreign keys also
    INSERT INTO COORDINATES_TRANSFORMED
    VALUES (DEFAULT, vInitialCoordinatesId, vTransformedGeometry.SDO_POINT.X, vTransformedGeometry.SDO_POINT.Y, vTargetCoordSystemId, vTransformedGeometry);

    -- Set the OUT parameters
    OUT_MESSAGE := 'COORDINATES TRANSFORMATION SUCCESS';
    SELECT JSON_OBJECT(
            'initial_point' VALUE json_object('x' VALUE pLongitude, 'y' VALUE pLatitude, 'srid' VALUE selectedSrid),
            'transformed_point' VALUE json_object('x' VALUE vTransformedGeometry.SDO_POINT.X, 'y' VALUE vTransformedGeometry.SDO_POINT.Y, 'srid' VALUE vTransformedGeometry.SDO_SRID, 'geojson' VALUE SDO_Util.TO_GEOJSON(vTransformedGeometry))
            format json
            returning clob
    ) 
    INTO OUT_JSON
    FROM dual;
    DBMS_OUTPUT.PUT_LINE(OUT_JSON);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
        OUT_MESSAGE := 'COORDINATES TRANSFORMATION FAILURE';
        OUT_JSON:= JSON_OBJECT();
END;

CREATE OR REPLACE FUNCTION get_origin_coord_system_id(
    srid NUMBER,
    dmsToddneeded VARCHAR DEFAULT 'N'
) RETURN NUMBER AS
    vCoordSystemId NUMBER;
BEGIN
    SELECT ID INTO vCoordSystemId
    FROM COORDINATES_SYSTEMS
    WHERE EPSG = srid AND is_dms = dmsToddneeded;

    RETURN vCoordSystemId;
END;


-- DMS_to_DD function
CREATE OR REPLACE FUNCTION DMS_TO_DD (
    p_degrees  NUMBER,
    p_minutes  NUMBER,
    p_seconds  NUMBER,
    p_direction VARCHAR2
  ) RETURN NUMBER IS
    dd NUMBER;
  BEGIN
    -- Convert degrees, minutes, and seconds to decimal degrees
    dd := p_degrees + (p_minutes / 60) + (p_seconds / 3600);
    -- Adjust the sign based on the direction (E, W, N, S)
    IF p_direction = 'W' OR p_direction = 'S' THEN
      dd := -dd;
    END IF;
    RETURN dd;
  END DMS_TO_DD;

-- CHECK_INTERSECTION_WITH_ABS function
CREATE OR REPLACE FUNCTION CHECK_INTERSECTION_WITH_ABS(
    p_longitude NUMBER,
    p_latitude NUMBER,
    p_srid NUMBER
) RETURN NUMBER AS
    v_result NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_result
    FROM SEM_CHR_GIS.abs_2020_etrs89
    WHERE SDO_ANYINTERACT(
        SDO_GEOMETRY(2001, p_srid, SDO_POINT_TYPE(p_longitude, p_latitude, NULL), NULL, NULL),
        geom
    ) = 'TRUE';

    IF v_result > 0 THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;

  -- ABSINTERSECTEDBYPOINT procedure with CHECK_INTERSECTION_WITH_ABS incorporated
create or replace PROCEDURE ABSINTERSECTEDBYPOINT (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
    isABSLayerIntersected NUMBER;
BEGIN
    isABSLayerIntersected := CHECK_INTERSECTION_WITH_ABS(pLongitude, pLatitude, selectedSrid);
    IF isABSLayerIntersected > 0 THEN
        OUT_MESSAGE := 'ABS INTERSECTED BY POINT SUCCESS';
        SELECT JSON_ARRAYAGG(
            json_object( KEY 'codiabs' VALUE CODIABS, KEY 'nomabs' VALUE NOMABS, KEY 'codiss' VALUE CODISS, KEY 'nomss' VALUE NOMSS, KEY 'codirs' VALUE CODIRS, KEY 'nomrs' VALUE NOMRS, KEY 'codiaga' VALUE CODIAGA, KEY 'nomaga' VALUE NOMAGA, KEY 'estat' VALUE ESTAT, KEY 'observacions' VALUE OBSER)
            format json
            returning clob
        ) AS JSON 
        INTO OUT_JSON
        FROM SEM_CHR_GIS.abs_2020_etrs89
        where SDO_anyinteract(
            SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
            geom) = 'TRUE';
        DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    ELSE
        DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
        OUT_MESSAGE := 'Coordinates passed do not intersect ABS layer';
        OUT_JSON:= JSON_OBJECT();
    END IF;

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ABS INTERSECTED BY POINT FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ABSINTERSECTEDBYPOINT;

-- COUNTRY_INTERSECTED_BY_POINT function
-- cuando se llame a esta funcion si no devuelve nada (null), es que has pinchado mar
CREATE OR REPLACE FUNCTION GET_COUNTRY_ID_INTERSECTED_BY_POINT(
    p_longitude NUMBER,
    p_latitude NUMBER,
    p_srid NUMBER
) RETURN NUMBER AS
    v_result NUMBER;
BEGIN
    SELECT ID
    INTO v_result
    FROM SEM_CHR_GIS.COUNTRY_ETRS89
    WHERE SDO_ANYINTERACT(
        SDO_GEOMETRY(2001, p_srid, SDO_POINT_TYPE(p_longitude, p_latitude, NULL), NULL, NULL),
        geom
    ) = 'TRUE';

    RETURN v_result;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_result := NULL;
            RETURN v_result;
END;

CREATE OR REPLACE PROCEDURE ADMINDIVISION_INTERSECTION (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    GLOBAL_OUT_MESAGE OUT VARCHAR,
    GLOBL_OUT_JSON OUT CLOB
) AS
    country_id NUMBER;
    local_out_json CLOB;
    local_out_mesage VARCHAR2(100);
BEGIN
    --GLOBAL_OUT_MESAGE := 'ADMINDIVISION_INTERSECTION SUCCESS';
    country_id := GET_COUNTRY_ID_INTERSECTED_BY_POINT(pLongitude, pLatitude, selectedSrid);
    CASE 
        WHEN country_id = 2 THEN
            CASE
                WHEN CHECK_INTERSECTION_WITH_CAT(pLongitude, pLatitude, selectedSrid) = 1 AND CHECK_INTERSECTION_WITH_NEIGHBOURHOOD_BCN(pLongitude, pLatitude, selectedSrid) = 1 THEN
                    ADMINDIVISION_NEIGHBOURHOOD_BCN(pLongitude, pLatitude, selectedSrid, local_out_json, local_out_mesage);
                WHEN CHECK_INTERSECTION_WITH_CAT(pLongitude, pLatitude, selectedSrid) = 1 AND CHECK_INTERSECTION_WITH_NEIGHBOURHOOD_BCN(pLongitude, pLatitude, selectedSrid) = 0 THEN
                    ADMINDIVISION_CAT(pLongitude, pLatitude, selectedSrid, local_out_json, local_out_mesage);
                ELSE
                    --en este caso no hay procedimiento que rellene ambas variables por lo que se rellenan aqui
                    local_out_mesage := 'ADMINDIVISION_INTERSECTION FAILURE, POINT THAT WAS PASSED IS IN A GEOMETRY TOPOLOGY GAP';
                    local_out_json := JSON_OBJECT();
            END CASE;
        WHEN country_id = 1 THEN
            ADMINDIVISION_AND(pLongitude, pLatitude, selectedSrid, local_out_json, local_out_mesage);
        WHEN country_id = 7 THEN
            ADMINDIVISION_FRA(pLongitude, pLatitude, selectedSrid, local_out_json, local_out_mesage);
        WHEN country_id = 3 OR country_id = 4 OR country_id = 5 OR country_id = 6 THEN
            ADMINDIVISION_ESP(pLongitude, pLatitude, selectedSrid, local_out_json, local_out_mesage);
        WHEN country_id = NULL THEN
            --en este caso no hay procedimiento que rellene ambas variables por lo que se rellenan aqui
            local_out_mesage := 'ADMINDIVISION_INTERSECTION FAILURE, POINT THAT WAS PASSED DOES NOT INTERSECT EMERGED LAND OR THE POINT IS IN A GEOMETRY TOPOLOGY GAP';
            local_out_json := JSON_OBJECT();
        ELSE
            --en este caso no hay procedimiento que rellene ambas variables por lo que se rellenan aqui
            local_out_mesage := 'NOT CONTROLLED CASE AT THE ADMINDIVISION_INTERSECTION PROCEDURE';
            local_out_json := JSON_OBJECT();
    END CASE;

    IF local_out_json IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('eeeeeeeeeeh, escribo desde procedimiento padre y el local_out_json está lleno');
        DBMS_OUTPUT.PUT_LINE('CLOB data: ' || local_out_json);
    ELSE
        DBMS_OUTPUT.PUT_LINE('eeeeeeeeeeh, escribo desde procedimiento padre y el local_out_json está vacio');
    END IF;

    GLOBL_OUT_JSON := local_out_json;
    GLOBAL_OUT_MESAGE := local_out_mesage;
    DBMS_OUTPUT.PUT_LINE('GLOBL_OUT_JSON =>' || GLOBL_OUT_JSON );
    DBMS_OUTPUT.PUT_LINE('GLOBAL_OUT_MESAGE => ' || GLOBAL_OUT_MESAGE);

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception in ADMINDIVISION_INTERSECTION is -: ' || SQLERRM || SQLCODE);
            GLOBL_OUT_JSON := 'An error occurred: ' || SQLERRM;
            GLOBAL_OUT_MESAGE := 'ADMINDIVISION_INTERSECTION FAILURE';
END;

-- CHECK_INTERSECTION_WITH_CATALUNYAFRANJA function
CREATE OR REPLACE FUNCTION CHECK_INTERSECTION_WITH_CAT(
    p_longitude NUMBER,
    p_latitude NUMBER,
    p_srid NUMBER
) RETURN NUMBER AS
    v_result NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_result
    FROM SEM_CHR_GIS.LOCALADMIN_CAT_ETRS89
    WHERE SDO_ANYINTERACT(
        SDO_GEOMETRY(2001, p_srid, SDO_POINT_TYPE(p_longitude, p_latitude, NULL), NULL, NULL),
        geom
    ) = 'TRUE';

    IF v_result > 0 THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
/
-- CHECK_INTERSECTION_WITH_NEIGHBOURHOOD_BCN function
CREATE OR REPLACE FUNCTION CHECK_INTERSECTION_WITH_NEIGHBOURHOOD_BCN(
    p_longitude NUMBER,
    p_latitude NUMBER,
    p_srid NUMBER
) RETURN NUMBER AS
    v_result NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_result
    FROM SEM_CHR_GIS.NEIGHBOURHOOD_BCN_ETRS89
    WHERE SDO_ANYINTERACT(
        SDO_GEOMETRY(2001, p_srid, SDO_POINT_TYPE(p_longitude, p_latitude, NULL), NULL, NULL),
        geom
    ) = 'TRUE';

    IF v_result > 0 THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
/

-- ADMINDIVISION_ESP procedure
create or replace PROCEDURE ADMINDIVISION_ESP (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
    clob_size NUMBER;
BEGIN
    OUT_MESSAGE := 'ADMINDIVISION_ESP SUCCESS';
    SELECT json_object(
        'country' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.country,
        'countryId' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.COUNTRY_ID,
        'countryCode' VALUE NULL,
        'region' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.REGION,
        'regionId' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.REGION_ID,
        'macrocounty' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.MACROCOUNTY,
        'macrocountyId' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.MACROCOUNTY,
        'localadmin' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.LOCALADMIN,
        'localadminId' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.LOCALADMIN_ID,
        'locality' VALUE NULL,
        'localityId' VALUE NUll,
        'borough' VALUE NULL,
        'boroughId' VALUE NULL,
        'boroughCode' VALUE NULL,
        'neighbourhood' VALUE NULL,
        'neighbourhoodId' VALUE NULL,
        'neighbourhoodCode' VALUE NULL,
        'sm1' VALUE NULL,
        'sm1Id' VALUE NULL,
        'sm2' VALUE NULL,
        'sm2Id' VALUE NULL
        format json
        returning clob
    ) AS JSON 
    INTO OUT_JSON
    FROM SEM_CHR_GIS.localadmin_esp_etrs89
    where SDO_anyinteract(
        SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        geom) = 'TRUE';
    DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    clob_size := DBMS_LOB.GETLENGTH(OUT_JSON);
    DBMS_OUTPUT.PUT_LINE('ADMINDIVISION_ESP clob_size is: ' || clob_size || 'megabytes');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ADMINDIVISION_ESP FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISION_ESP;


-- ADMINDIVISION_CAT procedure
create or replace PROCEDURE ADMINDIVISION_CAT (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
    clob_size NUMBER;
BEGIN
    OUT_MESSAGE := 'ADMINDIVISION_CAT SUCCESS';
    SELECT json_object(
        'country' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.country,
        'countryId' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.COUNTRY_ID,
        'countryCode' VALUE NULL,
        'region' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.REGION,
        'regionId' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.REGION_ID,
        'macrocounty' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.MACROCOUNTY,
        'macrocountyId' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.MACROCOUNTY_ID,
        'localadmin' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.LOCALADMIN,
        'localadminId' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.LOCALADMIN_ID,
        'locality' VALUE NULL,
        'localityId' VALUE NUll,
        'borough' VALUE NULL,
        'boroughId' VALUE NULL,
        'boroughCode' VALUE NULL,
        'neighbourhood' VALUE NULL,
        'neighbourhoodId' VALUE NULL,
        'neighbourhoodCode' VALUE NULL,
        'sm1' VALUE NULL,
        'sm1Id' VALUE NULL,
        'sm2' VALUE NULL,
        'sm2Id' VALUE NULL
        format json
        returning clob
    ) AS JSON 
    INTO OUT_JSON
    FROM SEM_CHR_GIS.localadmin_cat_etrs89
    where SDO_anyinteract(
        SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        geom) = 'TRUE';
    DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    clob_size := DBMS_LOB.GETLENGTH(OUT_JSON);
    DBMS_OUTPUT.PUT_LINE('ADMINDIVISION_CAT clob_size is: ' || clob_size || 'megabytes');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ADMINDIVISION_CAT FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISION_CAT;

-- ADMINDIVISION_FRA procedure
create or replace PROCEDURE ADMINDIVISION_FRA (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
    clob_size NUMBER;
BEGIN
    OUT_MESSAGE := 'ADMINDIVISION_FRA SUCCESS';
    SELECT json_object(
        'country' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.country,
        'countryId' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.COUNTRY_ID,
        'countryCode' VALUE NULL,
        'region' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.REGION,
        'regionId' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.REGION_ID,
        'macrocounty' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.MACROCOUNTY,
        'macrocountyId' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.MACROCOUNTY_ID,
        'localadmin' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.LOCALADMIN,
        'localadminId' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.LOCALADMIN_ID,
        'locality' VALUE NULL,
        'localityId' VALUE NUll,
        'borough' VALUE NULL,
        'boroughId' VALUE NULL,
        'boroughCode' VALUE NULL,
        'neighbourhood' VALUE NULL,
        'neighbourhoodId' VALUE NULL,
        'neighbourhoodCode' VALUE NULL,
        'sm1' VALUE NULL,
        'sm1Id' VALUE NULL,
        'sm2' VALUE NULL,
        'sm2Id' VALUE NULL
        format json
        returning clob
    ) AS JSON 
    INTO OUT_JSON
    FROM SEM_CHR_GIS.localadmin_fra_etrs89
    where SDO_anyinteract(
        SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        geom) = 'TRUE';
    DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ADMINDIVISION_FRA FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISION_FRA;

-- ADMINDIVISION_AND procedure
create or replace PROCEDURE ADMINDIVISION_AND (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
    clob_size NUMBER;
BEGIN
    OUT_MESSAGE := 'ADMINDIVISION_AND SUCCESS';
    SELECT json_object(
        'country' VALUE SEM_CHR_GIS.localadmin_and_etrs89.country,
        'countryId' VALUE SEM_CHR_GIS.localadmin_and_etrs89.COUNTRY_ID,
        'countryCode' VALUE NULL,
        'region' VALUE NULL,
        'regionId' VALUE NULL,
        'macrocounty' VALUE NULL,
        'macrocountyId' VALUE NULL,
        'localadmin' VALUE SEM_CHR_GIS.localadmin_and_etrs89.LOCALADMIN,
        'localadminId' VALUE SEM_CHR_GIS.localadmin_and_etrs89.LOCALADMIN_ID,
        'locality' VALUE NULL,
        'localityId' VALUE NUll,
        'borough' VALUE NULL,
        'boroughId' VALUE NULL,
        'boroughCode' VALUE NULL,
        'neighbourhood' VALUE NULL,
        'neighbourhoodId' VALUE NULL,
        'neighbourhoodCode' VALUE NULL,
        'sm1' VALUE NULL,
        'sm1Id' VALUE NULL,
        'sm2' VALUE NULL,
        'sm2Id' VALUE NULL
        format json
        returning clob
    ) AS JSON 
    INTO OUT_JSON
    FROM SEM_CHR_GIS.localadmin_and_etrs89
    where SDO_anyinteract(
        SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        geom) = 'TRUE';
    DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    clob_size := DBMS_LOB.GETLENGTH(OUT_JSON);
    DBMS_OUTPUT.PUT_LINE('ADMINDIVISION_AND clob_size is: ' || clob_size || 'megabytes');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ADMINDIVISION_AND FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISION_AND;


-- ADMINDIVISION_NEIGHBOURHOOD_BCN procedure
create or replace PROCEDURE ADMINDIVISION_NEIGHBOURHOOD_BCN (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
    clob_size NUMBER;
BEGIN
    OUT_MESSAGE := 'ADMINDIVISION_NEIGHBOURHOOD_BCN SUCCESS';
    SELECT json_object(
        'country' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.country,
        'countryId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.COUNTRY_ID,
        'countryCode' VALUE NULL,
        'region' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.REGION,
        'regionId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.REGION_ID,
        'macrocounty' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.MACROCOUNTY,
        'macrocountyId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.MACROCOUNTY_ID,
        'localadmin' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.LOCALADMIN,
        'localadminId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.LOCALADMIN_ID,
        'locality' VALUE NULL,
        'localityId' VALUE NUll,
        'borough' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.BOROUGH,
        'boroughId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.BOROUGH_ID,
        'boroughCode' VALUE NULL,
        'neighbourhood' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.NEIGHBOURHOOD,
        'neighbourhoodId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.NEIGHBOURHOOD_ID,
        'neighbourhoodCode' VALUE NULL,
        'sm1' VALUE NULL,
        'sm1Id' VALUE NULL,
        'sm2' VALUE NULL,
        'sm2Id' VALUE NULL
        format json
        returning clob
    ) AS JSON 
    INTO OUT_JSON
    FROM SEM_CHR_GIS.neighbourhood_bcn_etrs89
    where SDO_anyinteract(
        SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        geom) = 'TRUE';
    DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    clob_size := DBMS_LOB.GETLENGTH(OUT_JSON);
    DBMS_OUTPUT.PUT_LINE('ADMINDIVISION_NEIGHBOURHOOD_BCN clob_size is: ' || clob_size || 'megabytes');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ADMINDIVISION_NEIGHBOURHOOD_BCN FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISION_NEIGHBOURHOOD_BCN;