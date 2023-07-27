import { Router } from 'express'
const router = Router();

import { getCoordSystems, getInitialCoords, getTransformedCoords, insertInitialCoords, intersectAbs, transformCoords, intersectAdminCapas } from '../controllers/controllers.index';

router.get('/coordsystems', getCoordSystems);
router.get('/initials', getInitialCoords);
router.get('/transformed', getTransformedCoords);
router.post('/sendinitials', insertInitialCoords);
router.post('/transform', transformCoords);
router.post('/intersectabs', intersectAbs);
router.post('/intersectcapas', intersectAdminCapas);
   

export default router;