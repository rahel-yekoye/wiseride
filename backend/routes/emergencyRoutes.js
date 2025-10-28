const express = require('express');
const router = express.Router();
const { protect, admin } = require('../middleware/auth');
const {
  createAlert,
  getMyAlerts,
  getActiveAlerts,
  respondToAlert,
  resolveAlert,
} = require('../controllers/emergencyController');

// User routes
router.post('/alert', protect, createAlert);
router.get('/alerts', protect, getMyAlerts);

// Admin routes
router.get('/active', protect, admin, getActiveAlerts);
router.put('/:id/respond', protect, admin, respondToAlert);
router.put('/:id/resolve', protect, admin, resolveAlert);

module.exports = router;


