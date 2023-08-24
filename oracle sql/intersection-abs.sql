CREATE OR REPLACE FUNCTION CHECK_INTERSECTION_WITH_ABS(
    p_longitude NUMBER,
    p_latitude NUMBER,
    p_srid NUMBER
) RETURN NUMBER AS
    v_result NUMBER;
BEGIN
    -- this is a crosschecking function. It counts number of rows (ABS) intersected.
    -- it is similar to yes/no function but returning 1/0 instead.
    SELECT COUNT(*)
    INTO v_result
    FROM SEM_CHR_GIS.abs_2020_etrs89
    -- next is a oracle spatial function 
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
    -- case there is ABS intersected
    IF isABSLayerIntersected > 0 THEN
        OUT_MESSAGE := 'ABS INTERSECTED BY POINT SUCCESS';
        -- create output json of the ABS intersected by analyzing the oracle spatial anyinteract relation between a point and the underlaying polygon layer
        SELECT JSON_ARRAYAGG(
            json_object( KEY 'codiabs' VALUE CODIABS, KEY 'nomabs' VALUE NOMABS, KEY 'codiss' VALUE CODISS, KEY 'nomss' VALUE NOMSS, KEY 'codirs' VALUE CODIRS, KEY 'nomrs' VALUE NOMRS, KEY 'codiaga' VALUE CODIAGA, KEY 'nomaga' VALUE NOMAGA, KEY 'estat' VALUE ESTAT, KEY 'observacions' VALUE OBSER)
            format json
            returning clob
        ) AS JSON 
        INTO OUT_JSON
        FROM SEM_CHR_GIS.abs_2020_etrs89
        where SDO_anyinteract(
            SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
            geom) = 'TRUE' FETCH NEXT 1 ROWS ONLY;
        DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    -- case there is not ABS intersected
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

DROP PROCEDURE "SEM_CHR_GIS"."ABSINTERSECTEDBYPOINT";
DROP FUNCTION "SEM_CHR_GIS"."CHECK_INTERSECTION_WITH_ABS";