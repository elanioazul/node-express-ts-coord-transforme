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
            Select * from GIS.coordinates_initial
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
    console.log('request es ', req);
    
    const { lon, lat } = req.body;
    const conn = (await miPool).getConnection();
    let result = (await conn).execute(
        `INSERT INTO COORDINATES_INITIAL VALUES (:LON, :LAt)`,
        { LON : {val: `${lon}` }, LAT : {val: `${lat}`} }
    );
    console.log("Rows inserted: " + (await result).rowsAffected);  

    res.json({
        message: 'Initials coord added successfully',
        body: {
            user: { lon, lat }
        }
    })
};