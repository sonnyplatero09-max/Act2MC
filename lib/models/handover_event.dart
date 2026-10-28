import 'network_state.dart';

enum HandoverType {
  wifiToCellular,
  cellularToWifi,
  connectedToOffline,
  offlineToConnected,
  interfaceChange,
}

class HandoverEvent {
  final String id;
  final DateTime timestamp;
  final NetworkState fromState;
  final NetworkState toState;
  final HandoverType handoverType;
  final String description;
  final int affectedRequests;
  final bool isSimulation;

  HandoverEvent({
    required this.id,
    required this.timestamp,
    required this.fromState,
    required this.toState,
    required this.handoverType,
    required this.description,
    this.affectedRequests = 0,
    this.isSimulation = false,
  });

  static HandoverType determineType(
    NetworkInterfaceType from,
    NetworkInterfaceType to,
  ) {
    if (from == NetworkInterfaceType.wifi &&
        to == NetworkInterfaceType.cellular) {
      return HandoverType.wifiToCellular;
    } else if (from == NetworkInterfaceType.cellular &&
        to == NetworkInterfaceType.wifi) {
      return HandoverType.cellularToWifi;
    } else if (to == NetworkInterfaceType.offline) {
      return HandoverType.connectedToOffline;
    } else if (from == NetworkInterfaceType.offline &&
        to != NetworkInterfaceType.offline) {
      return HandoverType.offlineToConnected;
    } else {
      return HandoverType.interfaceChange;
    }
  }

  String get typeLabel {
    switch (handoverType) {
      case HandoverType.wifiToCellular:
        return 'Wi-Fi ➔ Cellular Handover';
      case HandoverType.cellularToWifi:
        return 'Cellular ➔ Wi-Fi Handover';
      case HandoverType.connectedToOffline:
        return 'Connection Dropped (Offline)';
      case HandoverType.offlineToConnected:
        return 'Connection Re-established';
      case HandoverType.interfaceChange:
        return 'Network Interface Changed';
    }
  }
}

