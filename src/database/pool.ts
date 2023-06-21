import OracleDB from 'oracledb';
import dotenv from 'dotenv';
import { env } from 'process';

dotenv.config();

const miPool = OracleDB.createPool({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWD,
    connectString: process.env.DB_DOMAIN + '/' + process.env.DB_SID,
    poolAlias: 'default-pool',
    poolMax: 20,
    poolMin: 20,
    poolIncrement:0
});

export default miPool;