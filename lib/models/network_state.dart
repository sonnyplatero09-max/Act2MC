import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkInterfaceType {
  wifi,
  cellular,
  ethernet,
  vpn,
  bluetooth,
  offline,
  other,
}

class NetworkState {
  final NetworkInterfaceType interfaceType;
  final String label;
  final bool isConnected;
  final bool isMetered;
  final String ipAddress;
  final DateTime timestamp;
  final int latencyMs;

  const NetworkState({
    required this.interfaceType,
    required this.label,
    required this.isConnected,
    required this.isMetered,
    required this.ipAddress,
    required this.timestamp,
    this.latencyMs = 28,
  });

  factory NetworkState.fromConnectivityResults(
    List<ConnectivityResult> results, {
    String? customIp,
  }) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return NetworkState.offline();
    }

    if (results.contains(ConnectivityResult.wifi)) {
      return NetworkState(
        interfaceType: NetworkInterfaceType.wifi,
        label: 'Wi-Fi (802.11ax)',
        isConnected: true,
        isMetered: false,
        ipAddress: customIp ?? '192.168.1.104',
        timestamp: DateTime.now(),
        latencyMs: 18,
      );
    } else if (results.contains(ConnectivityResult.mobile)) {
      return NetworkState(
        interfaceType: NetworkInterfaceType.cellular,
        label: 'Cellular (5G NR)',
        isConnected: true,
        isMetered: true,
        ipAddress: customIp ?? '10.142.77.219',
        timestamp: DateTime.now(),
        latencyMs: 64,
      );
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return NetworkState(
        interfaceType: NetworkInterfaceType.ethernet,
        label: 'Ethernet (Gigabit)',
        isConnected: true,
        isMetered: false,
        ipAddress: customIp ?? '192.168.1.50',
        timestamp: DateTime.now(),
        latencyMs: 8,
      );
    } else if (results.contains(ConnectivityResult.vpn)) {
      return NetworkState(
        interfaceType: NetworkInterfaceType.vpn,
        label: 'Secure VPN Tunnel',
        isConnected: true,
        isMetered: false,
        ipAddress: customIp ?? '10.8.0.42',
        timestamp: DateTime.now(),
        latencyMs: 45,
      );
    } else {
      return NetworkState(
        interfaceType: NetworkInterfaceType.other,
        label: 'Active Network (${results.first.name})',
        isConnected: true,
        isMetered: false,
        ipAddress: customIp ?? '172.16.0.12',
        timestamp: DateTime.now(),
        latencyMs: 35,
      );
    }
  }

  factory NetworkState.offline() {
    return NetworkState(
      interfaceType: NetworkInterfaceType.offline,
      label: 'Disconnected (Offline)',
      isConnected: false,
      isMetered: false,
      ipAddress: '0.0.0.0',
      timestamp: DateTime.now(),
      latencyMs: 0,
    );
  }

  factory NetworkState.simulated({
    required NetworkInterfaceType type,
    String? label,
    String? ip,
    int? latency,
  }) {
    switch (type) {
      case NetworkInterfaceType.wifi:
        return NetworkState(
          interfaceType: NetworkInterfaceType.wifi,
          label: label ?? 'Wi-Fi (802.11ax - Home)',
          isConnected: true,
          isMetered: false,
          ipAddress: ip ?? '192.168.1.104',
          timestamp: DateTime.now(),
          latencyMs: latency ?? 16,
        );
      case NetworkInterfaceType.cellular:
        return NetworkState(
          interfaceType: NetworkInterfaceType.cellular,
          label: label ?? 'Cellular (5G LTE Carrier)',
          isConnected: true,
          isMetered: true,
          ipAddress: ip ?? '10.142.77.219',
          timestamp: DateTime.now(),
          latencyMs: latency ?? 72,
        );
      case NetworkInterfaceType.ethernet:
        return NetworkState(
          interfaceType: NetworkInterfaceType.ethernet,
          label: label ?? 'Ethernet LAN',
          isConnected: true,
          isMetered: false,
          ipAddress: ip ?? '192.168.1.50',
          timestamp: DateTime.now(),
          latencyMs: latency ?? 6,
        );
      case NetworkInterfaceType.vpn:
        return NetworkState(
          interfaceType: NetworkInterfaceType.vpn,
          label: label ?? 'WireGuard VPN',
          isConnected: true,
          isMetered: false,
          ipAddress: ip ?? '10.8.0.15',
          timestamp: DateTime.now(),
          latencyMs: latency ?? 48,
        );
      case NetworkInterfaceType.bluetooth:
        return NetworkState(
          interfaceType: NetworkInterfaceType.bluetooth,
          label: label ?? 'Bluetooth Tethering',
          isConnected: true,
          isMetered: true,
          ipAddress: ip ?? '192.168.44.2',
          timestamp: DateTime.now(),
          latencyMs: latency ?? 180,
        );
      case NetworkInterfaceType.offline:
      case NetworkInterfaceType.other:
        return NetworkState.offline();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkState &&
          runtimeType == other.runtimeType &&
          interfaceType == other.interfaceType &&
          isConnected == other.isConnected &&
          ipAddress == other.ipAddress;

  @override
  int get hashCode =>
      interfaceType.hashCode ^ isConnected.hashCode ^ ipAddress.hashCode;
}

