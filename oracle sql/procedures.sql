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
create table COORDINATES_INITIAL (
    ID INTEGER NOT NULL,
    lon varchar2(15) NOT NULL,
    lat varchar2(15) NOT NULL,
    epsg_code varchar(15),
    epsg_desc varchar(50),
    CONSTRAINT PK_COORDINATES_INITIAL PRIMARY KEY (ID)
);
-- create sequence to have autoincrement pk
CREATE SEQUENCE INITIALS_SEQ;

-- create tigger using the sequence
CREATE OR REPLACE TRIGGER INITIALS_TRG 
BEFORE INSERT ON COORDINATES_INITIAL 
FOR EACH ROW
WHEN (new.ID IS NULL)
BEGIN
  SELECT INITIALS_SEQ.NEXTVAL
  INTO   :new.ID
  FROM   dual;
END;

create table COORDINATES_TRANSFORMED (
    ID INTEGER NOT NULL,
    lon varchar2(15) NOT NULL,
    lat varchar2(15) NOT NULL,
    initial_id NOT NULL,
    epsg_code varchar(15),
    epsg_desc varchar(50),
    CONSTRAINT FK_COORDINATES_TRANSFORMED FOREIGN KEY (initial_id) REFERENCES COORDINATES_INITIAL(ID)
);
-- create sequence to have autoincrement pk
CREATE SEQUENCE TRANSFORMED_SEQ;

-- create tigger using the sequence
CREATE OR REPLACE TRIGGER TRANSFORMED_TRG 
BEFORE INSERT ON COORDINATES_TRANSFORMED 
FOR EACH ROW
WHEN (new.ID IS NULL)
BEGIN
  SELECT TRANSFORMED_SEQ.NEXTVAL
  INTO   :new.ID
  FROM   dual;
END;

--insertamos some initial coordinates
INSERT INTO COORDINATES_INITIAL (ID, LON, LAT, EPSG_CODE, EPSG_DESC) VALUES ('1', '335396.576084', '4683376.954308', 'EPSG:23031', 'ED50 / UTM zone 31N')
INSERT INTO COORDINATES_INITIAL (ID, LON, LAT, EPSG_CODE, EPSG_DESC) VALUES ('1', '400237.677142', '4652176.535812', 'EPSG:23031', 'ED50 / UTM zone 31N')


-- meto algun valor más por sql developer:
id:1
lon: 372503.164175
lat: 4642995.777040
epsg_code: EPSG:23031
epsg_desc: ED50 / UTM zone 31N

-- lo consulto y debo ver las 3 filas de la tabla
select * from coordinates_initial;