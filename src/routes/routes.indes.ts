import {Router} from 'express';
const router = Router();

import { getInitialCoords,, insertInitialCoords } from '../controllers/controllers.index';

router.get('/initials', getInitialCoords);
router.get('/sendinitials', insertInitialCoords);
// router.post('/users', createUser);
// router.put('/users/:id', updateUser)
// router.delete('/users/:id', deleteUser);

export default router;