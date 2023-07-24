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

DROP TABLE "SEM_CHR_GIS"."COORDINATES_SYSTEMS" CASCADE CONSTRAINTS;
DROP TABLE "SEM_CHR_GIS"."COORDINATES_INITIAL" CASCADE CONSTRAINTS;
DROP TABLE "SEM_CHR_GIS"."COORDINATES_TRANSFORMED" CASCADE CONSTRAINTS;

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