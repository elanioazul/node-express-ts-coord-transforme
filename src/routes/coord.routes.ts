import { Router } from 'express'
const router = Router();

import { getCoordSystems, getInitialCoords, getTransformedCoords, insertInitialCoords, transformCoords } from '../controllers/controllers.index';

router.get('/coordsystems', getCoordSystems);
router.get('/initials', getInitialCoords);
router.get('/transformed', getTransformedCoords);
router.post('/sendinitials', insertInitialCoords);
router.post('/transform', transformCoords);
   

export default router;