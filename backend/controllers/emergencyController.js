const EmergencyAlert = require('../models/EmergencyAlert');
const User = require('../models/User');

// Create SOS alert
const createAlert = async (req, res) => {
  try {
    const { rideId, type = 'other', location, description, priority } = req.body;

    if (!location || !Array.isArray(location.coordinates) || location.coordinates.length !== 2) {
      return res.status(400).json({ message: 'Location with [lng, lat] coordinates is required' });
    }

    const alert = await EmergencyAlert.create({
      userId: req.user._id,
      rideId,
      type,
      location: {
        type: 'Point',
        coordinates: location.coordinates,
        address: location.address,
      },
      description,
      priority: priority || 'high',
      status: 'active',
    });

    // Load user once (with contacts) for notifications
    let user;
    try {
      user = await User.findById(req.user._id).select('emergencyContacts name phone');
    } catch (_) {}

    // If user has emergency contacts, record that they were notified (future SMS/voice integration)
    try {
      if (user && Array.isArray(user.emergencyContacts) && user.emergencyContacts.length > 0) {
        alert.contactsNotified = user.emergencyContacts.map(c => ({
          name: c.name,
          phone: c.phone,
          relationship: c.relationship,
          notifiedAt: new Date(),
        }));
        await alert.save();
      }
    } catch (_) {
      // ignore if contacts not found
    }

    // Send SMS to emergency contacts if configured
    let smsSentCount = 0;
    try {
      const { sendSmsNormalized } = require('../services/notificationService');
      if (alert.contactsNotified && alert.contactsNotified.length > 0) {
        const messages = await Promise.all(
          alert.contactsNotified.map(async (c) => {
            const lat = alert.location?.coordinates?.[1];
            const lng = alert.location?.coordinates?.[0];
            const mapsLink = (lat !== undefined && lng !== undefined)
              ? `https://maps.google.com/?q=${lat},${lng}`
              : '';
            const msg = `WiseRide SOS: ${user?.name || 'A user'} needs help. Location: ${alert.location?.address || 'Unknown'} ${mapsLink}. Phone: ${user?.phone || ''}`;
            const result = await sendSmsNormalized(c.phone, msg);
            return result.success;
          })
        );
        smsSentCount = messages.filter(Boolean).length;
      }
    } catch (_) {
      // ignore SMS failures silently
    }

    // Emit basic notification to admins/support (broadcast to riders room for demo)
    try {
      const { emitToAllRiders } = require('../services/socketService');
      emitToAllRiders('sos:new_alert', {
        id: alert._id,
        userId: alert.userId,
        type: alert.type,
        location: alert.location,
        description: alert.description,
        createdAt: alert.createdAt,
      });
    } catch (_) {
      // Socket not initialized or unavailable; ignore silently
    }

    res.status(201).json({
      message: 'Emergency alert created',
      alert,
      contactsNotifiedCount: alert.contactsNotified?.length || 0,
      contactsNotificationMethod: smsSentCount > 0 ? 'sms' : (alert.contactsNotified?.length ? 'attempted_sms' : 'none')
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get alerts for current user
const getMyAlerts = async (req, res) => {
  try {
    const alerts = await EmergencyAlert.find({ userId: req.user._id }).sort({ createdAt: -1 });
    res.json({ alerts });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Admin: get active alerts
const getActiveAlerts = async (req, res) => {
  try {
    const { limit = 50 } = req.query;
    const alerts = await EmergencyAlert.find({ status: 'active' })
      .sort({ createdAt: -1 })
      .limit(Number(limit));
    res.json({ alerts });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Admin: mark responded
const respondToAlert = async (req, res) => {
  try {
    const { id } = req.params;
    const alert = await EmergencyAlert.findByIdAndUpdate(
      id,
      { status: 'responded', respondedBy: req.user._id, respondedAt: new Date() },
      { new: true }
    );
    if (!alert) return res.status(404).json({ message: 'Alert not found' });
    res.json({ message: 'Alert marked as responded', alert });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Admin: resolve alert
const resolveAlert = async (req, res) => {
  try {
    const { id } = req.params;
    const { resolution = '' } = req.body;
    const alert = await EmergencyAlert.findByIdAndUpdate(
      id,
      { status: 'resolved', resolution },
      { new: true }
    );
    if (!alert) return res.status(404).json({ message: 'Alert not found' });
    res.json({ message: 'Alert resolved', alert });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createAlert,
  getMyAlerts,
  getActiveAlerts,
  respondToAlert,
  resolveAlert,
};


