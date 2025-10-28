import 'package:flutter/material.dart';
import '../services/registration_service.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registrationService = RegistrationService();
  
  // Vehicle Info
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  String _vehicleType = 'taxi';
  
  // Bank Details
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _plateNumberController.dispose();
    _capacityController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _registrationService.startRegistration(
        vehicleInfo: {
          'make': _makeController.text,
          'model': _modelController.text,
          'year': int.parse(_yearController.text),
          'color': _colorController.text,
          'plateNumber': _plateNumberController.text,
          'capacity': int.parse(_capacityController.text),
          'vehicleType': _vehicleType,
        },
        bankDetails: {
          'bankName': _bankNameController.text,
          'accountNumber': _accountNumberController.text,
          'accountHolderName': _accountHolderController.text,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration started successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Registration'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 1) {
              setState(() => _currentStep++);
            } else {
              _submitRegistration();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          steps: [
            Step(
              title: const Text('Vehicle Information'),
              isActive: _currentStep >= 0,
              content: Column(
                children: [
                  TextFormField(
                    controller: _makeController,
                    decoration: const InputDecoration(labelText: 'Make'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(labelText: 'Model'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(labelText: 'Year'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(labelText: 'Color'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _plateNumberController,
                    decoration: const InputDecoration(labelText: 'Plate Number'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(labelText: 'Capacity'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: _vehicleType,
                    decoration: const InputDecoration(labelText: 'Vehicle Type'),
                    items: const [
                      DropdownMenuItem(value: 'taxi', child: Text('Taxi')),
                      DropdownMenuItem(value: 'bus', child: Text('Bus')),
                      DropdownMenuItem(value: 'minibus', child: Text('Minibus')),
                      DropdownMenuItem(value: 'private_car', child: Text('Private Car')),
                    ],
                    onChanged: (value) => setState(() => _vehicleType = value!),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Bank Details'),
              isActive: _currentStep >= 1,
              content: Column(
                children: [
                  TextFormField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(labelText: 'Bank Name'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _accountNumberController,
                    decoration: const InputDecoration(labelText: 'Account Number'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _accountHolderController,
                    decoration: const InputDecoration(labelText: 'Account Holder Name'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
