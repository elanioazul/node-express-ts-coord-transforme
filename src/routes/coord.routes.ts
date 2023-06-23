import { Router } from 'express'
const router = Router();

import { getInitialCoords, insertInitialCoords } from '../controllers/controllers.index';

router.get('/initials', getInitialCoords);
router.post('/sendinitials', insertInitialCoords);
   

export default router;