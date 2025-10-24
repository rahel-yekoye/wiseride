import 'package:flutter/material.dart';
import '../../models/school_contract.dart';
import '../../services/api_service.dart';

class CreateContractScreen extends StatefulWidget {
  const CreateContractScreen({super.key});

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Form controllers
  final _childNameController = TextEditingController();
  final _childGradeController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _dropoffAddressController = TextEditingController();
  final _monthlyFeeController = TextEditingController();

  String _pickupTime = '07:00';
  String _returnTime = '15:00';
  final List<String> _selectedDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  final List<String> _allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<Child> _children = [];
  bool _isLoading = false;

  // Default coordinates (Addis Ababa center)
  final double _pickupLat = 9.0320;
  final double _pickupLng = 38.7469;
  final double _dropoffLat = 9.0320;
  final double _dropoffLng = 38.7469;

  @override
  void dispose() {
    _childNameController.dispose();
    _childGradeController.dispose();
    _pickupAddressController.dispose();
    _dropoffAddressController.dispose();
    _monthlyFeeController.dispose();
    super.dispose();
  }

  void _addChild() {
    if (_childNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter child name')),
      );
      return;
    }

    setState(() {
      _children.add(Child(
        name: _childNameController.text,
        grade: _childGradeController.text.isEmpty ? 'N/A' : _childGradeController.text,
      ));
      _childNameController.clear();
      _childGradeController.clear();
    });
  }

  void _removeChild(int index) {
    setState(() {
      _children.removeAt(index);
    });
  }

  Future<void> _selectTime(BuildContext context, bool isPickup) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(isPickup ? _pickupTime.split(':')[0] : _returnTime.split(':')[0]),
        minute: int.parse(isPickup ? _pickupTime.split(':')[1] : _returnTime.split(':')[1]),
      ),
    );

    if (picked != null) {
      setState(() {
        final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isPickup) {
          _pickupTime = formattedTime;
        } else {
          _returnTime = formattedTime;
        }
      });
    }
  }

  Future<void> _createContract() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one child')),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    final monthlyFee = double.tryParse(_monthlyFeeController.text);
    if (monthlyFee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid monthly fee')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create location objects
      final pickupLocation = Location(
        lat: _pickupLat,
        lng: _pickupLng,
        address: _pickupAddressController.text.isEmpty ? 'Default Pickup Location' : _pickupAddressController.text,
      );
      
      final dropoffLocation = Location(
        lat: _dropoffLat,
        lng: _dropoffLng,
        address: _dropoffAddressController.text.isEmpty ? 'Default Dropoff Location' : _dropoffAddressController.text,
      );

      // Update children with location information
      final childrenWithLocations = _children.map((child) => Child(
        name: child.name,
        grade: child.grade,
        pickupPoint: pickupLocation,
        dropPoint: dropoffLocation,
      )).toList();

      final contractData = {
        'children': childrenWithLocations.map((c) => c.toJson()).toList(),
        'schedule': {
          'pickupTime': _pickupTime,
          'returnTime': _returnTime,
          'days': _selectedDays,
        },
        'monthlyFee': monthlyFee,
      };

      await _apiService.post(
        '/school/contracts', 
        body: contractData, 
        requiresAuth: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contract created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create contract: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text('Create School Contract'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Children Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Children Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _childNameController,
                              decoration: const InputDecoration(
                                labelText: 'Child Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.child_care),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter child name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _childGradeController,
                              decoration: const InputDecoration(
                                labelText: 'Grade (Optional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.grade),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _addChild,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Child'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                              ),
                            ),
                            if (_children.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const Text(
                                'Added Children:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ..._children.asMap().entries.map((entry) {
                                final index = entry.key;
                                final child = entry.value;
                                return Card(
                                  color: Colors.green[50],
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(child.name[0].toUpperCase()),
                                    ),
                                    title: Text(child.name),
                                    subtitle: Text('Grade: ${child.grade}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeChild(index),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Schedule Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Schedule',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.access_time),
                              title: const Text('Pickup Time'),
                              subtitle: Text(_pickupTime),
                              trailing: const Icon(Icons.edit),
                              onTap: () => _selectTime(context, true),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.access_time),
                              title: const Text('Return Time'),
                              subtitle: Text(_returnTime),
                              trailing: const Icon(Icons.edit),
                              onTap: () => _selectTime(context, false),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Select Days:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: _allDays.map((day) {
                                final isSelected = _selectedDays.contains(day);
                                return FilterChip(
                                  label: Text(day),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedDays.add(day);
                                      } else {
                                        _selectedDays.remove(day);
                                      }
                                    });
                                  },
                                  selectedColor: Colors.green[300],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Locations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _pickupAddressController,
                              decoration: const InputDecoration(
                                labelText: 'Pickup Address',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _dropoffAddressController,
                              decoration: const InputDecoration(
                                labelText: 'Dropoff Address',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _monthlyFeeController,
                              decoration: const InputDecoration(
                                labelText: 'Monthly Fee (ETB)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter monthly fee';
                                }
                                final fee = double.tryParse(value);
                                if (fee == null || fee <= 0) {
                                  return 'Please enter a valid fee';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createContract,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Create Contract',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}