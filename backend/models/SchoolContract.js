const mongoose = require('mongoose');

const childSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  grade: {
    type: String,
    required: true
  },
  pickupPoint: {
    lat: Number,
    lng: Number,
    address: String
  },
  dropPoint: {
    lat: Number,
    lng: Number,
    address: String
  }
});

const scheduleSchema = new mongoose.Schema({
  days: [{
    type: String,
    enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
  }],
  pickupTime: {
    type: String,
    required: true
  },
  returnTime: {
    type: String,
    required: true
  }
});

const schoolContractSchema = new mongoose.Schema({
  parentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  children: [childSchema],
  schedule: scheduleSchema,
  monthlyFee: {
    type: Number,
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'active', 'paused', 'cancelled'],
    default: 'pending'
  },
  startDate: {
    type: Date
  },
  endDate: {
    type: Date
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('SchoolContract', schoolContractSchema);