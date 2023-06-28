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
    ID NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT by 1) NOT NULL,
    longitude NUMBER,
    latitude NUMBER,
    srid NUMBER,
    CONSTRAINT PK_TEMP_COORDINATES_INITIAL PRIMARY KEY (ID)
);
-- create sequence to have autoincrement pk
--CREATE SEQUENCE TEMP_COORDINATES_INITIAL_SEQ;

-- create tigger using the sequence
-- CREATE OR REPLACE TRIGGER TEMP_COORDINATES_INITIAL_TRG 
-- BEFORE INSERT ON TEMP_COORDINATES_INITIAL 
-- FOR EACH ROW
-- WHEN (new.id IS NULL)
-- BEGIN
--   SELECT TEMP_COORDINATES_INITIAL_SEQ.NEXTVAL
--   INTO   :new.id
--   FROM   dual;
-- END;

CREATE TABLE TEMP_COORDINATES_TRANSFORMED (
    ID NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT by 1),
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
--CREATE SEQUENCE TEMP_COORDINATES_TRANSFORMED_SEQ;

-- create tigger using the sequence
-- CREATE OR REPLACE TRIGGER TEMP_COORDINATES_TRANSFORMED_TRG 
-- BEFORE INSERT ON TEMP_COORDINATES_TRANSFORMED 
-- FOR EACH ROW
-- WHEN (new.id IS NULL)
-- BEGIN
--   SELECT TEMP_COORDINATES_TRANSFORMED_SEQ.NEXTVAL
--   INTO   :new.id
--   FROM   dual;
-- END;

--insertamos some initial coordinates
INSERT INTO TEMP_COORDINATES_INITIAL (ID, longitude, latitude, srid) VALUES (1.493404, 41.631894, 4258)
INSERT INTO TEMP_COORDINATES_INITIAL (ID, longitude, latitude, srid) VALUES (1.395264, 42.313878, 4258)
INSERT INTO TEMP_COORDINATES_INITIAL (ID, longitude, latitude, srid) VALUES (2.147827, 41.590797, 4258)

CREATE TABLE TEMP_COORDINATES_SYSTEMS (
    ID NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT by 1),
    epsg NUMBER,
    epsg_desc VARCHAR2(200),
    label VARCHAR2(200),
    label_advance VARCHAR2(200),
    CONSTRAINT PK_TEMP_COORDINATES_SYSTEMS PRIMARY KEY (ID)
);

INSERT INTO TEMP_COORDINATES_SYSTEMS (epsg, epsg_desc, label, label_advance) VALUES (4326, 'EPSG 4326 - WGS84', 'gps grados, minutos y segundos', 'WGS84 Geograficas (4326) GMS');
INSERT INTO TEMP_COORDINATES_SYSTEMS (epsg, epsg_desc, label, label_advance) VALUES (4326, 'EPSG 4326 - WGS84', 'gps grados decimales', 'WGS84 Geograficas (4326) GD');
INSERT INTO TEMP_COORDINATES_SYSTEMS (epsg, epsg_desc, label, label_advance) VALUES (3857, 'EPSG:3857 - WGS 84', 'x e y psudomercator (metros)', 'WGS84 PsueudoMercator(3857)');
INSERT INTO TEMP_COORDINATES_SYSTEMS (epsg, epsg_desc, label, label_advance) VALUES (23031, 'EPSG:23031 - ED50 / UTM zone 31N', 'ed50 utm (metros)', 'ED50 / UTM zone 31N');
INSERT INTO TEMP_COORDINATES_SYSTEMS (epsg, epsg_desc, label, label_advance) VALUES (4258, 'EPSG:4258 - ETRS89', 'etrs89 geograficas grados decimales', 'ETRS Geograficas (4258) GD');
INSERT INTO TEMP_COORDINATES_SYSTEMS (epsg, epsg_desc, label, label_advance) VALUES (4258, 'EPSG:4258 - ETRS89', 'etrs89 geograficas grados, minutos y segundos', 'ETRS Geograficas (4258) GMS');
INSERT INTO TEMP_COORDINATES_SYSTEMS (epsg, epsg_desc, label, label_advance) VALUES (25831, 'EPSG:25831 - ETRS89 / UTM zone 31N', 'etrs89 catalunya proyectadas (metros)', 'ETRS89 UTM huso 31N (25831)');

-- most current procedure in the controller located
