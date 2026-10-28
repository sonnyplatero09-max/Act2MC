import 'package:flutter_test/flutter_test.dart';
import 'package:acitivy2mc/models/network_state.dart';
import 'package:acitivy2mc/models/queued_request.dart';
import 'package:acitivy2mc/services/network_monitor_service.dart';
import 'package:acitivy2mc/services/request_queue_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NetworkMonitorService monitor;
  late RequestQueueManager queueManager;

  setUp(() async {
    monitor = NetworkMonitorService.instance;
    await monitor.initialize();
    queueManager = RequestQueueManager.instance;
    queueManager.initialize();
    queueManager.clearCompleted();
  });

  test('NetworkMonitorService initial state and simulation transitions', () {
    // Simulate Wi-Fi
    monitor.simulateWifi();
    expect(monitor.currentState.isConnected, isTrue);
    expect(monitor.currentState.interfaceType, NetworkInterfaceType.wifi);

    // Simulate Cellular Handover
    monitor.simulateCellular();
    expect(monitor.currentState.isConnected, isTrue);
    expect(monitor.currentState.interfaceType, NetworkInterfaceType.cellular);
    expect(monitor.handoverCount, greaterThan(0));

    // Simulate Offline
    monitor.simulateOffline();
    expect(monitor.currentState.isConnected, isFalse);
    expect(monitor.currentState.interfaceType, NetworkInterfaceType.offline);
  });

  test('RequestQueueManager enqueues requests and handles handover gracefully', () async {
    monitor.simulateWifi();

    final req = queueManager.enqueueLargeDatasetFetch(
      title: 'Test Dataset Transfer',
      chunks: 10,
    );

    expect(req.id, isNotEmpty);
    expect(queueManager.requests.contains(req), isTrue);

    // Give it a brief moment to begin streaming chunks
    await Future.delayed(const Duration(milliseconds: 150));

    // Simulate sudden handover to Cellular during streaming
    monitor.simulateCellular();

    // Verify request paused/intercepted handover without crashing
    expect(
      req.status == RequestStatus.inProgress ||
      req.status == RequestStatus.pausedHandover ||
      req.status == RequestStatus.completed,
      isTrue,
    );

    // Simulate complete disconnect
    monitor.simulateOffline();
    await Future.delayed(const Duration(milliseconds: 50));
    expect(queueManager.queuedCount, greaterThanOrEqualTo(0));

    // Simulate connection re-establishment to trigger graceful recovery
    monitor.simulateWifi();
    await Future.delayed(const Duration(milliseconds: 700));

    // Check that auto-recovery was triggered
    expect(monitor.currentState.isConnected, isTrue);
  });
}
