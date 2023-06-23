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
create table TEMP_COORDINATES_INITIAL (
    ID INTEGER NOT NULL,
    lon varchar2(15) NOT NULL,
    lat varchar2(15) NOT NULL,
    epsg_code varchar(15),
    epsg_desc varchar(50),
    CONSTRAINT PK_TEMP_COORDINATES_INITIAL PRIMARY KEY (ID)
);
-- create sequence to have autoincrement pk
CREATE SEQUENCE TEMPCOORDINITIALS_SEQ;

-- create tigger using the sequence
CREATE OR REPLACE TRIGGER TEMPCOORDINITIALS_TRG 
BEFORE INSERT ON TEMP_COORDINATES_INITIAL 
FOR EACH ROW
WHEN (new.ID IS NULL)
BEGIN
  SELECT TEMPCOORDINITIALS_SEQ.NEXTVAL
  INTO   :new.ID
  FROM   dual;
END;

create table TEMP_COORDINATES_TRANSFORMED (
    ID INTEGER NOT NULL,
    lon varchar2(15) NOT NULL,
    lat varchar2(15) NOT NULL,
    initials_id NOT NULL,
    epsg_code varchar(15),
    epsg_desc varchar(50),
    CONSTRAINT FK_TEMP_COORDINATES_TRANSFORMED FOREIGN KEY (initials_id) REFERENCES TEMP_COORDINATES_INITIAL(ID)
);
-- create sequence to have autoincrement pk
CREATE SEQUENCE TEMPCOORDTRANSFORMED_SEQ;

-- create tigger using the sequence
CREATE OR REPLACE TRIGGER TEMPCOORDTRANSFORMED_TRG 
BEFORE INSERT ON TEMP_COORDINATES_TRANSFORMED 
FOR EACH ROW
WHEN (new.ID IS NULL)
BEGIN
  SELECT TEMPCOORDTRANSFORMED_SEQ.NEXTVAL
  INTO   :new.ID
  FROM   dual;
END;

--insertamos some initial coordinates
INSERT INTO TEMP_COORDINATES_INITIAL (ID, LON, LAT, EPSG_CODE, EPSG_DESC) VALUES ('1', '335396.576084', '4683376.954308', 'EPSG:23031', 'ED50 / UTM zone 31N')
INSERT INTO TEMP_COORDINATES_INITIAL (ID, LON, LAT, EPSG_CODE, EPSG_DESC) VALUES ('1', '400237.677142', '4652176.535812', 'EPSG:23031', 'ED50 / UTM zone 31N')


-- meto algun valor más por sql developer:
id:1
lon: 372503.164175
lat: 4642995.777040
epsg_code: EPSG:23031
epsg_desc: ED50 / UTM zone 31N

-- lo consulto y debo ver las 3 filas de la tabla
select * from TEMP_COORDINATES_INITIAL;