import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

/// Displays a banner at the top of the screen when offline.
/// Wrap your Scaffold body with this widget.
class OfflineBanner extends StatelessWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityService>();

    return Column(
      children: [
        if (!connectivity.isOnline)
          MaterialBanner(
            content: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No internet connection. Some features may be limited.',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            actions: const [SizedBox.shrink()],
          ),
        Expanded(child: child),
      ],
    );
  }
}
