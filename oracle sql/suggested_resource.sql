--return the data as an array
-----------------------------
----------------------------
-- CREATE OR REPLACE TYPE ResourceInfo AS OBJECT (
--     id NUMBER,
--     tiporecurso VARCHAR2(255),
--     matricula VARCHAR2(255),
--     abscisa NUMBER,
--     ordenada NUMBER
-- );

-- CREATE OR REPLACE TYPE ResourceInfoArray AS VARRAY OF ResourceInfo;

-- CREATE OR REPLACE FUNCTION GetResourcesWithinDistance(
--     latitude NUMBER,
--     longitude NUMBER,
--     distance_meters NUMBER,
--     selectedSrid NUMBER,
--     resourcesSrid NUMBER
-- ) RETURN ResourceInfoArray
-- IS
--     suggestedResources ResourceInfoArray;
-- BEGIN
--     SELECT ResourceInfo(
--                id,
--                tiporecurso,
--                matricula,
--                abscisa,
--                ordenada
--            )
--     BULK COLLECT INTO suggestedResources
--     FROM (
--         SELECT
--             r.id,
--             r.tiporecurso,
--             r.matricula,
--             r.abscisa,
--             r.ordenada,
--             SDO_NN_DISTANCE(1) AS distance
--         FROM RESOURCES r
--         WHERE SDO_WITHIN_DISTANCE(
--             SDO_GEOMETRY(
--                 2001,
--                 selectedSrid,
--                 SDO_POINT_TYPE(longitude, latitude, NULL),
--                 NULL,
--                 NULL
--             ),
--             SDO_GEOMETRY(
--                 2001,
--                 resourcesSrid,
--                 SDO_POINT_TYPE(r.abscisa, r.ordenada, NULL),
--                 NULL,
--                 NULL
--             ),
--             'distance=' || distance_meters
--         ) = 'TRUE'
--         ORDER BY distance
--     );

--     RETURN suggestedResources;
-- END;


--returns the result as a JSON object
-------------------------------------
-------------------------------------
-- CREATE OR REPLACE FUNCTION GetResourcesWithinDistanceJSON(
--     latitude NUMBER,
--     longitude NUMBER,
--     distance_meters NUMBER,
--     selectedSrid NUMBER,
--     resourcesSrid NUMBER
-- ) RETURN CLOB
-- IS
--     suggestedResources CLOB;
-- BEGIN
--     SELECT JSON_ARRAYAGG(
--                JSON_OBJECT(
--                    'id' VALUE id,
--                    'tiporecurso' VALUE tiporecurso,
--                    'matricula' VALUE matricula,
--                    'bastidor' VALUE bastidor,
--                    'abscisa' VALUE abscisa,
--                    'ordenada' VALUE ordenada,
--                    'distance' VALUE SDO_NN_DISTANCE(1)
--                )
--            )
--     INTO suggestedResources
--     FROM (
--         SELECT
--             r.id,
--             r.tiporecurso,
--             r.matricula,
--             r.bastidor,
--             r.abscisa,
--             r.ordenada,
--             SDO_NN_DISTANCE(1)
--         FROM RESOURCES r
--         WHERE SDO_WITHIN_DISTANCE(
--             SDO_GEOMETRY(
--                 2001,
--                 selectedSrid,
--                 SDO_POINT_TYPE(longitude, latitude, NULL),
--                 NULL,
--                 NULL
--             ),
--             SDO_GEOMETRY(
--                 2001,
--                 resourcesSrid,
--                 SDO_POINT_TYPE(r.abscisa, r.ordenada, NULL),
--                 NULL,
--                 NULL
--             ),
--             'distance=' || distance_meters
--         ) = 'TRUE'
--         ORDER BY distance
--     );

--     RETURN suggestedResources;
-- END;


--returns the result as a JSON object but changed to previuls time used JSON_ARRAYAGG in ABSINTERSECTEDBYPOINT procedure
-------------------------------------
-------------------------------------
-- create or replace FUNCTION GET_RESOURCES_WITHIN_DISTANCE(
--     latitude NUMBER,
--     longitude NUMBER,
--     distance_meters NUMBER,
--     selectedSrid NUMBER,
--     resourcesSrid NUMBER
-- ) RETURN CLOB
-- IS
--     suggestedResources CLOB;
-- BEGIN
--     SELECT JSON_ARRAYAGG(
--         JSON_OBJECT(
--             KEY 'ID' VALUE r.ID,
--             KEY 'TIPORECURSO' VALUE r.TIPORECURSO,
--             KEY 'MATRICULA' VALUE r.MATRICULA,
--             KEY 'ABSCISA' VALUE r.ABSCISA,
--             KEY 'ORDENADA' VALUE r.ORDENADA,
--             KEY 'distance' VALUE d
--         )
--         format json
--         returning clob
--     ) AS JSON
--     INTO suggestedResources
--     FROM (
--         SELECT
--             r.ID,
--             r.TIPORECURSO,
--             r.MATRICULA,
--             r.ABSCISA,
--             r.ORDENADA
--         FROM SEM_CHR_GIS.RESOURCES r
--         WHERE SDO_WITHIN_DISTANCE(
--             SDO_GEOMETRY(
--                 2001,
--                 selectedSrid,
--                 SDO_POINT_TYPE(longitude, latitude, NULL),
--                 NULL,
--                 NULL
--             ),
--             SDO_GEOMETRY(
--                 2001,
--                 resourcesSrid,
--                 SDO_POINT_TYPE(r.abscisa, r.ordenada, NULL),
--                 NULL,
--                 NULL
--             ),
--             'distance=' || distance_meters
--         ) = 'TRUE'
--     ) r
--     CROSS JOIN (
--         SELECT SDO_NN_DISTANCE(1) AS d
--         FROM DUAL
--     ) d;

--     RETURN suggestedResources;
-- END;



--query que funciona
--  SELECT
--  r.resources_id,
--  r.bastidor,
--  r.coordx,
--  r.coordy
-- FROM SEM_CHR_GIS.RESOURCES r
-- WHERE sdo_within_distance (
--      SDO_GEOMETRY(
--         2001,
--         25831,
--         SDO_POINT_TYPE(417983.87416212, 4601821.73652691, NULL),
--         NULL,
--         NULL
--     ),
--     SDO_GEOMETRY(
--         2001,
--         25831,
--         SDO_POINT_TYPE(COORDX, COORDY, NULL),
--         NULL,
--         NULL
--     ),
--     'distance = 1 unit = KILOMETER'
-- ) = 'TRUE';

--query que no funciona
--ORA-29908: falta la llamada principal al operador auxiliar
--29908. 00000 -  "missing primary invocation for ancillary operator"
--*Cause:    The primary invocation corresponding to an ancillary operator is missing.
--  SELECT
--  r.resources_id,
--  r.bastidor,
--  r.coordx,
--  r.coordy,
--  SDO_NN_DISTANCE(1) AS distance
-- FROM SEM_CHR_GIS.RESOURCES r
-- WHERE sdo_within_distance (
--      SDO_GEOMETRY(
--         2001,
--         25831,
--         SDO_POINT_TYPE(417983.87416212, 4601821.73652691, NULL),
--         NULL,
--         NULL
--     ),
--     SDO_GEOMETRY(
--         2001,
--         25831,
--         SDO_POINT_TYPE(COORDX, COORDY, NULL),
--         NULL,
--         NULL
--     ),
--     'distance = 1 unit = KILOMETER'
-- ) = 'TRUE'
-- ORDER BY distance;

--query que funciona sacando distance por cada recurso:
-- SELECT
--  r.resources_id,
--  r.bastidor,
--  r.coordx,
--  r.coordy,
--  SDO_GEOM.SDO_DISTANCE(
--     SDO_GEOMETRY(2001, 25831, SDO_POINT_TYPE(417983.87416212, 4601821.73652691, NULL), NULL, NULL),
--     SDO_GEOMETRY(2001, 25831, SDO_POINT_TYPE(r.coordx, r.coordy, NULL), NULL, NULL),
--     0.005 -- Tolerance value for distance calculation (adjust as needed)
--  ) AS distance
-- FROM SEM_CHR_GIS.RESOURCES r
-- WHERE sdo_within_distance (
--      SDO_GEOMETRY(
--         2001,
--         25831,
--         SDO_POINT_TYPE(417983.87416212, 4601821.73652691, NULL),
--         NULL,
--         NULL
--     ),
--     SDO_GEOMETRY(
--         2001,
--         25831,
--         SDO_POINT_TYPE(r.coordx, r.coordy, NULL),
--         NULL,
--         NULL
--     ),
--     'distance = 1 unit = KILOMETER'
-- ) = 'TRUE'
-- ORDER BY distance;



--Definitivo viendo la query que saca distancia por cada registro:
-- create or replace FUNCTION GET_RESOURCES_WITHIN_DISTANCE (
--     latitude NUMBER,
--     longitude NUMBER,
--     distance NUMBER,
--     unit VARCHAR,
--     selectedSrid NUMBER,
--     resourcesSrid NUMBER
-- ) RETURN CLOB
-- IS
--     suggestedResources CLOB;
-- BEGIN
--     WITH DistanceCTE AS (
--         SELECT
--             r.resources_id,
--             r.tiporecurso,
--             r.matricula,
--             r.bastidor,
--             r.coordx,
--             r.coordy,
--             SDO_GEOM.SDO_DISTANCE(
--                 SDO_GEOMETRY(2001, 25831, SDO_POINT_TYPE(longitude, latitude, NULL), NULL, NULL),
--                 SDO_GEOMETRY(2001, 25831, SDO_POINT_TYPE(r.coordx, r.coordy, NULL), NULL, NULL),
--                 0.005
--             ) AS distance
--         FROM RESOURCES r
--         WHERE SDO_WITHIN_DISTANCE(
--             SDO_GEOMETRY(
--                 2001,
--                 selectedSrid,
--                 SDO_POINT_TYPE(longitude, latitude, NULL),
--                 NULL,
--                 NULL
--             ),
--             SDO_GEOMETRY(
--                 2001,
--                 resourcesSrid,
--                 SDO_POINT_TYPE(r.coordx, r.coordy, NULL),
--                 NULL,
--                 NULL
--             ),
--             'distance=' || distance || ' unit=' || unit
--         ) = 'TRUE'
--     )

--     SELECT JSON_ARRAYAGG(
--         JSON_OBJECT(
--             'resources_id' VALUE resources_id,
--             'tiporecurso' VALUE tiporecurso,
--             'matricula' VALUE matricula,
--             'bastidor' VALUE bastidor,
--             'coordx' VALUE coordx,
--             'coordy' VALUE coordy,
--             'distance' VALUE distance
--         ) RETURNING CLOB)
--     INTO suggestedResources
--     FROM DistanceCTE;

--     RETURN suggestedResources;
-- END;


--Definitivo ORDENADO POR DISTANCE viendo la query que saca distancia por cada registro:
create or replace FUNCTION GET_RESOURCES_WITHIN_DISTANCE_ORDER_BY_DISTANCE (
    latitude NUMBER,
    longitude NUMBER,
    distance NUMBER,
    unit VARCHAR,
    selectedSrid NUMBER,
    resourcesSrid NUMBER
) RETURN CLOB
IS
    suggestedResources CLOB;
BEGIN
    WITH DistanceCTE AS (
        SELECT
            r.resources_id,
            r.tiporecurso,
            r.matricula,
            r.bastidor,
            r.coordx,
            r.coordy,
            SDO_GEOM.SDO_DISTANCE(
                SDO_GEOMETRY(2001, resourcesSrid, SDO_POINT_TYPE(longitude, latitude, NULL), NULL, NULL),
                SDO_GEOMETRY(2001, resourcesSrid, SDO_POINT_TYPE(r.coordx, r.coordy, NULL), NULL, NULL),
                0.005
            ) AS distance
        FROM RESOURCES r
        WHERE SDO_WITHIN_DISTANCE(
            SDO_GEOMETRY(
                2001,
                selectedSrid,
                SDO_POINT_TYPE(longitude, latitude, NULL),
                NULL,
                NULL
            ),
            SDO_GEOMETRY(
                2001,
                resourcesSrid,
                SDO_POINT_TYPE(r.coordx, r.coordy, NULL),
                NULL,
                NULL
            ),
            'distance=' || distance || ' unit=' || unit
        ) = 'TRUE'
    )

    SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
            'resources_id' VALUE resources_id,
            'tiporecurso' VALUE tiporecurso,
            'matricula' VALUE matricula,
            'bastidor' VALUE bastidor,
            'coordx' VALUE coordx,
            'coordy' VALUE coordy,
            'distance' VALUE distance
        ) RETURNING CLOB)
    INTO suggestedResources
    FROM DistanceCTE ORDER BY distance;


    DBMS_OUTPUT.PUT_LINE(suggestedResources);

    RETURN suggestedResources;
END;


--Evolución definitivo en vez de coget coordx y coordy, cogiendo X e y del attributo Geom:

--Evolucion definitivo metiendo EXCEPCION cuando no recusos encontrados:
CREATE OR REPLACE FUNCTION GET_RESOURCES_WITHIN_DISTANCE_ORDER_BY_DISTANCE (
    latitude NUMBER,
    longitude NUMBER,
    distance NUMBER,
    unit VARCHAR,
    selectedSrid NUMBER,
    resourcesSrid NUMBER
) RETURN CLOB
IS
    suggestedResources CLOB;
    suggestedResourcesCount NUMBER;
BEGIN
    -- Define a subquery to count rows that meet the criteria
    SELECT COUNT(*)
    INTO suggestedResourcesCount
    FROM (
        SELECT
            r.resources_id,
            r.tiporecurso,
            r.matricula,
            r.bastidor,
            r.coordx,
            r.coordy,
            SDO_GEOM.SDO_DISTANCE(
                SDO_GEOMETRY(2001, resourcesSrid, SDO_POINT_TYPE(longitude, latitude, NULL), NULL, NULL),
                SDO_GEOMETRY(2001, resourcesSrid, SDO_POINT_TYPE(r.coordx, r.coordy, NULL), NULL, NULL),
                0.005
            ) AS distance
        FROM RESOURCES r
        WHERE SDO_WITHIN_DISTANCE(
            SDO_GEOMETRY(
                2001,
                selectedSrid,
                SDO_POINT_TYPE(longitude, latitude, NULL),
                NULL,
                NULL
            ),
            SDO_GEOMETRY(
                2001,
                resourcesSrid,
                SDO_POINT_TYPE(r.coordx, r.coordy, NULL),
                NULL,
                NULL
            ),
            'distance=' || distance || ' unit=' || unit
        ) = 'TRUE'
    );

    IF suggestedResourcesCount = 0 THEN
        -- Raise a NO_DATA_FOUND exception
        RAISE NO_DATA_FOUND;
    ELSE
        -- Retrieve the JSON result when data is found
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'resources_id' VALUE resources_id,
                'tiporecurso' VALUE tiporecurso,
                'matricula' VALUE matricula,
                'bastidor' VALUE bastidor,
                'coordx' VALUE coordx,
                'coordy' VALUE coordy,
                'distance' VALUE distance
            ) RETURNING CLOB)
        INTO suggestedResources
        FROM (
            SELECT
                r.resources_id,
                r.tiporecurso,
                r.matricula,
                r.bastidor,
                r.coordx,
                r.coordy,
                SDO_GEOM.SDO_DISTANCE(
                    SDO_GEOMETRY(2001, resourcesSrid, SDO_POINT_TYPE(longitude, latitude, NULL), NULL, NULL),
                    SDO_GEOMETRY(2001, resourcesSrid, SDO_POINT_TYPE(r.coordx, r.coordy, NULL), NULL, NULL),
                    0.005
                ) AS distance
            FROM RESOURCES r
            WHERE SDO_WITHIN_DISTANCE(
                SDO_GEOMETRY(
                    2001,
                    selectedSrid,
                    SDO_POINT_TYPE(longitude, latitude, NULL),
                    NULL,
                    NULL
                ),
                SDO_GEOMETRY(
                    2001,
                    resourcesSrid,
                    SDO_POINT_TYPE(r.coordx, r.coordy, NULL),
                    NULL,
                    NULL
                ),
                'distance=' || distance || ' unit=' || unit
            ) = 'TRUE'
        ) ORDER BY distance;
    END IF;

    DBMS_OUTPUT.PUT_LINE(suggestedResources);

    RETURN suggestedResources;
EXCEPTION
    -- Handle the NO_DATA_FOUND exception by returning an empty array
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No resources found within the given radius.');
        RETURN '[]';
END;



--FINAL
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
            r.resources_id
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
                SDO_POINT_TYPE(r.coordx, r.coordy, NULL),
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
    suggestedResources OUT CLOB
) AS
    vGeometry SDO_GEOMETRY;
    outCount NUMBER;
BEGIN
    suggestedResources:= '[]';

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
                'resources_id' VALUE resources_id,
                'tiporecurso' VALUE tiporecurso,
                'coordx' VALUE coordx,
                'coordy' VALUE coordy,
                'distance' VALUE distance
            ) ORDER BY distance ASC RETURNING CLOB)
        INTO suggestedResources
        FROM (
            SELECT
                r.resources_id,
                r.tiporecurso,
                r.coordx,
                r.coordy,
                SDO_GEOM.SDO_DISTANCE(
                    SDO_GEOMETRY(2001, vGeometry.SDO_SRID, SDO_POINT_TYPE(vGeometry.SDO_POINT.X, vGeometry.SDO_POINT.Y, NULL), NULL, NULL),
                    SDO_GEOMETRY(2001, vGeometry.SDO_SRID, SDO_POINT_TYPE(r.coordx, r.coordy, NULL), NULL, NULL),
                    0.005
                ) AS distance
            FROM RESOURCES r
            WHERE SDO_WITHIN_DISTANCE( --se podría pasar aqui resourcesSrid y vGeometry.SDO_POINT.X & vGeometry.SDO_POINT.Y en vez del punto original
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
                    SDO_POINT_TYPE(r.coordx, r.coordy, NULL),
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