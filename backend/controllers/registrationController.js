const User = require('../models/User');
const DriverDocument = require('../models/DriverDocument');

// Start driver registration
const startRegistration = async (req, res) => {
  try {
    const {
      vehicleInfo,
      bankDetails,
      mobileMoneyDetails,
      serviceAreas,
      availabilitySchedule
    } = req.body;

    const user = await User.findById(req.user._id);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (user.role !== 'driver') {
      return res.status(400).json({ message: 'User must be registered as a driver' });
    }

    // Update driver information
    if (vehicleInfo) {
      user.vehicleInfo = vehicleInfo;
    }
    
    if (bankDetails) {
      user.bankDetails = bankDetails;
    }
    
    if (mobileMoneyDetails) {
      user.mobileMoneyDetails = mobileMoneyDetails;
    }
    
    if (serviceAreas) {
      user.serviceAreas = serviceAreas;
    }
    
    if (availabilitySchedule) {
      user.availabilitySchedule = availabilitySchedule;
    }

    user.driverRegistrationStatus = 'pending';
    await user.save();

    res.json({
      message: 'Driver registration started successfully',
      user
    });
  } catch (error) {
    console.error('Error in startRegistration:', error);
    res.status(500).json({ message: error.message });
  }
};

// Upload driver documents
const uploadDocument = async (req, res) => {
  try {
    const {
      documentType,
      documentUrl,
      documentNumber,
      expiryDate,
      metadata
    } = req.body;

    if (!documentType || !documentUrl) {
      return res.status(400).json({ 
        message: 'Document type and URL are required' 
      });
    }

    const user = await User.findById(req.user._id);
    
    if (!user || user.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can upload documents' });
    }

    // Check if document already exists
    let document = await DriverDocument.findOne({
      driverId: req.user._id,
      documentType
    });

    if (document) {
      // Update existing document
      document.documentUrl = documentUrl;
      document.documentNumber = documentNumber;
      document.expiryDate = expiryDate;
      document.metadata = metadata;
      document.verificationStatus = 'pending';
    } else {
      // Create new document
      document = new DriverDocument({
        driverId: req.user._id,
        documentType,
        documentUrl,
        documentNumber,
        expiryDate,
        metadata
      });
    }

    await document.save();

    // Check if all required documents are uploaded
    const requiredDocs = ['license', 'vehicle_registration', 'insurance', 'id_card'];
    const uploadedDocs = await DriverDocument.find({
      driverId: req.user._id,
      documentType: { $in: requiredDocs }
    });

    if (uploadedDocs.length === requiredDocs.length) {
      user.driverRegistrationStatus = 'documents_submitted';
      await user.save();
    }

    res.json({
      message: 'Document uploaded successfully',
      document
    });
  } catch (error) {
    console.error('Error in uploadDocument:', error);
    res.status(500).json({ message: error.message });
  }
};

// Get driver documents
const getDocuments = async (req, res) => {
  try {
    const documents = await DriverDocument.find({
      driverId: req.user._id
    }).sort({ createdAt: -1 });

    res.json(documents);
  } catch (error) {
    console.error('Error in getDocuments:', error);
    res.status(500).json({ message: error.message });
  }
};

// Submit registration for review
const submitForReview = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    
    if (!user || user.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can submit for review' });
    }

    // Validate required information
    if (!user.vehicleInfo || !user.vehicleInfo.plateNumber) {
      return res.status(400).json({ message: 'Vehicle information is required' });
    }

    if (!user.bankDetails && !user.mobileMoneyDetails) {
      return res.status(400).json({ 
        message: 'Payment details (bank or mobile money) are required' 
      });
    }

    // Check if all required documents are uploaded
    const requiredDocs = ['license', 'vehicle_registration', 'insurance', 'id_card'];
    const uploadedDocs = await DriverDocument.find({
      driverId: req.user._id,
      documentType: { $in: requiredDocs }
    });

    if (uploadedDocs.length < requiredDocs.length) {
      return res.status(400).json({ 
        message: 'All required documents must be uploaded',
        missing: requiredDocs.filter(doc => 
          !uploadedDocs.find(d => d.documentType === doc)
        )
      });
    }

    user.driverRegistrationStatus = 'under_review';
    await user.save();

    res.json({
      message: 'Registration submitted for review successfully',
      user
    });
  } catch (error) {
    console.error('Error in submitForReview:', error);
    res.status(500).json({ message: error.message });
  }
};

// Get registration status
const getRegistrationStatus = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-password');
    const documents = await DriverDocument.find({
      driverId: req.user._id
    });

    const requiredDocs = ['license', 'vehicle_registration', 'insurance', 'id_card'];
    const uploadedDocs = documents.filter(doc => 
      requiredDocs.includes(doc.documentType)
    );

    res.json({
      status: user.driverRegistrationStatus,
      approvalDate: user.driverApprovalDate,
      rejectionReason: user.driverRejectionReason,
      vehicleInfo: user.vehicleInfo,
      bankDetails: user.bankDetails,
      mobileMoneyDetails: user.mobileMoneyDetails,
      serviceAreas: user.serviceAreas,
      availabilitySchedule: user.availabilitySchedule,
      documents: uploadedDocs,
      requiredDocuments: requiredDocs,
      completionPercentage: Math.round((uploadedDocs.length / requiredDocs.length) * 100)
    });
  } catch (error) {
    console.error('Error in getRegistrationStatus:', error);
    res.status(500).json({ message: error.message });
  }
};

// Admin: Review and approve/reject driver registration
const reviewRegistration = async (req, res) => {
  try {
    const { driverId } = req.params;
    const { action, reason } = req.body; // action: 'approve' or 'reject'

    // Check if user is admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can review registrations' });
    }

    const driver = await User.findById(driverId);
    
    if (!driver || driver.role !== 'driver') {
      return res.status(404).json({ message: 'Driver not found' });
    }

    if (action === 'approve') {
      driver.driverRegistrationStatus = 'approved';
      driver.driverVerified = true;
      driver.driverApprovalDate = new Date();
      driver.driverRejectionReason = undefined;

      // Approve all documents
      await DriverDocument.updateMany(
        { driverId: driver._id, verificationStatus: 'pending' },
        { 
          verificationStatus: 'approved',
          verifiedBy: req.user._id,
          verifiedAt: new Date()
        }
      );
    } else if (action === 'reject') {
      driver.driverRegistrationStatus = 'rejected';
      driver.driverVerified = false;
      driver.driverRejectionReason = reason || 'Registration rejected';
    } else {
      return res.status(400).json({ message: 'Invalid action' });
    }

    await driver.save();

    res.json({
      message: `Driver registration ${action}ed successfully`,
      driver
    });
  } catch (error) {
    console.error('Error in reviewRegistration:', error);
    res.status(500).json({ message: error.message });
  }
};

// Admin: Get all pending registrations
const getPendingRegistrations = async (req, res) => {
  try {
    // Check if user is admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can view pending registrations' });
    }

    const pendingDrivers = await User.find({
      role: 'driver',
      driverRegistrationStatus: { $in: ['under_review', 'documents_submitted'] }
    }).select('-password').sort({ updatedAt: -1 });

    // Get documents for each driver
    const driversWithDocs = await Promise.all(
      pendingDrivers.map(async (driver) => {
        const documents = await DriverDocument.find({
          driverId: driver._id
        });
        return {
          ...driver.toObject(),
          documents
        };
      })
    );

    res.json(driversWithDocs);
  } catch (error) {
    console.error('Error in getPendingRegistrations:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  startRegistration,
  uploadDocument,
  getDocuments,
  submitForReview,
  getRegistrationStatus,
  reviewRegistration,
  getPendingRegistrations
};
