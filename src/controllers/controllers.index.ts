import { Request, Response } from 'express';
import miPool from '../database/pool';

export const getInitialCoord = async  (req: Request, res: Response): Promise<Response> => {
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