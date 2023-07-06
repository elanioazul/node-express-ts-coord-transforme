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
        const { pairOfCoords } = req.body;
        
        const lon =  pairOfCoords.split(' ')[0];
        const lat =  pairOfCoords.split(' ')[1];
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
        //console.log("Rows inserted: " + (await result).rowsAffected);  
    
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
        const { pairOfCoords, epsgSelected } = req.body;
        
        const lon =  pairOfCoords.split(' ')[0];
        const lat =  pairOfCoords.split(' ')[1];
        const lonFloat =  parseFloat(lon);
        const latFloat =  parseFloat(lat);

        let conn = (await miPool).getConnection();
        (await conn).execute(
            `
            create or replace PROCEDURE TransformPointCoodinatesAndStore(
                pLongitude IN NUMBER,
                pLatitude IN NUMBER,
                selectedSrid IN NUMBER,
                OUT_MESSAGE OUT VARCHAR,
                OUT_JSON OUT CLOB
            ) AS
                vInitialGeometry SDO_GEOMETRY;
                vTransformedGeometry SDO_GEOMETRY;
                vInitialCoordinatesId NUMBER;
            BEGIN
                -- Create the point geometry with the srid sent by user
                vInitialGeometry := SDO_GEOMETRY(2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL);
                
                -- Create the point geometry with 25831 as target srid
                vTransformedGeometry := SDO_CS.TRANSFORM(
                    SDO_GEOMETRY(2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
                    25831
                );

                -- Store the initial coordinates and the srid selected by the user and get the generated primary key
                INSERT INTO COORDINATES_INITIAL
                VALUES (DEFAULT, pLongitude, pLatitude, selectedSrid, vInitialGeometry)
                RETURNING id INTO vInitialCoordinatesId;

                -- Store the transformed coordinates, referencing the foreign key also
                INSERT INTO COORDINATES_TRANSFORMED
                VALUES (DEFAULT, vInitialCoordinatesId, vTransformedGeometry.SDO_POINT.X, vTransformedGeometry.SDO_POINT.Y, vTransformedGeometry.SDO_SRID, vTransformedGeometry);

                -- Set the OUT parameters
                OUT_MESSAGE := 'COORDINATES TRANSFORMATION SUCCESS';
                SELECT JSON_OBJECT(
                        'initial_point' VALUE json_object('x' VALUE pLongitude, 'y' VALUE pLatitude, 'srid' VALUE selectedSrid),
                        'transformed_point' VALUE json_object('x' VALUE vTransformedGeometry.SDO_POINT.X, 'y' VALUE vTransformedGeometry.SDO_POINT.Y, 'srid' VALUE vTransformedGeometry.SDO_SRID, 'geojson' VALUE SDO_Util.TO_GEOJSON(vTransformedGeometry))
                        format json
                        returning clob
                ) 
                INTO OUT_JSON
                FROM dual;
                DBMS_OUTPUT.PUT_LINE(OUT_JSON);
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
                    OUT_MESSAGE := 'COORDINATES TRANSFORMATION FAILURE';
                    OUT_JSON:= JSON_OBJECT();
            END;
            `
        );
        let result = (await conn).execute(
            `
            BEGIN
                TransformPointCoodinatesAndStore(:pLongitude, :pLatitude, :selectedSrid, :OUT_MESSAGE, :OUT_JSON);
            END;`,
            { 
                pLongitude : { val: lonFloat }, 
                pLatitude : { val: latFloat }, 
                selectedSrid: { val: epsgSelected },
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

};