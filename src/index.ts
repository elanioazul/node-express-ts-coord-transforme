import { Application} from 'express';
import express from 'express';
import indexRoutes from './routes/routes.indes';

const app: Application = express();

// middlewares
app.use(express.json());
app.use(express.urlencoded({extended: false}));

// Routes
app.use(indexRoutes);

app.listen(4000);
console.log('Server listening on port 4000');


