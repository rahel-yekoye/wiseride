import 'package:flutter/material.dart';
import '../../models/school_contract.dart';
import '../../services/api_service.dart';
import './create_contract_screen.dart';
import './contract_detail_screen.dart';

class ContractListScreen extends StatefulWidget {
  const ContractListScreen({super.key});

  @override
  State<ContractListScreen> createState() => _ContractListScreenState();
}

class _ContractListScreenState extends State<ContractListScreen> {
  final ApiService _apiService = ApiService();
  List<SchoolContract> _contracts = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final response = await _apiService.get('/school/contracts', requiresAuth: true);
      final contractsJson = response as List? ?? [];
      
      if (mounted) {
        setState(() {
          _contracts = contractsJson
              .map((json) => SchoolContract.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load contracts: $e';
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadContracts,
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteContract(String contractId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contract'),
        content: const Text('Are you sure you want to delete this contract? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.delete('/school/contracts/$contractId', requiresAuth: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contract deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadContracts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete contract: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Ride Contracts'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContracts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contracts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadContracts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _contracts.length,
                    itemBuilder: (context, index) {
                      final contract = _contracts[index];
                      return _buildContractCard(contract);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateContractScreen()),
          );
          if (result == true) {
            _loadContracts();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Contract'),
        backgroundColor: Colors.green[700],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 100,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 24),
              const Text(
                'No contracts yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create your first school ride contract\nto get started with safe transportation',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateContractScreen()),
                  );
                  if (result == true) {
                    _loadContracts();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Contract'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractCard(SchoolContract contract) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ContractDetailScreen(contract: contract),
            ),
          );
          if (result == true) {
            _loadContracts();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Contract #${contract.id?.substring(0, 8) ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(contract.status),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.child_care,
                '${contract.children.length} child${contract.children.length != 1 ? 'ren' : ''}',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.schedule,
                '${contract.schedule.pickupTime} - ${contract.schedule.returnTime}',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.calendar_today,
                contract.schedule.days.join(', '),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.attach_money,
                '${contract.monthlyFee} ETB/month',
              ),
              if (contract.driverId != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.person,
                  'Driver assigned',
                  color: Colors.green,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ContractDetailScreen(contract: contract),
                        ),
                      );
                      if (result == true) {
                        _loadContracts();
                      }
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteContract(contract.id!),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'active':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        displayText = 'Active';
        break;
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        displayText = 'Pending';
        break;
      case 'completed':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        displayText = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        displayText = 'Cancelled';
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
