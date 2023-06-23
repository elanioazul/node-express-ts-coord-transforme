import { Application} from 'express';
import express from 'express';
import cors from 'cors';

import coordRoutes from './routes/coord.routes';


const app: Application = express();
app.use(cors());

// middlewares
app.use(express.json());
app.use(express.urlencoded({extended: false}));

// Routes
app.use('/api', coordRoutes);

app.listen(4000);
console.log('Server listening on port 4000');


