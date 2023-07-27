create or replace FUNCTION GET_COUNTRY_ID_INTERSECTED_BY_POINT(
    p_longitude NUMBER,
    p_latitude NUMBER,
    p_srid NUMBER
) RETURN VARCHAR2 AS
    v_result VARCHAR2(200);
BEGIN
    SELECT TARGET_TABLE
    INTO v_result
    FROM SEM_CHR_GIS.COUNTRY_ETRS89
    WHERE SDO_ANYINTERACT(
        SDO_GEOMETRY(2001, p_srid, SDO_POINT_TYPE(p_longitude, p_latitude, NULL), NULL, NULL),
        geom
    ) = 'TRUE' ORDER BY PRIORITY ASC FETCH NEXT 1 ROWS ONLY;

    RETURN v_result;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('It does not intersect any country, probably derived from a scale/generalization topology gap or because water has been intersected');
            v_result := 'AGUA';
            RETURN v_result;
END;

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

create or replace PROCEDURE ADMINDIVISION_ESP (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
BEGIN
    OUT_MESSAGE := 'ADMINDIVISION_ESP SUCCESS';
    SELECT json_object(
        'country' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.country,
        'countryId' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.COUNTRY_ID,
        'countryCode' VALUE NULL,
        'region' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.REGION,
        'regionId' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.REGION_ID,
        'macrocounty' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.MACROCOUNTY,
        'macrocountyId' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.MACROCOUNTY,
        'localadmin' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.LOCALADMIN,
        'localadminId' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.LOCALADMIN_ID,
        'locality' VALUE NULL,
        'localityId' VALUE NUll,
        'borough' VALUE NULL,
        'boroughId' VALUE NULL,
        'boroughCode' VALUE NULL,
        'neighbourhood' VALUE NULL,
        'neighbourhoodId' VALUE NULL,
        'neighbourhoodCode' VALUE NULL,
        'sm1' VALUE NULL,
        'sm1Id' VALUE NULL,
        'sm2' VALUE NULL,
        'sm2Id' VALUE NULL
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
            OUT_MESSAGE := 'ADMINDIVISION_ESP FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISION_ESP;

create or replace PROCEDURE ADMINDIVISION_CAT (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
BEGIN
    OUT_MESSAGE := 'ADMINDIVISION_CAT SUCCESS';
    SELECT json_object(
        'country' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.country,
        'countryId' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.COUNTRY_ID,
        'countryCode' VALUE NULL,
        'region' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.REGION,
        'regionId' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.REGION_ID,
        'macrocounty' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.MACROCOUNTY,
        'macrocountyId' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.MACROCOUNTY_ID,
        'localadmin' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.LOCALADMIN,
        'localadminId' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.LOCALADMIN_ID,
        'locality' VALUE NULL,
        'localityId' VALUE NUll,
        'borough' VALUE NULL,
        'boroughId' VALUE NULL,
        'boroughCode' VALUE NULL,
        'neighbourhood' VALUE NULL,
        'neighbourhoodId' VALUE NULL,
        'neighbourhoodCode' VALUE NULL,
        'sm1' VALUE NULL,
        'sm1Id' VALUE NULL,
        'sm2' VALUE NULL,
        'sm2Id' VALUE NULL
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
            OUT_MESSAGE := 'ADMINDIVISION_CAT FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISION_CAT;

create or replace PROCEDURE ADMINDIVISION_FRA (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
BEGIN
    OUT_MESSAGE := 'ADMINDIVISION_FRA SUCCESS';
    SELECT json_object(
        'country' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.country,
        'countryId' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.COUNTRY_ID,
        'countryCode' VALUE NULL,
        'region' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.REGION,
        'regionId' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.REGION_ID,
        'macrocounty' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.MACROCOUNTY,
        'macrocountyId' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.MACROCOUNTY_ID,
        'localadmin' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.LOCALADMIN,
        'localadminId' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.LOCALADMIN_ID,
        'locality' VALUE NULL,
        'localityId' VALUE NUll,
        'borough' VALUE NULL,
        'boroughId' VALUE NULL,
        'boroughCode' VALUE NULL,
        'neighbourhood' VALUE NULL,
        'neighbourhoodId' VALUE NULL,
        'neighbourhoodCode' VALUE NULL,
        'sm1' VALUE NULL,
        'sm1Id' VALUE NULL,
        'sm2' VALUE NULL,
        'sm2Id' VALUE NULL
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
            OUT_MESSAGE := 'ADMINDIVISION_FRA FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISION_FRA;

create or replace PROCEDURE ADMINDIVISION_AND (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
BEGIN
    OUT_MESSAGE := 'ADMINDIVISION_AND SUCCESS';
    SELECT json_object(
        'country' VALUE SEM_CHR_GIS.localadmin_and_etrs89.country,
        'countryId' VALUE SEM_CHR_GIS.localadmin_and_etrs89.COUNTRY_ID,
        'countryCode' VALUE NULL,
        'region' VALUE NULL,
        'regionId' VALUE NULL,
        'macrocounty' VALUE NULL,
        'macrocountyId' VALUE NULL,
        'localadmin' VALUE SEM_CHR_GIS.localadmin_and_etrs89.LOCALADMIN,
        'localadminId' VALUE SEM_CHR_GIS.localadmin_and_etrs89.LOCALADMIN_ID,
        'locality' VALUE NULL,
        'localityId' VALUE NUll,
        'borough' VALUE NULL,
        'boroughId' VALUE NULL,
        'boroughCode' VALUE NULL,
        'neighbourhood' VALUE NULL,
        'neighbourhoodId' VALUE NULL,
        'neighbourhoodCode' VALUE NULL,
        'sm1' VALUE NULL,
        'sm1Id' VALUE NULL,
        'sm2' VALUE NULL,
        'sm2Id' VALUE NULL
        format json
        returning clob
    ) AS JSON 
    INTO OUT_JSON
    FROM SEM_CHR_GIS.localadmin_and_etrs89
    where SDO_anyinteract(
        SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        geom) = 'TRUE';
    DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ADMINDIVISION_AND FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISION_AND;

create or replace PROCEDURE ADMINDIVISION_NEIGHBOURHOOD_BCN (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    OUT_MESSAGE OUT VARCHAR,
    OUT_JSON OUT CLOB
) AS 
BEGIN
    OUT_MESSAGE := 'ADMINDIVISION_NEIGHBOURHOOD_BCN SUCCESS';
    SELECT json_object(
        'country' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.country,
        'countryId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.COUNTRY_ID,
        'countryCode' VALUE NULL,
        'region' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.REGION,
        'regionId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.REGION_ID,
        'macrocounty' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.MACROCOUNTY,
        'macrocountyId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.MACROCOUNTY_ID,
        'localadmin' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.LOCALADMIN,
        'localadminId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.LOCALADMIN_ID,
        'locality' VALUE NULL,
        'localityId' VALUE NUll,
        'borough' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.BOROUGH,
        'boroughId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.BOROUGH_ID,
        'boroughCode' VALUE NULL,
        'neighbourhood' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.NEIGHBOURHOOD,
        'neighbourhoodId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.NEIGHBOURHOOD_ID,
        'neighbourhoodCode' VALUE NULL,
        'sm1' VALUE NULL,
        'sm1Id' VALUE NULL,
        'sm2' VALUE NULL,
        'sm2Id' VALUE NULL
        format json
        returning clob
    ) AS JSON 
    INTO OUT_JSON
    FROM SEM_CHR_GIS.neighbourhood_bcn_etrs89
    where SDO_anyinteract(
        SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        geom) = 'TRUE';
    DBMS_OUTPUT.PUT_LINE(OUT_JSON);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
            OUT_MESSAGE := 'ADMINDIVISION_NEIGHBOURHOOD_BCN FAILURE';
            OUT_JSON:= JSON_OBJECT();
END ADMINDIVISION_NEIGHBOURHOOD_BCN;

create or replace PROCEDURE ADMINDIVISION_INTERSECTION (
    pLongitude IN NUMBER,
    pLatitude IN NUMBER,
    selectedSrid IN NUMBER,
    GLOBAL_OUT_MESAGE OUT VARCHAR,
    GLOBL_OUT_JSON OUT CLOB
) AS
    target_country  VARCHAR2(200);
    local_out_json CLOB;
    local_out_mesage VARCHAR2(200);
BEGIN
    target_country := GET_COUNTRY_ID_INTERSECTED_BY_POINT(pLongitude, pLatitude, selectedSrid);
    CASE 
        WHEN target_country = 'LOCALADMIN_CAT_ETRS89' THEN
            CASE
                WHEN CHECK_INTERSECTION_WITH_CAT(pLongitude, pLatitude, selectedSrid) = 1 AND CHECK_INTERSECTION_WITH_NEIGHBOURHOOD_BCN(pLongitude, pLatitude, selectedSrid) = 1 THEN
                    ADMINDIVISION_NEIGHBOURHOOD_BCN(pLongitude, pLatitude, selectedSrid, local_out_mesage, local_out_json);
                WHEN CHECK_INTERSECTION_WITH_CAT(pLongitude, pLatitude, selectedSrid) = 1 AND CHECK_INTERSECTION_WITH_NEIGHBOURHOOD_BCN(pLongitude, pLatitude, selectedSrid) = 0 THEN
                    ADMINDIVISION_CAT(pLongitude, pLatitude, selectedSrid, local_out_mesage, local_out_json);
                ELSE
                    --en este caso no hay procedimiento que rellene ambas variables por lo que se rellenan aqui
                    local_out_mesage := 'POINT THAT WAS PASSED IS IN A GEOMETRY TOPOLOGY GAP';
                    local_out_json := JSON_OBJECT();
            END CASE;
        WHEN target_country = 'LOCALADMIN_AND_ETRS89' THEN
            ADMINDIVISION_AND(pLongitude, pLatitude, selectedSrid, local_out_mesage, local_out_json);
        WHEN target_country = 'LOCALADMIN_FRA_ETRS89' THEN
            ADMINDIVISION_FRA(pLongitude, pLatitude, selectedSrid, local_out_mesage, local_out_json);
        WHEN target_country = 'LOCALADMIN_ESP_ETRS89' THEN
            ADMINDIVISION_ESP(pLongitude, pLatitude, selectedSrid, local_out_mesage, local_out_json);
        WHEN target_country = 'AGUA' THEN
            --en este caso no hay procedimiento que rellene ambas variables por lo que se rellenan aqui
            local_out_mesage := 'POINT THAT WAS PASSED DOES NOT INTERSECT EMERGED LAND OR THE POINT IS IN A GEOMETRY TOPOLOGY GAP';
            local_out_json := JSON_OBJECT();
        ELSE
            --en este caso no hay procedimiento que rellene ambas variables por lo que se rellenan aqui
            local_out_mesage := 'NOT CONTROLLED CASE AT THE ADMINDIVISION_INTERSECTION PROCEDURE';
            local_out_json := JSON_OBJECT();
    END CASE;

    GLOBL_OUT_JSON := local_out_json;
    GLOBAL_OUT_MESAGE := local_out_mesage;

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('The occured exception in ADMINDIVISION_INTERSECTION is -: ' || SQLERRM || SQLCODE);
            GLOBL_OUT_JSON := 'An error occurred: ' || SQLERRM;
            GLOBAL_OUT_MESAGE := 'ADMINDIVISION_INTERSECTION FAILURE';
END;