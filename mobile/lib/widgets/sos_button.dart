import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SOSButton extends StatelessWidget {
  final String? rideId;
  final double? currentLat;
  final double? currentLng;
  final String? currentAddress;

  const SOSButton({
    super.key,
    this.rideId,
    this.currentLat,
    this.currentLng,
    this.currentAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0, right: 16.0),
      child: FloatingActionButton.extended(
        onPressed: () => _triggerSOS(context),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.warning_amber_rounded, size: 28),
        label: const Text(
          'EMERGENCY SOS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        heroTag: 'sos_button',
      ),
    );
  }

  Future<void> _triggerSOS(BuildContext context) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Emergency SOS'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('Share your live location')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('Notify emergency contacts')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.support_agent, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('Alert WiseRide support')),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Are you in an emergency?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('SEND SOS'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.red),
                SizedBox(height: 16),
                Text('Sending emergency alert...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Send SOS alert to backend
      final response = await ApiService().post('/emergency/alert', body: {
        if (rideId != null) 'rideId': rideId,
        'type': 'other',
        'location': {
          'coordinates': [currentLng ?? 0, currentLat ?? 0],
          'address': currentAddress ?? 'Unknown location',
        },
        'description': 'Emergency SOS triggered from app',
      });

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('SOS Sent'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emergency alert has been sent!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),
                const Text('✓ Your location has been shared'),
                FutureBuilder(
                  future: ApiService().get('/users/me'),
                  builder: (context, snapshot) {
                    final hasContacts = snapshot.hasData &&
                        snapshot.data is Map &&
                        ((snapshot.data as Map)['emergencyContacts'] as List?)?.isNotEmpty == true;
                    return Text(
                      hasContacts ? '✓ Emergency contacts notified' : '• No emergency contacts on file',
                      style: TextStyle(color: hasContacts ? Colors.black : Colors.orange),
                    );
                  },
                ),
                const Text('✓ Support team alerted'),
                const SizedBox(height: 6),
                if (response is Map && response['contactsNotifiedCount'] != null)
                  Text(
                    'Contacts notified: ${response['contactsNotifiedCount']} (${response['contactsNotificationMethod']})',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                SizedBox(height: 12),
                const Text(
                  'Help is on the way. Stay safe!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Text('Error'),
              ],
            ),
            content: Text('Failed to send SOS: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

}

// Alternative: Large SOS Button for dedicated screen
class LargeSOSButton extends StatefulWidget {
  final String? rideId;
  final double? currentLat;
  final double? currentLng;
  final String? currentAddress;

  const LargeSOSButton({
    super.key,
    this.rideId,
    this.currentLat,
    this.currentLng,
    this.currentAddress,
  });

  @override
  State<LargeSOSButton> createState() => _LargeSOSButtonState();
}

class _LargeSOSButtonState extends State<LargeSOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              SOSButton(
                rideId: widget.rideId,
                currentLat: widget.currentLat,
                currentLng: widget.currentLng,
                currentAddress: widget.currentAddress,
              )._triggerSOS(context);
            },
            customBorder: const CircleBorder(),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning,
                  size: 64,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'EMERGENCY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
