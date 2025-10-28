const express = require('express');
const router = express.Router();
const { 
  createContract,
  getParentContracts,
  getContractById,
  updateContractStatus,
  assignDriver,
  getAvailableContracts,
  updateContract
} = require('../controllers/schoolController');
const { auth } = require('../middleware/auth');

// All routes are protected
router.use(auth);

// School contract routes
router.route('/contracts')
  .post(createContract)
  .get(getParentContracts);

router.route('/contracts/:id')
  .get(getContractById)
  .put(updateContract);

router.put('/contracts/:id/status', auth, updateContractStatus);
router.put('/contracts/:id/assign', auth, assignDriver);
router.get('/contracts/available', auth, getAvailableContracts);

module.exports = router;