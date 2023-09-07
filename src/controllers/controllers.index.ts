import { Request, Response } from 'express';
import miPool from '../database/pool';
import oracledb from 'oracledb';

export const getInitialCoords = async  (req: Request, res: Response): Promise<Response> => {
    try {
        const conn = (await miPool).getConnection();
        const result = (await conn).execute(
            `
            Select * from SEM_CHR_GIS.COORDINATES_INITIAL
            `
        );
        //console.log('number of records in Initial coord table', (await result).rows?.length);
        (await conn).close();
        return res.status(200).json((await result).rows);

    } catch (error) {
        console.log(error);
        return res.status(500).json('Internal Server error getting InitialCoords');
    }
}
export const getCoordSystems = async  (req: Request, res: Response): Promise<Response> => {
    try {
        const conn = (await miPool).getConnection();
        const result = (await conn).execute(
            `
            Select * from SEM_CHR_GIS.COORDINATES_SYSTEMS
            `
        );
        //console.log('number of records in CoodSystems table ', (await result).rows?.length);
        (await conn).close();
        return res.status(200).json((await result).rows);

    } catch (error) {
        console.log(error);
        return res.status(500).json('Internal Server error getting CoordSystems table');
    }
}
export const getTransformedCoords = async  (req: Request, res: Response): Promise<Response> => {
    try {
        const conn = (await miPool).getConnection();
        const result = (await conn).execute(
            `
            Select * from SEM_CHR_GIS.COORDINATES_TRANSFORMED
            `
        );
        //console.log('number of records in Transformed coord table', (await result).rows?.length);
        (await conn).close();
        return res.status(200).json((await result).rows);

    } catch (error) {
        console.log(error);
        return res.status(500).json('Internal Server error getting TransformedCoords');
    }
}

export const insertInitialCoords = async (req: Request, res: Response) => {
    try {
        const { coords } = req.body;
        
        const lon =  coords.split(' ')[0];
        const lat =  coords.split(' ')[1];
        let conn = (await miPool).getConnection();
        let result = (await conn).execute(
            `INSERT INTO COORDINATES_INITIAL VALUES (:ID, :LONGITUDE, :LATITUDE, :SRID)`,
            { 
                ID: { val: null},
                LONGITUDE : {val: lon}, 
                LATITUDE : {val: lat}, 
                SRID: {val: '4258'}
            },
            { autoCommit: true }
        );
    
        res.json({
            message: 'Initials coord added successfully',
            body: {
                coords: { lon, lat }
            }
        })
    } catch (error) {
        console.error('Error inserting data:', error);
    } 

};
export const transformCoords = async (req: Request, res: Response) => {
    try {
        const { coords, epsgSelected } = req.body;

        let conn = (await miPool).getConnection();
        //escribo en bd el procedimiento TransformPointCoodinatesAndStore
        // (await conn).execute(
        //     `
        //     create or replace PROCEDURE TransformPointCoodinatesAndStore(
        //         pLongitude IN NUMBER,
        //         pLatitude IN NUMBER,
        //         selectedSrid IN NUMBER,
        //         dmsToddNeeded IN VARCHAR,
        //         targetSrid IN NUMBER,
        //         OUT_MESSAGE OUT VARCHAR,
        //         OUT_JSON OUT CLOB
        //     ) AS
        //         vInitialGeometry SDO_GEOMETRY;
        //         vTransformedGeometry SDO_GEOMETRY;
        //         vInitialCoordinatesId NUMBER;
        //         vOriginCoordSystemId NUMBER;
        //         vTargetCoordSystemId NUMBER;
        //     BEGIN
        //         -- Get the origin coordinate system (pk)
        //         vOriginCoordSystemId := get_origin_coord_system_id(selectedSrid, dmsToddneeded);
            
        //         -- Get the target coordinate system (pk). 
        //         -- Note it uses the default parameter in the function (25831 is_dms = 0 only option)
        //         vTargetCoordSystemId := get_origin_coord_system_id(targetSrid);
            
        //         -- Create the point geometry with the srid sent by user
        //         vInitialGeometry := SDO_GEOMETRY(2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL);
                
        //         -- Create the point geometry with targetSrid as target srid (commonly 25831 (Chronos system)
        //         vTransformedGeometry := SDO_CS.TRANSFORM(
        //             SDO_GEOMETRY(2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        //             targetSrid
        //         );
            
        //         -- Store the initial coordinates and the srid selected by the user and get the generated primary key
        //         INSERT INTO COORDINATES_INITIAL
        //         VALUES (DEFAULT, pLongitude, pLatitude, vOriginCoordSystemId, vInitialGeometry)
        //         RETURNING id INTO vInitialCoordinatesId;
            
        //         -- Store the transformed coordinates, referencing the foreign keys also
        //         INSERT INTO COORDINATES_TRANSFORMED
        //         VALUES (DEFAULT, vInitialCoordinatesId, vTransformedGeometry.SDO_POINT.X, vTransformedGeometry.SDO_POINT.Y, vTargetCoordSystemId, vTransformedGeometry);
            
        //         -- Set the OUT parameters
        //         OUT_MESSAGE := 'COORDINATES TRANSFORMATION SUCCESS';
        //         SELECT JSON_OBJECT(
        //                 'initial_point' VALUE json_object('x' VALUE pLongitude, 'y' VALUE pLatitude, 'srid' VALUE selectedSrid),
        //                 'transformed_point' VALUE json_object('x' VALUE vTransformedGeometry.SDO_POINT.X, 'y' VALUE vTransformedGeometry.SDO_POINT.Y, 'srid' VALUE vTransformedGeometry.SDO_SRID, 'geojson' VALUE SDO_Util.TO_GEOJSON(vTransformedGeometry))
        //                 format json
        //                 returning clob
        //         ) 
        //         INTO OUT_JSON
        //         FROM dual;
        //         DBMS_OUTPUT.PUT_LINE(OUT_JSON);
        //     EXCEPTION
        //         WHEN OTHERS THEN
        //             DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
        //             OUT_MESSAGE := 'COORDINATES TRANSFORMATION FAILURE';
        //             OUT_JSON:= JSON_OBJECT();
        //     END;
        //     `
        // );
        //escribo en bd la funcion FUNCTION DMS_TO_DD
        // (await conn).execute(
        //     `
        //     CREATE OR REPLACE FUNCTION DMS_TO_DD (
        //         p_degrees  NUMBER,
        //         p_minutes  NUMBER,
        //         p_seconds  NUMBER,
        //         p_direction VARCHAR2
        //       ) RETURN NUMBER IS
        //         dd NUMBER;
        //       BEGIN
        //         -- Convert degrees, minutes, and seconds to decimal degrees
        //         dd := p_degrees + (p_minutes / 60) + (p_seconds / 3600);
              
        //         -- Adjust the sign based on the direction (E, W, N, S)
        //         IF p_direction = 'W' OR p_direction = 'S' THEN
        //           dd := -dd;
        //         END IF;

        //         RETURN dd;

        //       END DMS_TO_DD;
        //     `
        // );
        //escribo en bd la función get_origin_coord_system_id
        // (await conn).execute(
        //     `
        //     CREATE OR REPLACE FUNCTION get_origin_coord_system_id(
        //         srid NUMBER,
        //         dmsToddneeded VARCHAR DEFAULT 'N'
        //     ) RETURN NUMBER AS
        //         vCoordSystemId NUMBER;
        //     BEGIN
        //         SELECT ID INTO vCoordSystemId
        //         FROM COORDINATES_SYSTEMS
        //         WHERE EPSG = srid AND is_dms = dmsToddneeded;
            
        //         RETURN vCoordSystemId;
        //     END;
        //     `
        // );
        let result: any;
        //caso noDms
        if (typeof coords === 'string') {
            const lon =  coords.split(' ')[0];
            const lat =  coords.split(' ')[1];
            const lonFloat =  parseFloat(lon);
            const latFloat =  parseFloat(lat);
            result = (await conn).execute(
                `
                BEGIN
                    TransformPointCoodinatesAndStore(:pLongitude, :pLatitude, :selectedSrid, :dmsToddNeeded, :targetSrid, :OUT_MESSAGE, :OUT_JSON);
                END;`,
                { 
                    pLongitude : { val: lonFloat }, 
                    pLatitude : { val: latFloat }, 
                    selectedSrid: { val: epsgSelected },
                    dmsToddNeeded: { val: 'N' },
                    targetSrid: { val: '4326'},
                    OUT_MESSAGE: { dir: oracledb.BIND_OUT, type: oracledb.STRING },
                    OUT_JSON: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 5000  }
                },
                { autoCommit: true }
            );
        }
        //caso Dms
        if (Array.isArray(coords)) {
            const long = await transformDmsIntoDD(coords[0][0], coords[0][1], coords[0][2], coords[0][3]);
            const lat = await transformDmsIntoDD(coords[1][0], coords[1][1], coords[1][2], coords[1][3]);
            result = (await conn).execute(
                `
                BEGIN
                    TransformPointCoodinatesAndStore(:pLongitude, :pLatitude, :selectedSrid, :dmsToddNeeded, :targetSrid, :OUT_MESSAGE, :OUT_JSON);
                END;`,
                { 
                    pLongitude : { val: long }, 
                    pLatitude : { val: lat }, 
                    selectedSrid: { val: epsgSelected },
                    dmsToddNeeded: { val: 'Y' },
                    targetSrid: { val: '4326'},
                    OUT_MESSAGE: { dir: oracledb.BIND_OUT, type: oracledb.STRING },
                    OUT_JSON: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 5000  }
                },
                { autoCommit: true }
            );
        }

        console.log("procedure outputs :", (await result).outBinds);

        let proccedureStatus = (await result as any).outBinds.OUT_MESSAGE;
        let procedureOutJson = (await result as any).outBinds.OUT_JSON;
    
        res.json({
            message: proccedureStatus,
            body: procedureOutJson
        })
    } catch (error) {
        console.error('Error inserting data:', error);
    } 

};

export const intersectAdminCapas = async (req: Request, res: Response) => {
    try {
        const { epsg, lon, lat } = req.body;
        let conn = (await miPool).getConnection();
    
        // (await conn).execute(
        //     `
        //     create or replace FUNCTION GET_COUNTRY_ID_INTERSECTED_BY_POINT(
        //         p_longitude NUMBER,
        //         p_latitude NUMBER,
        //         p_srid NUMBER
        //     ) RETURN VARCHAR2 AS
        //         v_result VARCHAR2(200);
        //     BEGIN
        //         SELECT TARGET_TABLE
        //         INTO v_result
        //         FROM SEM_CHR_GIS.COUNTRY_ETRS89
        //         WHERE SDO_ANYINTERACT(
        //             SDO_GEOMETRY(2001, p_srid, SDO_POINT_TYPE(p_longitude, p_latitude, NULL), NULL, NULL),
        //             geom
        //         ) = 'TRUE' ORDER BY PRIORITY ASC FETCH NEXT 1 ROWS ONLY;
            
        //         RETURN v_result;
            
        //         EXCEPTION
        //             WHEN NO_DATA_FOUND THEN
        //                 DBMS_OUTPUT.PUT_LINE('It does not intersect any country, probably derived from a scale/generalization topology gap or because water has been intersected');
        //                 v_result := 'AGUA';
        //                 RETURN v_result;
        //     END;
        //     `
        // );
        // (await conn).execute(
        //     `
        //     create or replace PROCEDURE ADMINDIVISION_ESP (
        //         pLongitude IN NUMBER,
        //         pLatitude IN NUMBER,
        //         selectedSrid IN NUMBER,
        //         OUT_MESSAGE OUT VARCHAR,
        //         OUT_JSON OUT CLOB
        //     ) AS 
        //     BEGIN
        //         OUT_MESSAGE := 'ADMINDIVISION_ESP SUCCESS';
        //         SELECT json_object(
        //             'country' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.country,
        //             'countryId' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.COUNTRY_ID,
        //             'countryCode' VALUE NULL,
        //             'region' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.REGION,
        //             'regionId' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.REGION_ID,
        //             'macrocounty' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.MACROCOUNTY,
        //             'macrocountyId' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.MACROCOUNTY,
        //             'localadmin' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.LOCALADMIN,
        //             'localadminId' VALUE SEM_CHR_GIS.localadmin_esp_etrs89.LOCALADMIN_ID,
        //             'locality' VALUE NULL,
        //             'localityId' VALUE NUll,
        //             'borough' VALUE NULL,
        //             'boroughId' VALUE NULL,
        //             'boroughCode' VALUE NULL,
        //             'neighbourhood' VALUE NULL,
        //             'neighbourhoodId' VALUE NULL,
        //             'neighbourhoodCode' VALUE NULL,
        //             'sm1' VALUE NULL,
        //             'sm1Id' VALUE NULL,
        //             'sm2' VALUE NULL,
        //             'sm2Id' VALUE NULL
        //             format json
        //             returning clob
        //         ) AS JSON 
        //         INTO OUT_JSON
        //         FROM SEM_CHR_GIS.localadmin_esp_etrs89
        //         where SDO_anyinteract(
        //             SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        //             geom) = 'TRUE' FETCH NEXT 1 ROWS ONLY;
        //         DBMS_OUTPUT.PUT_LINE(OUT_JSON);
        //         EXCEPTION
        //             WHEN OTHERS THEN
        //                 DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
        //                 OUT_MESSAGE := 'ADMINDIVISION_ESP FAILURE';
        //                 OUT_JSON:= JSON_OBJECT();
        //     END ADMINDIVISION_ESP;
        //     `
        // );
        // (await conn).execute(
        //     `
        //     create or replace PROCEDURE ADMINDIVISION_CAT (
        //         pLongitude IN NUMBER,
        //         pLatitude IN NUMBER,
        //         selectedSrid IN NUMBER,
        //         OUT_MESSAGE OUT VARCHAR,
        //         OUT_JSON OUT CLOB
        //     ) AS 
        //     BEGIN
        //         OUT_MESSAGE := 'ADMINDIVISION_CAT SUCCESS';
        //         SELECT json_object(
        //             'country' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.country,
        //             'countryId' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.COUNTRY_ID,
        //             'countryCode' VALUE NULL,
        //             'region' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.REGION,
        //             'regionId' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.REGION_ID,
        //             'macrocounty' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.MACROCOUNTY,
        //             'macrocountyId' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.MACROCOUNTY_ID,
        //             'localadmin' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.LOCALADMIN,
        //             'localadminId' VALUE SEM_CHR_GIS.localadmin_cat_etrs89.LOCALADMIN_ID,
        //             'locality' VALUE NULL,
        //             'localityId' VALUE NUll,
        //             'borough' VALUE NULL,
        //             'boroughId' VALUE NULL,
        //             'boroughCode' VALUE NULL,
        //             'neighbourhood' VALUE NULL,
        //             'neighbourhoodId' VALUE NULL,
        //             'neighbourhoodCode' VALUE NULL,
        //             'sm1' VALUE NULL,
        //             'sm1Id' VALUE NULL,
        //             'sm2' VALUE NULL,
        //             'sm2Id' VALUE NULL
        //             format json
        //             returning clob
        //         ) AS JSON 
        //         INTO OUT_JSON
        //         FROM SEM_CHR_GIS.localadmin_cat_etrs89
        //         where SDO_anyinteract(
        //             SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        //             geom) = 'TRUE' FETCH NEXT 1 ROWS ONLY;
        //         DBMS_OUTPUT.PUT_LINE(OUT_JSON);
        //         EXCEPTION
        //             WHEN OTHERS THEN
        //                 DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
        //                 OUT_MESSAGE := 'ADMINDIVISION_CAT FAILURE';
        //                 OUT_JSON:= JSON_OBJECT();
        //     END ADMINDIVISION_CAT;
        //     `
        // );
        // (await conn).execute(
        //     `
        //     create or replace PROCEDURE ADMINDIVISION_FRA (
        //         pLongitude IN NUMBER,
        //         pLatitude IN NUMBER,
        //         selectedSrid IN NUMBER,
        //         OUT_MESSAGE OUT VARCHAR,
        //         OUT_JSON OUT CLOB
        //     ) AS 
        //     BEGIN
        //         OUT_MESSAGE := 'ADMINDIVISION_FRA SUCCESS';
        //         SELECT json_object(
        //             'country' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.country,
        //             'countryId' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.COUNTRY_ID,
        //             'countryCode' VALUE NULL,
        //             'region' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.REGION,
        //             'regionId' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.REGION_ID,
        //             'macrocounty' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.MACROCOUNTY,
        //             'macrocountyId' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.MACROCOUNTY_ID,
        //             'localadmin' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.LOCALADMIN,
        //             'localadminId' VALUE SEM_CHR_GIS.localadmin_fra_etrs89.LOCALADMIN_ID,
        //             'locality' VALUE NULL,
        //             'localityId' VALUE NUll,
        //             'borough' VALUE NULL,
        //             'boroughId' VALUE NULL,
        //             'boroughCode' VALUE NULL,
        //             'neighbourhood' VALUE NULL,
        //             'neighbourhoodId' VALUE NULL,
        //             'neighbourhoodCode' VALUE NULL,
        //             'sm1' VALUE NULL,
        //             'sm1Id' VALUE NULL,
        //             'sm2' VALUE NULL,
        //             'sm2Id' VALUE NULL
        //             format json
        //             returning clob
        //         ) AS JSON 
        //         INTO OUT_JSON
        //         FROM SEM_CHR_GIS.localadmin_fra_etrs89
        //         where SDO_anyinteract(
        //             SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        //             geom) = 'TRUE' FETCH NEXT 1 ROWS ONLY;
        //         DBMS_OUTPUT.PUT_LINE(OUT_JSON);
        //         EXCEPTION
        //             WHEN OTHERS THEN
        //                 DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
        //                 OUT_MESSAGE := 'ADMINDIVISION_FRA FAILURE';
        //                 OUT_JSON:= JSON_OBJECT();
        //     END ADMINDIVISION_FRA;
        //     `
        // );
        // (await conn).execute(
        //     `
        //     create or replace PROCEDURE ADMINDIVISION_AND (
        //         pLongitude IN NUMBER,
        //         pLatitude IN NUMBER,
        //         selectedSrid IN NUMBER,
        //         OUT_MESSAGE OUT VARCHAR,
        //         OUT_JSON OUT CLOB
        //     ) AS 
        //     BEGIN
        //         OUT_MESSAGE := 'ADMINDIVISION_AND SUCCESS';
        //         SELECT json_object(
        //             'country' VALUE SEM_CHR_GIS.localadmin_and_etrs89.country,
        //             'countryId' VALUE SEM_CHR_GIS.localadmin_and_etrs89.COUNTRY_ID,
        //             'countryCode' VALUE NULL,
        //             'region' VALUE NULL,
        //             'regionId' VALUE NULL,
        //             'macrocounty' VALUE NULL,
        //             'macrocountyId' VALUE NULL,
        //             'localadmin' VALUE SEM_CHR_GIS.localadmin_and_etrs89.LOCALADMIN,
        //             'localadminId' VALUE SEM_CHR_GIS.localadmin_and_etrs89.LOCALADMIN_ID,
        //             'locality' VALUE NULL,
        //             'localityId' VALUE NUll,
        //             'borough' VALUE NULL,
        //             'boroughId' VALUE NULL,
        //             'boroughCode' VALUE NULL,
        //             'neighbourhood' VALUE NULL,
        //             'neighbourhoodId' VALUE NULL,
        //             'neighbourhoodCode' VALUE NULL,
        //             'sm1' VALUE NULL,
        //             'sm1Id' VALUE NULL,
        //             'sm2' VALUE NULL,
        //             'sm2Id' VALUE NULL
        //             format json
        //             returning clob
        //         ) AS JSON 
        //         INTO OUT_JSON
        //         FROM SEM_CHR_GIS.localadmin_and_etrs89
        //         where SDO_anyinteract(
        //             SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        //             geom) = 'TRUE' FETCH NEXT 1 ROWS ONLY;
        //         DBMS_OUTPUT.PUT_LINE(OUT_JSON);
        //         EXCEPTION
        //             WHEN OTHERS THEN
        //                 DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
        //                 OUT_MESSAGE := 'ADMINDIVISION_AND FAILURE';
        //                 OUT_JSON:= JSON_OBJECT();
        //     END ADMINDIVISION_AND;
        //     `
        // );
        // (await conn).execute(
        //     `
        //     create or replace PROCEDURE ADMINDIVISION_NEIGHBOURHOOD_BCN (
        //         pLongitude IN NUMBER,
        //         pLatitude IN NUMBER,
        //         selectedSrid IN NUMBER,
        //         OUT_MESSAGE OUT VARCHAR,
        //         OUT_JSON OUT CLOB
        //     ) AS 
        //     BEGIN
        //         OUT_MESSAGE := 'ADMINDIVISION_NEIGHBOURHOOD_BCN SUCCESS';
        //         SELECT json_object(
        //             'country' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.country,
        //             'countryId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.COUNTRY_ID,
        //             'countryCode' VALUE NULL,
        //             'region' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.REGION,
        //             'regionId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.REGION_ID,
        //             'macrocounty' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.MACROCOUNTY,
        //             'macrocountyId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.MACROCOUNTY_ID,
        //             'localadmin' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.LOCALADMIN,
        //             'localadminId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.LOCALADMIN_ID,
        //             'locality' VALUE NULL,
        //             'localityId' VALUE NUll,
        //             'borough' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.BOROUGH,
        //             'boroughId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.BOROUGH_ID,
        //             'boroughCode' VALUE NULL,
        //             'neighbourhood' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.NEIGHBOURHOOD,
        //             'neighbourhoodId' VALUE SEM_CHR_GIS.neighbourhood_bcn_etrs89.NEIGHBOURHOOD_ID,
        //             'neighbourhoodCode' VALUE NULL,
        //             'sm1' VALUE NULL,
        //             'sm1Id' VALUE NULL,
        //             'sm2' VALUE NULL,
        //             'sm2Id' VALUE NULL
        //             format json
        //             returning clob
        //         ) AS JSON 
        //         INTO OUT_JSON
        //         FROM SEM_CHR_GIS.neighbourhood_bcn_etrs89
        //         where SDO_anyinteract(
        //             SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        //             geom) = 'TRUE' FETCH NEXT 1 ROWS ONLY;
        //         DBMS_OUTPUT.PUT_LINE(OUT_JSON);
        //         EXCEPTION
        //             WHEN OTHERS THEN
        //                 DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
        //                 OUT_MESSAGE := 'ADMINDIVISION_NEIGHBOURHOOD_BCN FAILURE';
        //                 OUT_JSON:= JSON_OBJECT();
        //     END ADMINDIVISION_NEIGHBOURHOOD_BCN;
        //     `
        // );
        // (await conn).execute(
        //     `
        //     create or replace PROCEDURE ADMINDIVISION_INTERSECTION (
        //         pLongitude IN NUMBER,
        //         pLatitude IN NUMBER,
        //         selectedSrid IN NUMBER,
        //         GLOBAL_OUT_MESAGE OUT VARCHAR,
        //         GLOBL_OUT_JSON OUT CLOB
        //     ) AS
        //         target_country  VARCHAR2(200);
        //         local_out_json CLOB;
        //         local_out_mesage VARCHAR2(200);
        //     BEGIN
        //         target_country := GET_COUNTRY_ID_INTERSECTED_BY_POINT(pLongitude, pLatitude, selectedSrid);
        //         CASE 
        //             WHEN target_country = 'NEIGHBOURHOOD_BCN_ETRS89' THEN
        //                 ADMINDIVISION_NEIGHBOURHOOD_BCN(pLongitude, pLatitude, selectedSrid, local_out_mesage, local_out_json);
        //             WHEN target_country = 'LOCALADMIN_CAT_ETRS89' THEN
        //                 ADMINDIVISION_CAT(pLongitude, pLatitude, selectedSrid, local_out_mesage, local_out_json);
        //             WHEN target_country = 'LOCALADMIN_AND_ETRS89' THEN
        //                 ADMINDIVISION_AND(pLongitude, pLatitude, selectedSrid, local_out_mesage, local_out_json);
        //             WHEN target_country = 'LOCALADMIN_FRA_ETRS89' THEN
        //                 ADMINDIVISION_FRA(pLongitude, pLatitude, selectedSrid, local_out_mesage, local_out_json);
        //             WHEN target_country = 'LOCALADMIN_ESP_ETRS89' THEN
        //                 ADMINDIVISION_ESP(pLongitude, pLatitude, selectedSrid, local_out_mesage, local_out_json);
        //             WHEN target_country = 'AGUA' THEN
        //                 --en este caso no hay procedimiento que rellene ambas variables por lo que se rellenan aqui
        //                 local_out_mesage := 'POINT DOES NOT INTERSECT EMERGED LAND OR THE POINT IS IN A SCALE/GENERALIZATION TOPOLOGY GAP BETWEEN DATA SOURCES';
        //                 local_out_json := JSON_OBJECT();
        //             ELSE
        //                 --en este caso no hay procedimiento que rellene ambas variables por lo que se rellenan aqui
        //                 local_out_mesage := 'NOT CONTROLLED CASE AT THE ADMINDIVISION_INTERSECTION PROCEDURE';
        //                 local_out_json := JSON_OBJECT();
        //         END CASE;
            
        //         GLOBL_OUT_JSON := local_out_json;
        //         GLOBAL_OUT_MESAGE := local_out_mesage;
            
        //         EXCEPTION
        //             WHEN OTHERS THEN
        //                 DBMS_OUTPUT.PUT_LINE('The occured exception in ADMINDIVISION_INTERSECTION is -: ' || SQLERRM || SQLCODE);
        //                 GLOBL_OUT_JSON := 'An error occurred: ' || SQLERRM;
        //                 GLOBAL_OUT_MESAGE := 'ADMINDIVISION_INTERSECTION FAILURE';
        //     END;
        //     `
        // )
    
        let result: any;

        const lonFloat =  parseFloat(lon);
        const latFloat =  parseFloat(lat);
        result = (await conn).execute(
            `
            BEGIN
                ADMINDIVISION_INTERSECTION(:pLongitude, :pLatitude, :selectedSrid, :OUT_MESSAGE, :OUT_JSON);
            END;`,
            { 
                pLongitude : { val: lonFloat }, 
                pLatitude : { val: latFloat }, 
                selectedSrid: { val: epsg },
                OUT_MESSAGE: { dir: oracledb.BIND_OUT, type: oracledb.STRING },
                OUT_JSON: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 5000  }
            },
            { autoCommit: true }
        );

        console.log("procedure outputs :", (await result).outBinds);

        let proccedureStatus = (await result as any).outBinds.OUT_MESSAGE;
        let procedureOutJson = (await result as any).outBinds.OUT_JSON;
    
        res.json({
            message: proccedureStatus,
            body: procedureOutJson
        })
        
    } catch (error) {
        console.error('Error inserting data:', error);
    }
}

export const intersectAbs = async (req: Request, res: Response) => {
    try {
        const { epsg, lon, lat } = req.body;
        let conn = (await miPool).getConnection();
    
        //escribo en bd el procedimiento ABSINTERSECTEDBYPOINT
        // (await conn).execute(
        //     `
        //     create or replace PROCEDURE ABSINTERSECTEDBYPOINT (
        //         pLongitude IN NUMBER,
        //         pLatitude IN NUMBER,
        //         selectedSrid IN NUMBER,
        //         OUT_MESSAGE OUT VARCHAR,
        //         OUT_JSON OUT CLOB
        //     ) AS 
        //         isABSLayerIntersected NUMBER;
        //     BEGIN
        //         isABSLayerIntersected := CHECK_INTERSECTION_WITH_ABS(pLongitude, pLatitude, selectedSrid);
        //         IF isABSLayerIntersected > 0 THEN
        //             OUT_MESSAGE := 'ABS INTERSECTED BY POINT SUCCESS';
        //             SELECT JSON_ARRAYAGG(
        //                 json_object( KEY 'codiabs' VALUE CODIABS, KEY 'nomabs' VALUE NOMABS, KEY 'codiss' VALUE CODISS, KEY 'nomss' VALUE NOMSS, KEY 'codirs' VALUE CODIRS, KEY 'nomrs' VALUE NOMRS, KEY 'codiaga' VALUE CODIAGA, KEY 'nomaga' VALUE NOMAGA, KEY 'estat' VALUE ESTAT, KEY 'observacions' VALUE OBSER)
        //                 format json
        //                 returning clob
        //             ) AS JSON 
        //             INTO OUT_JSON
        //             FROM SEM_CHR_GIS.abs_2020_etrs89
        //             where SDO_anyinteract(
        //                 SDO_GEOMETRY( 2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
        //                 geom) = 'TRUE' FETCH NEXT 1 ROWS ONLY;
        //             DBMS_OUTPUT.PUT_LINE(OUT_JSON);
        //         ELSE
        //             DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
        //             OUT_MESSAGE := 'Coordinates passed do not intersect ABS layer';
        //             OUT_JSON:= JSON_OBJECT();
        //         END IF;
            
        //         EXCEPTION
        //             WHEN OTHERS THEN
        //                 DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
        //                 OUT_MESSAGE := 'ABS INTERSECTED BY POINT FAILURE';
        //                 OUT_JSON:= JSON_OBJECT();
        //     END ABSINTERSECTEDBYPOINT;
        //     `
        // );
        //escribo en bd la funcion que chequea interseccion con capa ABS
        // (await conn).execute(
        //     `
        //     CREATE OR REPLACE FUNCTION CHECK_INTERSECTION_WITH_ABS(
        //         p_longitude NUMBER,
        //         p_latitude NUMBER,
        //         p_srid NUMBER
        //     ) RETURN NUMBER AS
        //         v_result NUMBER;
        //     BEGIN
        //         SELECT COUNT(*)
        //         INTO v_result
        //         FROM SEM_CHR_GIS.abs_2020_etrs89
        //         WHERE SDO_ANYINTERACT(
        //             SDO_GEOMETRY(2001, p_srid, SDO_POINT_TYPE(p_longitude, p_latitude, NULL), NULL, NULL),
        //             geom
        //         ) = 'TRUE';
            
        //         IF v_result > 0 THEN
        //             RETURN 1;
        //         ELSE
        //             RETURN 0;
        //         END IF;
        //     END;
        //     `
        // )
    
        let result: any;

        const lonFloat =  parseFloat(lon);
        const latFloat =  parseFloat(lat);
        result = (await conn).execute(
            `
            BEGIN
                ABSINTERSECTEDBYPOINT(:pLongitude, :pLatitude, :selectedSrid, :OUT_MESSAGE, :OUT_JSON);
            END;`,
            { 
                pLongitude : { val: lonFloat }, 
                pLatitude : { val: latFloat }, 
                selectedSrid: { val: epsg },
                OUT_MESSAGE: { dir: oracledb.BIND_OUT, type: oracledb.STRING },
                OUT_JSON: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 5000  }
            },
            { autoCommit: true }
        );

        console.log("procedure outputs :", (await result).outBinds);

        let proccedureStatus = (await result as any).outBinds.OUT_MESSAGE;
        let procedureOutJson = (await result as any).outBinds.OUT_JSON;
    
        res.json({
            message: proccedureStatus,
            body: procedureOutJson
        })
        
    } catch (error) {
        console.error('Error inserting data:', error);
    }

}

async function transformDmsIntoDD (deg: string, min: string, sec: string, direc: string) {
    const degFloat =  parseFloat(deg);
    const minFloat =  parseFloat(min);
    const secFloat =  parseFloat(sec);
    let conn: any;
    try {
        conn = (await miPool).getConnection();
        const result = (await conn).execute(
            `
            BEGIN
                :outputParam := DMS_TO_DD(:p_degrees, :p_minutes, :p_seconds, :p_direction);
            END;
            `,
            { 
                p_degrees : { val: degFloat }, 
                p_minutes : { val: minFloat }, 
                p_seconds: { val: secFloat },
                p_direction: { val: direc},
                outputParam: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
            }
        );
        //(await conn).close();
        //(await conn).commit();
        return (await result).outBinds.outputParam;
    }  catch (err) {
        console.error('Error calling Oracle function:', err);
        throw err;
      } finally {
        if (conn) {
          try {
            (await conn).close();
          } catch (err) {
            console.error('Error closing database connection:', err);
          }
        }
      }

}