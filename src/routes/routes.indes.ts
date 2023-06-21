import {Router} from 'express';
const router = Router();

import { getInitialCoord } from '../controllers/controllers.index';

router.get('/initial', getInitialCoord);
// router.get('/users/:id', getUserById);
// router.post('/users', createUser);
// router.put('/users/:id', updateUser)
// router.delete('/users/:id', deleteUser);

export default router;