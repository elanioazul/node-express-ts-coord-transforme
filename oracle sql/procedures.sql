/*
PASOS PARA LANZAR EN LOCAL LA BD ORACLE
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
    original_coordinates_id NUMBER,
    transformed_geometry SDO_GEOMETRY,
    CONSTRAINT PK_TEMP_COORDINATES_TRANSFORMED PRIMARY KEY (ID),
    CONSTRAINT FK_TEMP_COORDINATES_TRANSFORMED FOREIGN KEY (original_coordinates_id)
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



/*
PASOS PARA REPLICAR ESTO MISMO EN LA BD ORACLE QAS DEL PROYECTO ES LO MISMO PERO CAMBIANDO EN ARCHVO .ENV CON LAS CREDENCIALES DE CONEXIÓN.
TAMPOCO ES NECESARIO LA CREACION DE USUARIO GIS PORQUE YA HAY UNO CREADO DE PRUEBAS, "SEM_CHR_GIS"
*/