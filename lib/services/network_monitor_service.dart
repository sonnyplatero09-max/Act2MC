import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/network_state.dart';
import '../models/handover_event.dart';

class NetworkMonitorService {
  static final NetworkMonitorService _instance = NetworkMonitorService._internal();
  factory NetworkMonitorService() => _instance;
  static NetworkMonitorService get instance => _instance;

  NetworkMonitorService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkState _currentState = NetworkState.offline();
  NetworkState? _previousState;
  bool _isSimulationMode = false;
  int _handoverCount = 0;

  final List<HandoverEvent> _handoverHistory = [];
  final List<String> _eventLogs = [];

  final StreamController<NetworkState> _networkStreamController =
      StreamController<NetworkState>.broadcast();
  final StreamController<HandoverEvent> _handoverStreamController =
      StreamController<HandoverEvent>.broadcast();
  final StreamController<String> _logStreamController =
      StreamController<String>.broadcast();

  // Getters
  NetworkState get currentState => _currentState;
  NetworkState? get previousState => _previousState;
  bool get isSimulationMode => _isSimulationMode;
  int get handoverCount => _handoverCount;
  List<HandoverEvent> get handoverHistory => List.unmodifiable(_handoverHistory);
  List<String> get eventLogs => List.unmodifiable(_eventLogs);

  Stream<NetworkState> get networkStream => _networkStreamController.stream;
  Stream<HandoverEvent> get handoverStream => _handoverStreamController.stream;
  Stream<String> get logStream => _logStreamController.stream;

  Future<void> initialize() async {
    addLog('NetworkMonitorService: Initializing hardware network listeners...');
    try {
      final initialResults = await _connectivity.checkConnectivity();
      _handleConnectivityChange(initialResults, isInitial: true);
    } catch (e) {
      addLog('Error reading initial connectivity: $e');
      _currentState = NetworkState.offline();
      _networkStreamController.add(_currentState);
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (!_isSimulationMode) {
        _handleConnectivityChange(results);
      }
    });
  }

  void _handleConnectivityChange(
    List<ConnectivityResult> results, {
    bool isInitial = false,
  }) {
    final newState = NetworkState.fromConnectivityResults(results);

    if (isInitial) {
      _currentState = newState;
      _networkStreamController.add(_currentState);
      addLog('Initial network state detected: ${_currentState.label} [IP: ${_currentState.ipAddress}]');
      return;
    }

    _applyStateTransition(newState, isSimulation: false);
  }

  void _applyStateTransition(NetworkState newState, {required bool isSimulation}) {
    if (_currentState == newState) return;

    _previousState = _currentState;
    _currentState = newState;

    final handoverType = HandoverEvent.determineType(
      _previousState!.interfaceType,
      _currentState.interfaceType,
    );

    final eventId = 'HO-${DateTime.now().millisecondsSinceEpoch % 100000}';
    String description;
    if (_previousState!.isConnected && !_currentState.isConnected) {
      description = 'Network connection dropped! Transferred from ${_previousState!.label} to Offline.';
    } else if (!_previousState!.isConnected && _currentState.isConnected) {
      description = 'Network recovered! Established connection via ${_currentState.label} [${_currentState.ipAddress}].';
    } else {
      description = 'IP migration & interface handover: ${_previousState!.label} ➔ ${_currentState.label} (${_previousState!.ipAddress} ➔ ${_currentState.ipAddress}).';
    }

    final handoverEvent = HandoverEvent(
      id: eventId,
      timestamp: DateTime.now(),
      fromState: _previousState!,
      toState: _currentState,
      handoverType: handoverType,
      description: description,
      isSimulation: isSimulation,
    );

    _handoverCount++;
    _handoverHistory.insert(0, handoverEvent);
    if (_handoverHistory.length > 50) _handoverHistory.removeLast();

    _networkStreamController.add(_currentState);
    _handoverStreamController.add(handoverEvent);

    final modeTag = isSimulation ? '[SIM]' : '[LIVE]';
    addLog('$modeTag Handover: ${_previousState!.label} ➔ ${_currentState.label} [IP: ${_currentState.ipAddress}]');
  }

  // Simulation Controls for Testing Handovers
  void simulateWifi() {
    _isSimulationMode = true;
    _applyStateTransition(
      NetworkState.simulated(
        type: NetworkInterfaceType.wifi,
        label: 'Wi-Fi (802.11ax - 5GHz)',
        ip: '192.168.1.104',
        latency: 14,
      ),
      isSimulation: true,
    );
  }

  void simulateCellular() {
    _isSimulationMode = true;
    _applyStateTransition(
      NetworkState.simulated(
        type: NetworkInterfaceType.cellular,
        label: 'Cellular (5G Ultra Wideband)',
        ip: '10.142.77.219',
        latency: 68,
      ),
      isSimulation: true,
    );
  }

  void simulateOffline() {
    _isSimulationMode = true;
    _applyStateTransition(
      NetworkState.simulated(
        type: NetworkInterfaceType.offline,
        label: 'Offline (No Signal / Tunnel Dropped)',
        ip: '0.0.0.0',
        latency: 0,
      ),
      isSimulation: true,
    );
  }

  void toggleHandoverBetweenWifiAndCellular() {
    _isSimulationMode = true;
    if (_currentState.interfaceType == NetworkInterfaceType.wifi) {
      simulateCellular();
    } else {
      simulateWifi();
    }
  }

  Future<void> restoreHardwareLiveMode() async {
    _isSimulationMode = false;
    addLog('[LIVE] Exited simulation mode. Synchronizing with hardware network...');
    final results = await _connectivity.checkConnectivity();
    _handleConnectivityChange(results);
  }

  void addLog(String message) {
    final timeStr = DateTime.now().toIso8601String().substring(11, 19);
    final logEntry = '[$timeStr] $message';
    _eventLogs.insert(0, logEntry);
    if (_eventLogs.length > 80) _eventLogs.removeLast();
    _logStreamController.add(logEntry);
  }

  void clearLogs() {
    _eventLogs.clear();
    _handoverHistory.clear();
    _handoverCount = 0;
    addLog('Event logs and handover history reset.');
  }

  void dispose() {
    _subscription?.cancel();
    _networkStreamController.close();
    _handoverStreamController.close();
    _logStreamController.close();
  }
}

