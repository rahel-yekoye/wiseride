const express = require('express');
const router = express.Router();
const { protect, admin } = require('../middleware/auth');
const {
  validatePromoCode,
  applyPromoCode,
  createPromoCode,
  getAllPromoCodes,
  updatePromoCode,
  deletePromoCode,
  getUserPromoHistory,
  generateReferralCode,
} = require('../controllers/promoCodeController');

// User routes (require authentication)
router.post('/validate', protect, validatePromoCode);
router.post('/apply', protect, applyPromoCode);
router.get('/history', protect, getUserPromoHistory);
router.post('/referral', protect, generateReferralCode);

// Admin routes (require authentication + admin role)
router.post('/create', protect, admin, createPromoCode);
router.get('/', protect, admin, getAllPromoCodes);
router.put('/:id', protect, admin, updatePromoCode);
router.delete('/:id', protect, admin, deletePromoCode);

module.exports = router;
