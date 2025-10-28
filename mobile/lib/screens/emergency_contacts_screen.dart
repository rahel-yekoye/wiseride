import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  bool _loading = true;
  bool _saving = false;
  List<Map<String, String>> _contacts = [
    {'name': '', 'phone': '', 'relationship': ''},
  ];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final me = await ApiService().get('/users/me');
      final List<dynamic> ecs = me['emergencyContacts'] ?? [];
      setState(() {
        _contacts = ecs
            .map((e) => {
                  'name': (e['name'] ?? '').toString(),
                  'phone': (e['phone'] ?? '').toString(),
                  'relationship': (e['relationship'] ?? '').toString(),
                })
            .toList()
            .cast<Map<String, String>>();
        if (_contacts.isEmpty) {
          _contacts = [
            {'name': '', 'phone': '', 'relationship': ''},
          ];
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load contacts: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveContacts() async {
    setState(() => _saving = true);
    try {
      // Filter out empty entries
      final payload = _contacts
          .where((c) => (c['name']?.trim().isNotEmpty ?? false) && (c['phone']?.trim().isNotEmpty ?? false))
          .toList();

      await ApiService().put('/users/me', body: {
        'emergencyContacts': payload,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency contacts saved'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addContact() {
    if (_contacts.length >= 3) return;
    setState(() {
      _contacts.add({'name': '', 'phone': '', 'relationship': ''});
    });
  }

  void _removeContact(int index) {
    setState(() {
      _contacts.removeAt(index);
      if (_contacts.isEmpty) {
        _contacts.add({'name': '', 'phone': '', 'relationship': ''});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveContacts,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add up to 3 trusted contacts. We will notify them during an SOS.',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  for (int i = 0; i < _contacts.length; i++) _buildContactCard(i),
                  const SizedBox(height: 12),
                  if (_contacts.length < 3)
                    ElevatedButton.icon(
                      onPressed: _addContact,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Contact'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildContactCard(int index) {
    final c = _contacts[index];
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Contact ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_contacts.length > 1)
                  IconButton(
                    onPressed: () => _removeContact(index),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
              ],
            ),
            TextFormField(
              initialValue: c['name'],
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (v) => _contacts[index]['name'] = v,
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: c['phone'],
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              onChanged: (v) => _contacts[index]['phone'] = v,
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: c['relationship'],
              decoration: const InputDecoration(labelText: 'Relationship (e.g., Father)'),
              onChanged: (v) => _contacts[index]['relationship'] = v,
            ),
          ],
        ),
      ),
    );
  }
}


