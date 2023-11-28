create or replace FUNCTION count_resources (
    latitude NUMBER,
    longitude NUMBER,
    distance NUMBER,
    unit VARCHAR,
    srid NUMBER
) RETURN NUMBER AS
    suggestedResourcesCount NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO suggestedResourcesCount
    FROM (
        SELECT
            r.ID_VEHICLE
        FROM RESOURCES r
        WHERE SDO_WITHIN_DISTANCE(
            SDO_GEOMETRY(
                2001,
                srid,
                SDO_POINT_TYPE(longitude, latitude, NULL),
                NULL,
                NULL
            ),
            SDO_GEOMETRY(
                2001,
                srid,
                SDO_POINT_TYPE(r.LNG_WGS84, r.LAT_WGS84, NULL),
                NULL,
                NULL
            ),
            'distance=' || distance || ' unit=' || unit
        ) = 'TRUE'
    );
    RETURN suggestedResourcesCount;
END;




CREATE OR REPLACE PROCEDURE RESOURCES_BY_RADIO (
    latitude IN NUMBER,
    longitude IN NUMBER,
    distance IN NUMBER,
    unit IN VARCHAR,
    selectedSrid IN NUMBER,
    resourcesSrid IN NUMBER,
    targetSrid IN NUMBER,
    suggestedResources OUT CLOB
) AS
    vGeometry SDO_GEOMETRY;
    outDistanceUnit VARCHAR (10);
    outCount NUMBER;
BEGIN
    suggestedResources:= '[]';
    
    IF unit = 'KILOMETER' THEN
        outDistanceUnit := 'unit=KM';
    ELSIF unit = 'METER' THEN
        outDistanceUnit := 'unit=M';
    ELSE
        outDistanceUnit := 'unit=M';
    END IF;

    IF selectedSrid <> resourcesSrid THEN
        vGeometry := SDO_CS.TRANSFORM(
            SDO_GEOMETRY(2001, selectedSrid, SDO_POINT_TYPE(longitude, latitude, NULL), NULL, NULL),
            resourcesSrid
        );
    ELSE
        vGeometry := SDO_GEOMETRY(2001, resourcesSrid, SDO_POINT_TYPE(longitude, latitude, NULL), NULL, NULL);
    END IF;

    outCount := count_resources(vGeometry.SDO_POINT.Y, vGeometry.SDO_POINT.X, distance, unit, resourcesSrid);

    IF outCount = 0 THEN
        RAISE NO_DATA_FOUND;
    ELSE
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'id_vehicle' VALUE ID_VEHICLE,
                'tiporecurso' VALUE tiporecurso,
                'coordx' VALUE coordx,
                'coordy' VALUE coordy,
                'distance' VALUE distance
            ) ORDER BY distance ASC RETURNING CLOB)
        INTO suggestedResources
        FROM (
            SELECT
                r.ID_VEHICLE,
                r.tiporecurso,
                SDO_CS.TRANSFORM(
                    SDO_GEOMETRY(2001, resourcesSrid, SDO_POINT_TYPE(r.LNG_WGS84, r.LAT_WGS84, NULL), NULL, NULL),
                    targetSrid
                ).SDO_POINT.X AS coordx,
                SDO_CS.TRANSFORM(
                    SDO_GEOMETRY(2001, resourcesSrid, SDO_POINT_TYPE(r.LNG_WGS84, r.LAT_WGS84, NULL), NULL, NULL),
                    targetSrid
                ).SDO_POINT.Y AS coordy,
                SDO_GEOM.SDO_DISTANCE(
                    SDO_GEOMETRY(2001, vGeometry.SDO_SRID, SDO_POINT_TYPE(vGeometry.SDO_POINT.X, vGeometry.SDO_POINT.Y, NULL), NULL, NULL),
                    SDO_GEOMETRY(2001, vGeometry.SDO_SRID, SDO_POINT_TYPE(r.LNG_WGS84, r.LAT_WGS84, NULL), NULL, NULL),
                    0.005,
                    outDistanceUnit
                ) AS distance
            FROM RESOURCES r
            WHERE SDO_WITHIN_DISTANCE(
                SDO_GEOMETRY(
                    2001,
                    vGeometry.SDO_SRID,
                    SDO_POINT_TYPE(vGeometry.SDO_POINT.X, vGeometry.SDO_POINT.Y, NULL),
                    NULL,
                    NULL
                ),
                SDO_GEOMETRY(
                    2001,
                    resourcesSrid,
                    SDO_POINT_TYPE(r.LNG_WGS84, r.LAT_WGS84, NULL),
                    NULL,
                    NULL
                ),
                'distance=' || distance || ' unit=' || unit
            ) = 'TRUE'
        );
    END IF;
    DBMS_OUTPUT.PUT_LINE(suggestedResources);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No resources found within the given radius.');
        NULL;
END;



--esta es la que finalmente quería haber dejado Rafa, sin el conteo. Pero como Raymond en su código wrap native query Java cuenta, lo dejamos contando tras revisar que cambió lo mismo exactamente que los cambios de este commit
-- o sea, lo tocó Rafa, Raymond su wrap y luego me dicen a mi que medie =>>> wtf
create or replace PROCEDURE             RESOURCES_BY_RADIO_RAFA (
    latitude IN NUMBER,
    longitude IN NUMBER,
    distance IN NUMBER,
    unit IN VARCHAR,
    selectedSrid IN NUMBER,
    resourcesSrid IN NUMBER,
    targetSrid IN NUMBER,
    suggestedResources OUT CLOB
) AS
    vGeometry SDO_GEOMETRY;
    outDistanceUnit VARCHAR (10);
    outCount NUMBER;
BEGIN
    suggestedResources:= '[]';
    
    IF unit = 'KILOMETER' THEN
        outDistanceUnit := 'unit=KM';
    ELSIF unit = 'METER' THEN
        outDistanceUnit := 'unit=M';
    ELSE
        outDistanceUnit := 'unit=M';
    END IF;

    IF selectedSrid <> resourcesSrid THEN
        vGeometry := SDO_CS.TRANSFORM(
            SDO_GEOMETRY(2001, selectedSrid, SDO_POINT_TYPE(longitude, latitude, NULL), NULL, NULL),
            resourcesSrid
        );
    ELSE
        vGeometry := SDO_GEOMETRY(2001, resourcesSrid, SDO_POINT_TYPE(longitude, latitude, NULL), NULL, NULL);
    END IF;

    --outCount := count_resources(vGeometry.SDO_POINT.Y, vGeometry.SDO_POINT.X, distance, unit, resourcesSrid);

    IF true THEN
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'ID_VEHICLE' VALUE ID_VEHICLE,
                'tiporecurso' VALUE tiporecurso,
                'LAT_WGS84' VALUE LAT_WGS84,
                'LNG_WGS84' VALUE LNG_WGS84,
                'distance' VALUE distance
            ) ORDER BY distance ASC RETURNING CLOB)
        INTO suggestedResources
        FROM (
            SELECT
                r.ID_VEHICLE,
                r.tiporecurso,
                SDO_CS.TRANSFORM(
                    SDO_GEOMETRY(2001, resourcesSrid, SDO_POINT_TYPE(r.LNG_WGS84, r.LAT_WGS84, NULL), NULL, NULL),
                    targetSrid
                ).SDO_POINT.X AS LNG_WGS84,
                SDO_CS.TRANSFORM(
                    SDO_GEOMETRY(2001, resourcesSrid, SDO_POINT_TYPE(r.LNG_WGS84, r.LAT_WGS84, NULL), NULL, NULL),
                    targetSrid
                ).SDO_POINT.Y AS LAT_WGS84,
                SDO_GEOM.SDO_DISTANCE(
                    SDO_GEOMETRY(2001, vGeometry.SDO_SRID, SDO_POINT_TYPE(vGeometry.SDO_POINT.X, vGeometry.SDO_POINT.Y, NULL), NULL, NULL),
                    SDO_GEOMETRY(2001, vGeometry.SDO_SRID, SDO_POINT_TYPE(r.LNG_WGS84, r.LAT_WGS84, NULL), NULL, NULL),
                    0.005,
                    outDistanceUnit
                ) AS distance
            FROM RESOURCES r
            WHERE SDO_WITHIN_DISTANCE(
                SDO_GEOMETRY(
                    2001,
                    vGeometry.SDO_SRID,
                    SDO_POINT_TYPE(vGeometry.SDO_POINT.X, vGeometry.SDO_POINT.Y, NULL),
                    NULL,
                    NULL
                ),
                SDO_GEOMETRY(
                    2001,
                    resourcesSrid,
                    SDO_POINT_TYPE(r.LNG_WGS84, r.LAT_WGS84, NULL),
                    NULL,
                    NULL
                ),
                'distance=' || distance || ' unit=' || unit
            ) = 'TRUE'
        );
    END IF;
    DBMS_OUTPUT.PUT_LINE(suggestedResources);

END;