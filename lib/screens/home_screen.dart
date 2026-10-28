import 'package:flutter/material.dart';
import '../models/network_state.dart';
import '../services/network_monitor_service.dart';
import 'network_monitor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Color _getInterfaceColor(NetworkInterfaceType type) {
    switch (type) {
      case NetworkInterfaceType.wifi:
        return const Color(0xFF00C853);
      case NetworkInterfaceType.cellular:
        return const Color(0xFF2979FF);
      case NetworkInterfaceType.ethernet:
        return const Color(0xFF00B0FF);
      case NetworkInterfaceType.vpn:
        return const Color(0xFFAA00FF);
      case NetworkInterfaceType.bluetooth:
        return const Color(0xFFFF9100);
      case NetworkInterfaceType.offline:
      case NetworkInterfaceType.other:
        return const Color(0xFFFF1744);
    }
  }

  IconData _getInterfaceIcon(NetworkInterfaceType type) {
    switch (type) {
      case NetworkInterfaceType.wifi:
        return Icons.wifi_rounded;
      case NetworkInterfaceType.cellular:
        return Icons.signal_cellular_alt_rounded;
      case NetworkInterfaceType.ethernet:
        return Icons.settings_ethernet_rounded;
      case NetworkInterfaceType.vpn:
        return Icons.vpn_lock_rounded;
      case NetworkInterfaceType.bluetooth:
        return Icons.bluetooth_connected_rounded;
      case NetworkInterfaceType.offline:
      case NetworkInterfaceType.other:
        return Icons.wifi_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final monitorService = NetworkMonitorService.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mobile Computing Master App',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Laboratory & Hands-on Compilation',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // Live connectivity pill in AppBar
          StreamBuilder<NetworkState>(
            stream: monitorService.networkStream,
            initialData: monitorService.currentState,
            builder: (context, snapshot) {
              final state = snapshot.data ?? monitorService.currentState;
              final color = _getInterfaceColor(state.interfaceType);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getInterfaceIcon(state.interfaceType), size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      state.isConnected ? state.interfaceType.name.toUpperCase() : 'OFFLINE',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome / Partner banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.hub_rounded, color: Colors.lightBlueAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hands-on Compilation Hub',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Pair Activity Portfolio & Practical Tests',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 10),
                const Text(
                  'Select an activity module below to launch interactive real-time demonstrations and test suites.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'ACTIVITIES & MODULES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 12),

          // Primary Featured Activity Card: Network Monitor & Handover Handling
          _buildActivityCard(
            context,
            activityNumber: 'Activity 2 (Featured)',
            title: 'Active Network Monitor & Handover Handling',
            subtitle:
                'Real-time network stream listener, dynamic interface dashboard (Wi-Fi/Cellular/Offline), robust request queuing, and automatic recovery upon IP handover.',
            icon: Icons.wifi_protected_setup_rounded,
            badgeColor: const Color(0xFF2563EB),
            tags: ['connectivity_plus', 'Stream Listeners', 'Request Queue', 'Zero Drop Recovery'],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NetworkMonitorScreen()),
              );
            },
          ),

          const SizedBox(height: 14),

          // Placeholder Activity 1 Card (Demonstrating master compilation structure)
          _buildActivityCard(
            context,
            activityNumber: 'Activity 1',
            title: 'Device Orientation & Sensor Metrics',
            subtitle: 'Compilation module for accelerometer, gyroscope, and screen metrics.',
            icon: Icons.screen_rotation_rounded,
            badgeColor: const Color(0xFF64748B),
            tags: ['Sensors', 'Completed'],
            isComingSoon: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Activity 1 Module is archived in compilation.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required String activityNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color badgeColor,
    required List<String> tags,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isComingSoon ? Colors.grey.shade200 : badgeColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      activityNumber,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: badgeColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tags.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
