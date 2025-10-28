const express = require('express');
const router = express.Router();
const {
  startRegistration,
  uploadDocument,
  getDocuments,
  submitForReview,
  getRegistrationStatus,
  reviewRegistration,
  getPendingRegistrations
} = require('../controllers/registrationController');
const { auth } = require('../middleware/auth');

// All routes are protected
router.use(auth);

// Driver registration routes
router.post('/start', startRegistration);
router.post('/documents', uploadDocument);
router.get('/documents', getDocuments);
router.post('/submit', submitForReview);
router.get('/status', getRegistrationStatus);

// Admin routes
router.get('/pending', getPendingRegistrations);
router.put('/:driverId/review', reviewRegistration);

module.exports = router;
