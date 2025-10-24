const SchoolContract = require('../models/SchoolContract');
const User = require('../models/User');

// Create a new school contract
const createContract = async (req, res) => {
  try {
    const { children, schedule, monthlyFee } = req.body;

    const contract = await SchoolContract.create({
      parentId: req.user._id,
      children,
      schedule,
      monthlyFee,
    });

    res.status(201).json(contract);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get all contracts for a parent
const getParentContracts = async (req, res) => {
  try {
    const contracts = await SchoolContract.find({ parentId: req.user._id })
      .sort({ createdAt: -1 });
    
    res.json(contracts);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get contract by ID
const getContractById = async (req, res) => {
  try {
    const contract = await SchoolContract.findById(req.params.id);
    
    if (!contract) {
      return res.status(404).json({ message: 'Contract not found' });
    }
    
    // Check if user is authorized to view this contract
    if (contract.parentId.toString() !== req.user._id.toString() && 
        contract.driverId && contract.driverId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }
    
    res.json(contract);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update contract status
const updateContractStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const contract = await SchoolContract.findById(req.params.id);
    
    if (!contract) {
      return res.status(404).json({ message: 'Contract not found' });
    }
    
    // Check if user is authorized to update this contract
    if (contract.parentId.toString() !== req.user._id.toString() && 
        contract.driverId && contract.driverId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }
    
    contract.status = status;
    
    if (status === 'active') {
      contract.startDate = new Date();
    } else if (status === 'cancelled') {
      contract.endDate = new Date();
    }
    
    const updatedContract = await contract.save();
    res.json(updatedContract);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Assign driver to contract
const assignDriver = async (req, res) => {
  try {
    const contract = await SchoolContract.findById(req.params.id);
    
    if (!contract) {
      return res.status(404).json({ message: 'Contract not found' });
    }
    
    // Check if user is a driver
    if (req.user.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can accept contracts' });
    }
    
    // Check if contract is still available
    if (contract.status !== 'pending') {
      return res.status(400).json({ message: 'Contract is no longer available' });
    }
    
    contract.driverId = req.user._id;
    contract.status = 'active';
    const updatedContract = await contract.save();
    
    res.json(updatedContract);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get available contracts (for drivers)
const getAvailableContracts = async (req, res) => {
  try {
    // Check if user is a driver
    if (req.user.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can view available contracts' });
    }
    
    const contracts = await SchoolContract.find({ 
      status: 'pending'
    }).sort({ createdAt: -1 });
    
    res.json(contracts);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update contract
const updateContract = async (req, res) => {
  try {
    const { children, schedule, monthlyFee } = req.body;
    const contract = await SchoolContract.findById(req.params.id);
    
    if (!contract) {
      return res.status(404).json({ message: 'Contract not found' });
    }
    
    // Check if user is authorized to update this contract
    if (contract.parentId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }
    
    if (children) contract.children = children;
    if (schedule) contract.schedule = schedule;
    if (monthlyFee) contract.monthlyFee = monthlyFee;
    
    const updatedContract = await contract.save();
    res.json(updatedContract);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createContract,
  getParentContracts,
  getContractById,
  updateContractStatus,
  assignDriver,
  getAvailableContracts,
  updateContract,
};