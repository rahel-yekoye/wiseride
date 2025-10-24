const express = require('express');
const router = express.Router();
const { 
  registerUser, 
  loginUser, 
  getUserProfile, 
  updateUserProfile,
  getUsers,
  getUserById
} = require('../controllers/userController');
const auth = require('../middleware/auth');

// Public routes
router.post('/register', registerUser);
router.post('/login', loginUser);

// Protected routes
router.get('/me', auth, getUserProfile);
router.put('/me', auth, updateUserProfile);
router.get('/', auth, getUsers);
router.get('/:id', auth, getUserById);

module.exports = router;