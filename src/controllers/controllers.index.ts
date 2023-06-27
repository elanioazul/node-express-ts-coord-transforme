import { Request, Response } from 'express';
import miPool from '../database/pool';

interface ICoordinates {
    lon: number,
    lat: number,
}

export const getInitialCoords = async  (req: Request, res: Response): Promise<Response> => {
    try {
        const conn = (await miPool).getConnection();
        const result = (await conn).execute(
            `
            Select * from SEM_CHR_GIS.TEMP_COORDINATES_INITIAL
            `
        )
        console.log('number of records in Initial coord table', (await result).rows?.length);
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
            Select * from SEM_CHR_GIS.TEMP_COORDINATES_SYSTEMS
            `
        )
        console.log('number of records in CoodSystems table ', (await result).rows?.length);
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
            Select * from SEM_CHR_GIS.TEMP_COORDINATES_TRANSFORMED
            `
        )
        console.log('number of records in Transformed coord table', (await result).rows?.length);
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
            `INSERT INTO TEMP_COORDINATES_INITIAL VALUES (:ID, :LONGITUDE, :LATITUDE, :SRID)`,
            { 
                ID: { val: null},
                LONGITUDE : {val: lon}, 
                LATITUDE : {val: lat}, 
                SRID: {val: '4258'}
            },
            { autoCommit: true }
        );
        console.log("Rows inserted: " + (await result).rowsAffected);  
    
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
        let conn = (await miPool).getConnection();
        (await conn).execute(
            `
            create or replace PROCEDURE TransformPointCoodinatesAndStore(
                pLongitude IN NUMBER,
                pLatitude IN NUMBER,
                selectedSrid IN NUMBER,
                OUT_MESSAGE OUT VARCHAR
            ) AS
                vTransformedGeometry SDO_GEOMETRY;
                vJsonRepresentation VARCHAR2(4000);
                vOriginalCoordinatesId NUMBER;
            BEGIN
                -- Create the point geometry with 25831 as target srid
                vTransformedGeometry := SDO_CS.TRANSFORM(
                    SDO_GEOMETRY(2001, selectedSrid, SDO_POINT_TYPE(pLongitude, pLatitude, NULL), NULL, NULL),
                    25831
                );
            
                -- Convert the transformed geometry to JSON
                vJsonRepresentation := SDO_Util.TO_JSON(vTransformedGeometry);
                
                -- Store the initial coordinates and the srid selected by the user in the table and get the generated primary key
                INSERT INTO TEMP_COORDINATES_INITIAL (longitude, latitude, srid)
                VALUES (pLongitude, pLatitude, selectedSrid)
                RETURNING id INTO vOriginalCoordinatesId;

                DBMS_OUTPUT.PUT_LINE('This transformation corresponde to the id ' || vOriginalCoordinatesId || ' of TEMP_COORDINATES_INITIAL table');

                 -- Store the transformed coordinates, referencing the foreign keying also
                INSERT INTO TEMP_COORDINATES_TRANSFORMED (id, initial_coordinates_id, longitude, latitude, srid, transformed_geometry)
                VALUES (TEMP_COORDINATES_TRANSFORMED_SEQ.NEXTVAL,vOriginalCoordinatesId, vTransformedGeometry.SDO_POINT.X, vTransformedGeometry.SDO_POINT.Y, vTransformedGeometry.SDO_SRID, vTransformedGeometry);
            
                -- Output the JSON representation
                DBMS_OUTPUT.PUT_LINE(vJsonRepresentation);
            
                OUT_MESSAGE := 'SUCCESS';
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('The occured exception is -: ' || SQLERRM || SQLCODE);
                    OUT_MESSAGE := 'FAILURE';
            END;
            `
        );
        let result = (await conn).execute(
            `BEGIN
                TransformPointCoodinatesAndStore(:lon, :lat, :selectedsrid);
            END;`,
            { 
                lon : {val: parseInt(lon, 10)}, 
                lat : {val: parseInt(lat, 10)}, 
                selectedsrid: {val: parseInt(epsgSelected, 10)}
            },
            { autoCommit: true }
        );
        console.log("procedure output :", (await result).outBinds);
    
        res.json({
            message: 'Initials coord transformed successfully',
            body: {
                coords: { lon, lat }
            }
        })
    } catch (error) {
        console.error('Error inserting data:', error);
    } 

};