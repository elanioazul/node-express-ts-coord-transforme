import { Request, Response } from 'express';
import miPool from '../database/pool';
import { log } from 'console';

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
        console.log('number of records in Initail coord table', (await result).rows?.length);
        (await conn).close();
        return res.status(200).json((await result).rows);

    } catch (error) {
        console.log(error);
        return res.status(500).json('Internal Server error getting InitialCoords');
    }
}

export const insertInitialCoords = async (req: Request, res: Response) => {
    try {
        const { pairOfCoords } = req.body;
        
        const lon =  pairOfCoords.split(' ')[0];
        const lat =  pairOfCoords.split(' ')[1];
        let conn = (await miPool).getConnection();
        let result = (await conn).execute(
            `INSERT INTO TEMP_COORDINATES_INITIAL VALUES (:ID, :LON, :LAT, :EPSG_CODE, :EPSG_DESC)`,
            { 
                ID: { val: null},
                LON : {val: lon}, 
                LAT : {val: lat}, 
                EPSG_CODE: {val: 'EPSG:23031'}, 
                EPSG_DESC: {val: 'ED50 / UTM zone 31N'}
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