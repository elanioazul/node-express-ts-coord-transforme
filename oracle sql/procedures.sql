/*
PASOS PARA LANZAR EN LOCAL LA BD ORACLE;
PASOS PARA REPLICAR ESTO MISMO EN LA BD ORACLE QAS DEL PROYECTO ES LO MISMO PERO CAMBIANDO EN ARCHVO .ENV CON LAS CREDENCIALES DE CONEXIÓN Y NO LANZAR EL DOCKER EN LOCAL.
TAMPOCO ES NECESARIO LA CREACION DE USUARIO GIS PORQUE YA HAY UNO CREADO DE PRUEBAS, "SEM_CHR_GIS AL QUE APUNTO CON .ENV"
*/

--docker run -d --name oracle-db -p 1521:1521 -e ORACLE_PWD=test container-registry.oracle.com/database/enterprise:latest

--me conecto (aunque tarda un rato la conexion en hacerse correctamente) con sqldeveloper a la bd que corre el container con:
-- USUARIO: SYS as SYSDBA
-- CONTRASEÑA: test
-- NOMBRE DEL HOST: localhost
-- PUERTO: 1521
-- NOMBRE DEL SERVICIO: orclpdb1


--hago un script sql para crear nuevo squema (nuevo user) y asi crear nueva conexion
-- alter session set "_ORACLE_SCRIPT"=true;
-- create user GIS identified by "123" default tablespace users quota unlimited on users;
-- grant resource, connect, create table, create session to GIS;

--me conecto con sqldeveloper a dicho nuevo squema con la con los parametros de conexion:
-- USUARIO: GIS
-- CONTRASEÑA: 123
-- NOMBRE DEL HOST: localhost
-- PUERTO: 1521
-- NOMBRE DEL SERVICIO: orclpdb1

--hago tablas
CREATE TABLE COORDINATES_INITIAL (
    ID NUMBER GENERATED BY DEFAULT as IDENTITY(START with 1 INCREMENT by 1) NOT NULL,
    longitude NUMBER NOT NULL,
    latitude NUMBER NOT NULL,
    srid NUMBER NOT NULL,
    geom SDO_GEOMETRY,
    CONSTRAINT PK_COORDINATES_INITIAL PRIMARY KEY (ID)
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
    CONSTRAINT FK_COORDINATES_TRANSFORMED FOREIGN KEY (initial_coordinates_id)
        REFERENCES COORDINATES_INITIAL (ID)
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
INSERT INTO COORDINATES_INITIAL VALUES (DEFAULT, 1.493404, 41.631894, 4258, NULL)
INSERT INTO COORDINATES_INITIAL VALUES (DEFAULT, 1.395264, 42.313878, 4258, NULL)
INSERT INTO COORDINATES_INITIAL VALUES (DEFAULT, 2.147827, 41.590797, 4258, NULL)

CREATE TABLE COORDINATES_SYSTEMS (
    ID NUMBER GENERATED BY DEFAULT as IDENTITY(START with 1 INCREMENT by 1),
    epsg NUMBER,
    epsg_desc VARCHAR2(200),
    label VARCHAR2(200),
    label_advance VARCHAR2(200),
    ejemplo_coords VARCHAR2(200),
    CONSTRAINT PK_COORDINATES_SYSTEMS PRIMARY KEY (ID)
);
COMMENT ON TABLE "SEM_CHR_GIS"."COORDINATES_SYSTEMS" IS 'Taula que recull els sistema de coordenades interoperables del sistema Chronos';

-- acordarse de hacer commit al introducir estos valores en sql developer o si no no persistirán
INSERT INTO COORDINATES_SYSTEMS VALUES (DEFAULT, 4326, 'EPSG 4326 - WGS84', 'gps grados, minutos y segundos', 'WGS84 Geograficas (4326) GMS', '3º 42'' 36'''' E 40º 26'' 46'''' N');
INSERT INTO COORDINATES_SYSTEMS VALUES (DEFAULT, 4326, 'EPSG 4326 - WGS84', 'gps grados decimales', 'WGS84 Geograficas (4326) GD', '1.384277, 42.107393');
INSERT INTO COORDINATES_SYSTEMS VALUES (DEFAULT, 3857, 'EPSG:3857 - WGS 84', 'x e y psudomercator (metros)', 'WGS84 PsueudoMercator(3857)', '99673.884884, 5185946.621036');
INSERT INTO COORDINATES_SYSTEMS VALUES (DEFAULT, 23031, 'EPSG:23031 - ED50 / UTM zone 31N', 'ed50 utm (metros)', 'ED50 / UTM zone 31N', '326243.545763, 4670603.684676');
INSERT INTO COORDINATES_SYSTEMS VALUES (DEFAULT, 4258, 'EPSG:4258 - ETRS89', 'etrs89 geograficas grados decimales', 'ETRS Geograficas (4258) GD', '0.895386, 42.166457');
INSERT INTO COORDINATES_SYSTEMS VALUES (DEFAULT, 4258, 'EPSG:4258 - ETRS89', 'etrs89 geograficas grados, minutos y segundos', 'ETRS Geograficas (4258) GMS', '3º 42'' 36'''' E 40º 26'' 46'''' N');
INSERT INTO COORDINATES_SYSTEMS VALUES (DEFAULT, 25831, 'EPSG:25831 - ETRS89 / UTM zone 31N', 'etrs89 catalunya proyectadas (metros)', 'ETRS89 UTM huso 31N (25831)', '379615.575691, 4657515.452277');

-- TransformPointCoodinatesAndStore procedure
create or replace PROCEDURE TransformPointCoodinatesAndStore(
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    targetSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS
    vInitialGeometry SDO_GEOMETRY;
    vTransformedGeometry SDO_GEOMETRY;
    vInitialCoordinatesId NUMBER;
BEGIN
    -- Create the point geometry with the srid sent by user
    vInitialGeometry := SDO_GEOMETRY(2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL);
    
    -- Create the point geometry with 25831 as target srid
    vTransformedGeometry := SDO_CS.TRANSFORM(
        SDO_GEOMETRY(2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        targetSrid
    );
    -- Store the initial coordinates and the srid selected by the user and get the generated primary key
    INSERT INTO COORDINATES_INITIAL
    VALUES (DEFAULT, pLongitude, pLatitude, selectedSrid, vInitialGeometry)
    RETURNING id INTO vInitialCoordinatesId;
    -- Store the transformed coordinates, referencing the foreign key also
    INSERT INTO COORDINATES_TRANSFORMED
    VALUES (DEFAULT, vInitialCoordinatesId, vTransformedGeometry.SDO_POINT.X, vTransformedGeometry.SDO_POINT.Y, vTransformedGeometry.SDO_SRID, vTransformedGeometry);
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

  -- ABSINTERSECTEDBYPOINT procedure
create or replace PROCEDURE ABSINTERSECTEDBYPOINT (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
BEGIN
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
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ABS INTERSECTED BY POINT FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ABSINTERSECTEDBYPOINT;


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

  -- ADMINDIVISIONINFO_ESP procedure
create or replace PROCEDURE ADMINDIVISIONINFO_ESP (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
BEGIN
    OUT_MESSAGE := 'ADMINDIVISIONINFO_ESP SUCCESS';
    SELECT JSON_ARRAYAGG(
        json_object( KEY 'localadmin_id' VALUE LOCALADMIN_ID, KEY 'localadmin' VALUE LOCALADMIN, KEY 'region_id' VALUE REGION_ID, KEY 'region' VALUE REGION, KEY 'country_id' VALUE COUNTRY_ID, KEY 'country' VALUE country)
        format json
        returning clob
    ) AS JSON 
    INTO OUT_JSON
    FROM SEM_CHR_GIS.localadmin_esp_etrs89
    where SDO_anyinteract(
        SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        geom) = 'TRUE';
    DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ADMINDIVISIONINFO_ESP FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISIONINFO_ESP;

-- ADMINDIVISIONINFO_ESP_2 procedure
create or replace PROCEDURE ADMINDIVISIONINFO_ESP_2 (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
BEGIN
    OUT_MESSAGE := 'ADMINDIVISIONINFO_ESP SUCCESS';
    SELECT json_object(
        'localadmin_id' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.LOCALADMIN_ID,
        'localadmin' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.LOCALADMIN,
        'region_id' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.REGION_ID,
        'region' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.REGION,
        'country_id' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.COUNTRY_ID,
        'country' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.country
        format json
        returning clob
    ) AS JSON 
    INTO OUT_JSON
    FROM SEM_CHR_GIS.localadmin_esp_etrs89
    where SDO_anyinteract(
        SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        geom) = 'TRUE';
    DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ADMINDIVISIONINFO_ESP FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISIONINFO_ESP_2;

-- ADMINDIVISIONINFO_ESP_3 procedure
create or replace PROCEDURE ADMINDIVISIONINFO_ESP_3 (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
BEGIN
    OUT_MESSAGE := 'ADMINDIVISIONINFO_ESP SUCCESS';
    SELECT json_object(
        'localadmin' VALUE json_object(
            'id' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.LOCALADMIN_ID,
            'localadmin' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.LOCALADMIN
        ),
        'region' VALUE json_object(
            'id' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.REGION_ID,
            'region' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.REGION
        ),
        'country' VALUE json_object(
            'id' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.COUNTRY_ID,
            'country' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.COUNTRY
        )
    ) INTO OUT_JSON
    FROM SEM_CHR_GIS.localadmin_esp_etrs89
    where SDO_anyinteract(
        SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        geom) = 'TRUE';
    DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ADMINDIVISIONINFO_ESP FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISIONINFO_ESP_3;

  -- ADMINDIVISIONINFO_CAT procedure
create or replace PROCEDURE ADMINDIVISIONINFO_CAT (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
BEGIN
    OUT_MESSAGE := 'ADMINDIVISIONINFO_CAT SUCCESS';
    SELECT JSON_ARRAYAGG(
        json_object( KEY 'localadmin_id' VALUE LOCALADMIN_ID, KEY 'localadmin' VALUE LOCALADMIN, KEY 'macrocounty_id' VALUE MACROCOUNTY, KEY 'macrocounty' VALUE MACROCOUNTY, KEY 'region_id' VALUE REGION_ID, KEY 'region' VALUE REGION, KEY 'country_id' VALUE COUNTRY_ID, KEY 'country' VALUE country)
        format json
        returning clob
    ) AS JSON 
    INTO OUT_JSON
    FROM SEM_CHR_GIS.localadmin_cat_etrs89
    where SDO_anyinteract(
        SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        geom) = 'TRUE';
    DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ADMINDIVISIONINFO_CAT FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISIONINFO_CAT;

-- ADMINDIVISIONINFO_CAT_2 procedure
create or replace PROCEDURE ADMINDIVISIONINFO_CAT_2 (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
BEGIN
    OUT_MESSAGE := 'ADMINDIVISIONINFO_CAT SUCCESS';
    SELECT json_object(
        'localadmin_id' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.LOCALADMIN_ID,
        'localadmin' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.LOCALADMIN,
        'macrocounty_id' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.MACROCOUNTY_ID,
        'macrocounty' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.MACROCOUNTY,
        'region_id' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.REGION_ID,
        'region' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.REGION,
        'country_id' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.COUNTRY_ID,
        'country' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.country
        format json
        returning clob
    ) AS JSON 
    INTO OUT_JSON
    FROM SEM_CHR_GIS.localadmin_cat_etrs89
    where SDO_anyinteract(
        SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        geom) = 'TRUE';
    DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ADMINDIVISIONINFO_CAT FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISIONINFO_CAT_2;


-- ADMINDIVISIONINFO_CAT_3 procedure
create or replace PROCEDURE ADMINDIVISIONINFO_CAT_3 (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
BEGIN
    OUT_MESSAGE := 'ADMINDIVISIONINFO_CAT SUCCESS';
    SELECT json_object(
        'localadmin' VALUE json_object(
            'id' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.LOCALADMIN_ID,
            'localadmin' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.LOCALADMIN
        ),
        'macrocounty' VALUE json_object(
            'id' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.MACROCOUNTY_ID,
            'macrocounty' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.MACROCOUNTY
        ),
        'region' VALUE json_object(
            'id' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.REGION_ID,
            'region' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.REGION
        ),
        'country' VALUE json_object(
            'id' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.COUNTRY_ID,
            'country' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.COUNTRY
        )
    ) INTO OUT_JSON
    FROM SEM_CHR_GIS.localadmin_cat_etrs89
    where SDO_anyinteract(
        SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        geom) = 'TRUE';
    DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ADMINDIVISIONINFO_CAT FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISIONINFO_CAT_3;


  -- ADMINDIVISIONINFO_FRA procedure
create or replace PROCEDURE ADMINDIVISIONINFO_FRA (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
BEGIN
    OUT_MESSAGE := 'ADMINDIVISIONINFO_FRA SUCCESS';
    SELECT JSON_ARRAYAGG(
        json_object( KEY 'localadmin_id' VALUE LOCALADMIN_ID, KEY 'localadmin' VALUE LOCALADMIN, KEY 'macrocounty_id' VALUE MACROCOUNTY, KEY 'macrocounty' VALUE MACROCOUNTY, KEY 'region_id' VALUE REGION_ID, KEY 'region' VALUE REGION, KEY 'country_id' VALUE COUNTRY_ID, KEY 'country' VALUE country)
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
            OUT_MESSAGE := 'ADMINDIVISIONINFO_FRA FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISIONINFO_FRA;

-- ADMINDIVISIONINFO_FRA_2 procedure
create or replace PROCEDURE ADMINDIVISIONINFO_FRA_2 (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
BEGIN
    OUT_MESSAGE := 'ADMINDIVISIONINFO_FRA SUCCESS';
    SELECT json_object(
        'localadmin_id' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.LOCALADMIN_ID,
        'localadmin' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.LOCALADMIN,
        'macrocounty_id' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.MACROCOUNTY_ID,
        'macrocounty' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.MACROCOUNTY,
        'region_id' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.REGION_ID,
        'region' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.REGION,
        'country_id' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.COUNTRY_ID,
        'country' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.country
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
            OUT_MESSAGE := 'ADMINDIVISIONINFO_FRA FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISIONINFO_FRA_2;


-- ADMINDIVISIONINFO_FRA_3 procedure
create or replace PROCEDURE ADMINDIVISIONINFO_FRA_3 (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
BEGIN
    OUT_MESSAGE := 'ADMINDIVISIONINFO_FRA SUCCESS';
    SELECT json_object(
        'localadmin' VALUE json_object(
            'id' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.LOCALADMIN_ID,
            'localadmin' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.LOCALADMIN
        ),
        'macrocounty' VALUE json_object(
            'id' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.MACROCOUNTY_ID,
            'macrocounty' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.MACROCOUNTY
        ),
        'region' VALUE json_object(
            'id' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.REGION_ID,
            'region' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.REGION
        ),
        'country' VALUE json_object(
            'id' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.COUNTRY_ID,
            'country' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.COUNTRY
        )
    ) INTO OUT_JSON
    FROM SEM_CHR_GIS.localadmin_fra_etrs89
    where SDO_anyinteract(
        SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        geom) = 'TRUE';
    DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ADMINDIVISIONINFO_FRA FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISIONINFO_FRA_3;