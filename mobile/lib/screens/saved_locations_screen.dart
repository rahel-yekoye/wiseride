import 'package:flutter/material.dart';
import '../models/school_contract.dart';
import '../services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SavedLocation {
  final String id;
  final String name;
  final String type; // home, work, custom
  final Location location;

  SavedLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'location': {
        'lat': location.lat,
        'lng': location.lng,
        'address': location.address,
      },
    };
  }

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    final loc = json['location'];
    return SavedLocation(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      location: Location(
        lat: loc['lat'].toDouble(),
        lng: loc['lng'].toDouble(),
        address: loc['address'],
      ),
    );
  }
}

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  List<SavedLocation> _savedLocations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  Future<void> _loadSavedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getString('saved_locations');
      
      if (locationsJson != null) {
        final List<dynamic> decoded = json.decode(locationsJson);
        setState(() {
          _savedLocations = decoded.map((item) => SavedLocation.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = json.encode(_savedLocations.map((loc) => loc.toJson()).toList());
    await prefs.setString('saved_locations', locationsJson);
  }

  Future<void> _addLocation(String name, String type, Location location) async {
    final newLocation = SavedLocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      location: location,
    );

    setState(() {
      _savedLocations.add(newLocation);
    });

    await _saveLocations();
  }

  Future<void> _deleteLocation(String id) async {
    setState(() {
      _savedLocations.removeWhere((loc) => loc.id == id);
    });

    await _saveLocations();
  }

  Future<void> _showAddLocationDialog() async {
    final nameController = TextEditingController();
    String selectedType = 'custom';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Saved Location'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Location Name',
                  hintText: 'e.g., Home, Work',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Home'),
                      selected: selectedType == 'home',
                      onSelected: (selected) {
                        setState(() => selectedType = 'home');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Work'),
                      selected: selectedType == 'work',
                      onSelected: (selected) {
                        setState(() => selectedType = 'work');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Custom'),
                      selected: selectedType == 'custom',
                      onSelected: (selected) {
                        setState(() => selectedType = 'custom');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Get current location or let user search
                    final location = await LocationService.getCurrentLocation();
                    if (location != null) {
                      await _addLocation(
                        nameController.text.isEmpty ? selectedType : nameController.text,
                        selectedType,
                        location,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('Use Current Location'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Saved Locations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedLocations.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _savedLocations.length,
                  itemBuilder: (context, index) {
                    return _buildLocationCard(_savedLocations[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLocationDialog,
        backgroundColor: Colors.blue[600],
        icon: const Icon(Icons.add),
        label: const Text('Add Location'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No saved locations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save your favorite places for quick access',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(SavedLocation location) {
    final typeIcon = _getTypeIcon(location.type);
    final typeColor = _getTypeColor(location.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: typeColor, width: 2),
          ),
          child: Icon(typeIcon, color: typeColor, size: 24),
        ),
        title: Text(
          location.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          location.location.address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteLocation(location.id),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      default:
        return Icons.location_on;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'home':
        return Colors.blue;
      case 'work':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }
}
