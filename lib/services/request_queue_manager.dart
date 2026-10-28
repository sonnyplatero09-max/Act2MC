import 'dart:async';
import 'dart:math';
import '../models/network_state.dart';
import '../models/queued_request.dart';
import '../models/handover_event.dart';
import 'network_monitor_service.dart';

class NetworkHandoverException implements Exception {
  final String message;
  final NetworkInterfaceType fromInterface;
  final NetworkInterfaceType toInterface;

  NetworkHandoverException(this.message, this.fromInterface, this.toInterface);

  @override
  String toString() => 'NetworkHandoverException: $message ($fromInterface ➔ $toInterface)';
}

class RequestQueueManager {
  static final RequestQueueManager _instance = RequestQueueManager._internal();
  factory RequestQueueManager() => _instance;
  static RequestQueueManager get instance => _instance;

  RequestQueueManager._internal();

  final List<QueuedRequest> _requests = [];
  final StreamController<List<QueuedRequest>> _queueStreamController =
      StreamController<List<QueuedRequest>>.broadcast();
  final StreamController<String> _auditStreamController =
      StreamController<String>.broadcast();

  StreamSubscription<NetworkState>? _networkSubscription;
  StreamSubscription<HandoverEvent>? _handoverSubscription;

  bool _isProcessing = false;
  int _requestCounter = 100;
  final Random _random = Random();

  List<QueuedRequest> get requests => List.unmodifiable(_requests);
  Stream<List<QueuedRequest>> get queueStream => _queueStreamController.stream;
  Stream<String> get auditStream => _auditStreamController.stream;

  int get activeCount =>
      _requests.where((r) => r.status == RequestStatus.inProgress || r.status == RequestStatus.retrying).length;

  int get queuedCount =>
      _requests.where((r) => r.status == RequestStatus.pending || r.status == RequestStatus.pausedHandover).length;

  int get completedCount =>
      _requests.where((r) => r.status == RequestStatus.completed).length;

  int get failedCount =>
      _requests.where((r) => r.status == RequestStatus.failed).length;

  void initialize() {
    final monitor = NetworkMonitorService.instance;

    // Listen to network state changes
    _networkSubscription = monitor.networkStream.listen((state) {
      if (state.isConnected) {
        _logAudit('Network status restored (${state.label}). Triggering graceful auto-recovery...');
        _triggerAutoRecovery(state);
      } else {
        _logAudit('Network lost (Offline). Actively pausing running requests...');
        _pauseRunningRequestsOnDisconnect();
      }
    });

    // Listen to handover events (e.g. Wi-Fi <-> Cellular)
    _handoverSubscription = monitor.handoverStream.listen((event) {
      _handleHandoverEvent(event);
    });

    _logAudit('RequestQueueManager initialized. Queue listener active.');
  }

  void _logAudit(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final formatted = '[$time] $message';
    _auditStreamController.add(formatted);
    NetworkMonitorService.instance.addLog(formatted);
  }

  void _notifyQueueChanged() {
    _queueStreamController.add(List.unmodifiable(_requests));
  }

  // Create and enqueue a large dataset fetch request
  QueuedRequest enqueueLargeDatasetFetch({
    String? title,
    String? category,
    int? chunks,
    double? totalSizeKb,
  }) {
    _requestCounter++;
    final req = QueuedRequest(
      id: 'REQ-$_requestCounter',
      title: title ?? 'Continuous Sync: Dataset Part #$_requestCounter (Telemetry & Assets)',
      category: category ?? 'Database Sync',
      totalChunks: chunks ?? 40,
      totalSizeKb: totalSizeKb ?? (2048 + _random.nextInt(3072)).toDouble(),
      createdAt: DateTime.now(),
    );

    req.addLog('Request queued in buffer.');
    _requests.insert(0, req);
    _logAudit('Enqueued [${req.id}]: "${req.title}" (${req.formattedTransferredSize})');
    _notifyQueueChanged();

    _processQueue();
    return req;
  }

  // Enqueue a batch of requests to test queue concurrency and handover resilience
  void enqueueBatchDatasetRequests() {
    final batchTitles = [
      ('User Profile & Social Graph (JSON)', 'User Data', 25, 1200.0),
      ('Satellite Map Vector Tiles (MBTiles)', 'Map Layer', 50, 4800.0),
      ('Firmware & Security Patch (Binary)', 'System Update', 35, 3100.0),
    ];

    for (final item in batchTitles) {
      enqueueLargeDatasetFetch(
        title: item.$1,
        category: item.$2,
        chunks: item.$3,
        totalSizeKb: item.$4,
      );
    }
  }

  // Main Queue Processor
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (true) {
        final currentNet = NetworkMonitorService.instance.currentState;
        if (!currentNet.isConnected) {
          // Cannot proceed while completely offline
          break;
        }

        // Find next request to work on (priority to paused handovers, then pending)
        QueuedRequest? nextReq;
        try {
          nextReq = _requests.firstWhere(
            (r) => r.status == RequestStatus.pausedHandover || r.status == RequestStatus.pending,
          );
        } catch (_) {
          nextReq = null;
        }

        if (nextReq == null) {
          break; // Nothing left to process
        }

        await _executeRequest(nextReq);
      }
    } finally {
      _isProcessing = false;
    }
  }

  // Executes a request chunk by chunk with simulated network streaming and handover resilience
  Future<void> _executeRequest(QueuedRequest req) async {
    final wasPaused = req.status == RequestStatus.pausedHandover;
    req.status = RequestStatus.inProgress;
    req.updatedAt = DateTime.now();

    if (wasPaused) {
      req.retryAttempts++;
      req.addLog('Graceful recovery initiated on ${NetworkMonitorService.instance.currentState.label}. Resuming from chunk ${req.completedChunks}/${req.totalChunks}.');
      _logAudit('Resuming [${req.id}] at chunk ${req.completedChunks}/${req.totalChunks} after handover.');
    } else {
      req.addLog('Starting transfer via ${NetworkMonitorService.instance.currentState.label} [IP: ${NetworkMonitorService.instance.currentState.ipAddress}].');
      _logAudit('Started transfer for [${req.id}] on ${NetworkMonitorService.instance.currentState.label}.');
    }
    _notifyQueueChanged();

    // Cache current network interface for socket migration comparison
    NetworkInterfaceType activeInterface = NetworkMonitorService.instance.currentState.interfaceType;

    try {
      while (req.completedChunks < req.totalChunks) {
        final currentNet = NetworkMonitorService.instance.currentState;

        // Check if connection was lost mid-request
        if (!currentNet.isConnected) {
          throw NetworkHandoverException(
            'Connection terminated mid-stream (Host unreachable)',
            activeInterface,
            NetworkInterfaceType.offline,
          );
        }

        // Check if IP / interface changed mid-request without app restart
        if (currentNet.interfaceType != activeInterface) {
          throw NetworkHandoverException(
            'Socket broken due to IP handover (${activeInterface.name} ➔ ${currentNet.interfaceType.name})',
            activeInterface,
            currentNet.interfaceType,
          );
        }

        // Simulate chunk transfer duration based on latency & network type
        final chunkDelayMs = currentNet.interfaceType == NetworkInterfaceType.wifi ? 120 : 220;
        await Future.delayed(Duration(milliseconds: chunkDelayMs));

        req.completedChunks++;
        // Calculate simulated transfer speed
        final chunkKb = req.totalSizeKb / req.totalChunks;
        req.speedKbps = (chunkKb / (chunkDelayMs / 1000.0)).clamp(200.0, 4500.0);
        req.updatedAt = DateTime.now();

        _notifyQueueChanged();
      }

      // Completed successfully
      req.status = RequestStatus.completed;
      req.speedKbps = 0.0;
      req.updatedAt = DateTime.now();
      req.addLog('Request finished successfully (${req.totalChunks}/${req.totalChunks} chunks received).');
      _logAudit('Completed [${req.id}]: "${req.title}" successfully transferred.');
      _notifyQueueChanged();
    } on NetworkHandoverException catch (e) {
      // Intercept and prevent application crash
      req.status = RequestStatus.pausedHandover;
      req.lastError = e.message;
      req.speedKbps = 0.0;
      req.updatedAt = DateTime.now();
      req.addLog('HANDOVER CAUGHT: ${e.message}. Preserved progress at ${req.progressPercent}%. Queued for automatic resume.');
      _logAudit('Intercepted socket error on [${req.id}]: ${e.message}. Saved state at ${req.completedChunks}/${req.totalChunks}.');
      _notifyQueueChanged();
    } catch (e) {
      // Catch general errors and retry or queue
      req.status = RequestStatus.pausedHandover;
      req.lastError = e.toString();
      req.speedKbps = 0.0;
      req.updatedAt = DateTime.now();
      req.addLog('Transfer interrupted: $e. Request queued.');
      _logAudit('Unexpected error on [${req.id}]: $e. Placed in recovery queue.');
      _notifyQueueChanged();
    }
  }

  void _handleHandoverEvent(HandoverEvent event) {
    final activeReqs = _requests.where((r) => r.status == RequestStatus.inProgress).toList();
    if (activeReqs.isNotEmpty) {
      for (final req in activeReqs) {
        req.status = RequestStatus.pausedHandover;
        req.lastError = 'Handover: ${event.typeLabel}';
        req.addLog('Handover in flight (${event.fromState.label} ➔ ${event.toState.label}). Safe-queuing request.');
      }
      _logAudit('Handover event: Intercepted ${activeReqs.length} active socket(s). Safely shifted to recovery queue.');
      _notifyQueueChanged();
    }

    if (event.toState.isConnected) {
      _triggerAutoRecovery(event.toState);
    }
  }

  void _pauseRunningRequestsOnDisconnect() {
    final running = _requests.where((r) => r.status == RequestStatus.inProgress).toList();
    for (final r in running) {
      r.status = RequestStatus.pausedHandover;
      r.lastError = 'Connection lost (Offline)';
      r.speedKbps = 0.0;
      r.addLog('Connection lost. Request paused at ${r.progressPercent}% without data loss.');
    }
    if (running.isNotEmpty) {
      _logAudit('Offline event: Paused ${running.length} in-flight request(s).');
      _notifyQueueChanged();
    }
  }

  // Graceful Recovery: Debounces then resumes pending and paused tasks
  void _triggerAutoRecovery(NetworkState newState) {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!NetworkMonitorService.instance.currentState.isConnected) return;

      final pausedOrPending = _requests.where(
        (r) => r.status == RequestStatus.pausedHandover || r.status == RequestStatus.pending,
      ).toList();

      if (pausedOrPending.isNotEmpty) {
        _logAudit('Connection established (${newState.label}). Auto-resuming ${pausedOrPending.length} queued request(s)...');
        _processQueue();
      }
    });
  }

  // User Actions
  void retryRequest(String id) {
    try {
      final req = _requests.firstWhere((r) => r.id == id);
      req.status = RequestStatus.pending;
      req.addLog('Manual retry queued by user.');
      _notifyQueueChanged();
      _processQueue();
    } catch (_) {}
  }

  void cancelRequest(String id) {
    try {
      final req = _requests.firstWhere((r) => r.id == id);
      req.status = RequestStatus.cancelled;
      req.speedKbps = 0.0;
      req.addLog('Request cancelled by user.');
      _notifyQueueChanged();
    } catch (_) {}
  }

  void resumeAll() {
    for (final r in _requests) {
      if (r.status == RequestStatus.pausedHandover || r.status == RequestStatus.failed) {
        r.status = RequestStatus.pending;
        r.addLog('Resumed by user.');
      }
    }
    _notifyQueueChanged();
    _processQueue();
  }

  void pauseAll() {
    for (final r in _requests) {
      if (r.status == RequestStatus.inProgress) {
        r.status = RequestStatus.pausedHandover;
        r.speedKbps = 0.0;
        r.addLog('Paused by user.');
      }
    }
    _notifyQueueChanged();
  }

  void clearCompleted() {
    _requests.removeWhere((r) => r.status == RequestStatus.completed || r.status == RequestStatus.cancelled);
    _logAudit('Cleared completed/cancelled requests from queue.');
    _notifyQueueChanged();
  }

  void dispose() {
    _networkSubscription?.cancel();
    _handoverSubscription?.cancel();
    _queueStreamController.close();
    _auditStreamController.close();
  }
}

