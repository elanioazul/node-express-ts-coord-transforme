/*
PASOS PARA LANZAR EN LOCAL LA BD ORACLE;
PASOS PARA REPLICAR ESTO MISMO EN LA BD ORACLE QAS DEL PROYECTO ES LO MISMO PERO CAMBIANDO EN ARCHVO .ENV CON LAS CREDENCIALES DE CONEXIÓN Y NO LANZAR EL DOCKER EN LOCAL.
TAMPOCO ES NECESARIO LA CREACION DE USUARIO GIS PORQUE YA HAY UNO CREADO DE PRUEBAS, "SEM_CHR_GIS AL QUE APUNTO CON .ENV"
*/

--docker run -d --name oracle-db -p 1521:1521 -e ORACLE_PWD=test container-registry.oracle.com/database/enterprise:latest

--me conecto (aunque tarda un rato la conexion en hacerse correctamente) con sqldeveloper a la bd que corre el container con:
USUARIO: SYS as SYSDBA
CONTRASEÑA: test
NOMBRE DEL HOST: localhost
PUERTO: 1521
NOMBRE DEL SERVICIO: orclpdb1


--hago un script sql para crear nuevo squema (nuevo user) y asi crear nueva conexion
alter session set "_ORACLE_SCRIPT"=true;
create user GIS identified by "123" default tablespace users quota unlimited on users;
grant resource, connect, create table, create session to GIS;

--me conecto con sqldeveloper a dicho nuevo squema con la con los parametros de conexion:
USUARIO: GIS
CONTRASEÑA: 123
NOMBRE DEL HOST: localhost
PUERTO: 1521
NOMBRE DEL SERVICIO: orclpdb1

--hago tablas
CREATE TABLE TEMP_COORDINATES_INITIAL (
    ID NUMBER NOT NULL,
    longitude NUMBER,
    latitude NUMBER,
    srid NUMBER,
    CONSTRAINT PK_TEMP_COORDINATES_INITIAL PRIMARY KEY (ID)
);
-- create sequence to have autoincrement pk
CREATE SEQUENCE TEMP_COORDINATES_INITIAL_SEQ;

-- create tigger using the sequence
CREATE OR REPLACE TRIGGER TEMP_COORDINATES_INITIAL_TRG 
BEFORE INSERT ON TEMP_COORDINATES_INITIAL 
FOR EACH ROW
WHEN (new.id IS NULL)
BEGIN
  SELECT TEMP_COORDINATES_INITIAL_SEQ.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;

CREATE TABLE TEMP_COORDINATES_TRANSFORMED (
    ID NUMBER NOT NULL,
    initial_coordinates_id NUMBER,
    longitude NUMBER,
    latitude NUMBER,
    srid NUMBER,
    transformed_geometry SDO_GEOMETRY,
    CONSTRAINT PK_TEMP_COORDINATES_TRANSFORMED PRIMARY KEY (ID),
    CONSTRAINT FK_TEMP_COORDINATES_TRANSFORMED FOREIGN KEY (initial_coordinates_id)
        REFERENCES TEMP_COORDINATES_INITIAL (ID)
);
-- create sequence to have autoincrement pk
CREATE SEQUENCE TEMP_COORDINATES_TRANSFORMED_SEQ;

-- create tigger using the sequence
CREATE OR REPLACE TRIGGER TEMP_COORDINATES_TRANSFORMED_TRG 
BEFORE INSERT ON TEMP_COORDINATES_TRANSFORMED 
FOR EACH ROW
WHEN (new.id IS NULL)
BEGIN
  SELECT TEMP_COORDINATES_TRANSFORMED_SEQ.NEXTVAL
  INTO   :new.id
  FROM   dual;
END;

--insertamos some initial coordinates
INSERT INTO TEMP_COORDINATES_INITIAL (ID, longitude, latitude, srid) VALUES (1, 1.493404, 41.631894, 4258)
INSERT INTO TEMP_COORDINATES_INITIAL (ID, longitude, latitude, srid) VALUES (2, 1.395264, 42.313878, 4258)
INSERT INTO TEMP_COORDINATES_INITIAL (ID, longitude, latitude, srid) VALUES (NULL, 2.147827, 41.590797, 4258)


-- lo consulto y debo ver las 3 filas de la tabla
select * from TEMP_COORDINATES_INITIAL;

-- procedure

create or replace PROCEDURE TransformPointCoodinatesAndStore(
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR
) AS
    vTransformedGeometry SDO_GEOMETRY;
    vJsonRepresentation VARCHAR2(4000);
    vOriginalCoordinatesId NUMBER;
BEGIN
    -- Create the point geometry with 25831 as target srid
    vTransformedGeometry := SDO_CS.TRANSFORM(
        SDO_GEOMETRY(2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        25831
    );

    -- Convert the transformed geometry to JSON
    vJsonRepresentation := SDO_Util.TO_JSON(vTransformedGeometry);
    
    -- Store the initial coordinates and the srid selected by the user in the table and get the generated primary key
    INSERT INTO TEMP_COORDINATES_INITIAL (longitude, latitude, srid)
    VALUES (pLongitude, pLatitude, selectedSrid)
    RETURNING id INTO vOriginalCoordinatesId;
    DBMS_OUTPUT.PUT_LINE('This transformation corresponde to the id ' || vOriginalCoordinatesId || ' of TEMP_COORDINATES_INITIAL table');
     -- Store the transformed coordinates, referencing the foreign keying also
    INSERT INTO TEMP_COORDINATES_TRANSFORMED (id, initial_coordinates_id, longitude, latitude, srid, transformed_geometry)
    VALUES (TEMP_COORDINATES_TRANSFORMED_SEQ.NEXTVAL,vOriginalCoordinatesId, vTransformedGeometry.SDO_POINT.X, vTransformedGeometry.SDO_POINT.Y, vTransformedGeometry.SDO_SRID, vTransformedGeometry);

    -- Output the JSON representation
    DBMS_OUTPUT.PUT_LINE(vJsonRepresentation);

    OUT_MESSAGE := 'SUCCESS';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
        OUT_MESSAGE := 'FAILURE';
END;


--tabla para poblar el dropdown de tipo de coordenda
CREATE TABLE TEMP_COORDINATES_SYSTEMS (
    ID NUMBER NOT NULL,
    epsg NUMBER,
    epsg_desc VARCHAR2(200),
    label VARCHAR2(200),
    label_advance VARCHAR2(200),
    CONSTRAINT PK_TEMP_COORDINATES_SYSTEMS PRIMARY KEY (ID)
);

INSERT INTO TEMP_COORDINATES_SYSTEMS (ID, epsg, epsg_desc, label, label_advance) VALUES (1, 4326, 'EPSG 4326 - WGS84', 'gps grados, minutos y segundos', 'WGS84 Geograficas (4326) GMS');
INSERT INTO TEMP_COORDINATES_SYSTEMS (ID, epsg, epsg_desc, label, label_advance) VALUES (2, 4326, 'EPSG 4326 - WGS84', 'gps grados decimales', 'WGS84 Geograficas (4326) GD');
INSERT INTO TEMP_COORDINATES_SYSTEMS (ID, epsg, epsg_desc, label, label_advance) VALUES (3, 3857, 'EPSG:3857 - WGS 84', 'x e y psudomercator (metros)', 'WGS84 PsueudoMercator(3857)');
INSERT INTO TEMP_COORDINATES_SYSTEMS (ID, epsg, epsg_desc, label, label_advance) VALUES (4, 23031, 'EPSG:23031 - ED50 / UTM zone 31N', 'ed50 utm (metros)', 'ED50 / UTM zone 31N');
INSERT INTO TEMP_COORDINATES_SYSTEMS (ID, epsg, epsg_desc, label, label_advance) VALUES (5, 4258, 'EPSG:4258 - ETRS89', 'etrs89 geograficas grados decimales', 'ETRS Geograficas (4258) GD');
INSERT INTO TEMP_COORDINATES_SYSTEMS (ID, epsg, epsg_desc, label, label_advance) VALUES (6, 4258, 'EPSG:4258 - ETRS89', 'etrs89 geograficas grados, minutos y segundos', 'ETRS Geograficas (4258) GMS');
INSERT INTO TEMP_COORDINATES_SYSTEMS (ID, epsg, epsg_desc, label, label_advance) VALUES (7, 25831, 'EPSG:25831 - ETRS89 / UTM zone 31N', 'etrs89 catalunya proyectadas (metros)', 'ETRS89 UTM huso 31N (25831)');