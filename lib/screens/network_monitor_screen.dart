import 'package:flutter/material.dart';
import '../models/network_state.dart';
import '../models/queued_request.dart';
import '../services/network_monitor_service.dart';
import '../services/request_queue_manager.dart';

class NetworkMonitorScreen extends StatefulWidget {
  const NetworkMonitorScreen({super.key});

  @override
  State<NetworkMonitorScreen> createState() => _NetworkMonitorScreenState();
}

class _NetworkMonitorScreenState extends State<NetworkMonitorScreen>
    with SingleTickerProviderStateMixin {
  final NetworkMonitorService _monitorService = NetworkMonitorService.instance;
  final RequestQueueManager _queueManager = RequestQueueManager.instance;

  late TabController _tabController;
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  Color _getColorForInterface(NetworkInterfaceType type) {
    switch (type) {
      case NetworkInterfaceType.wifi:
        return const Color(0xFF00C853); // Bright Emerald Green
      case NetworkInterfaceType.cellular:
        return const Color(0xFF2979FF); // Electric Blue
      case NetworkInterfaceType.ethernet:
        return const Color(0xFF00B0FF); // Cyan
      case NetworkInterfaceType.vpn:
        return const Color(0xFFAA00FF); // Purple
      case NetworkInterfaceType.bluetooth:
        return const Color(0xFFFF9100); // Amber
      case NetworkInterfaceType.offline:
      case NetworkInterfaceType.other:
        return const Color(0xFFFF1744); // Vivid Red
    }
  }

  IconData _getIconForInterface(NetworkInterfaceType type) {
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

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.inProgress:
        return Colors.blue;
      case RequestStatus.pausedHandover:
        return Colors.orange.shade800;
      case RequestStatus.retrying:
        return Colors.purple;
      case RequestStatus.completed:
        return Colors.green;
      case RequestStatus.failed:
      case RequestStatus.cancelled:
        return Colors.red;
      case RequestStatus.pending:
        return Colors.grey.shade700;
    }
  }

  String _getStatusChipText(RequestStatus status) {
    switch (status) {
      case RequestStatus.inProgress:
        return 'STREAMING';
      case RequestStatus.pausedHandover:
        return 'HANDOVER PAUSED';
      case RequestStatus.retrying:
        return 'RETRYING';
      case RequestStatus.completed:
        return 'COMPLETED';
      case RequestStatus.failed:
        return 'FAILED';
      case RequestStatus.cancelled:
        return 'CANCELLED';
      case RequestStatus.pending:
        return 'QUEUED';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Monitor & Handover',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Real-time Stream Listener & Recovery Queue',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Clear Event Logs',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () {
              _monitorService.clearLogs();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Audit and handover logs cleared.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<NetworkState>(
        stream: _monitorService.networkStream,
        initialData: _monitorService.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data ?? _monitorService.currentState;
          final accentColor = _getColorForInterface(state.interfaceType);

          return Column(
            children: [
              // Real-Time Active Interface Hero Dashboard
              _buildActiveInterfaceHero(state, accentColor),

              // Interactive Handover Simulation Bar
              _buildHandoverControls(state),

              // Request Queue Metrics Strip
              _buildMetricsStrip(),

              // Tabs: Request Queue vs Handover Audit Log
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF1E293B),
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: const Color(0xFF2563EB),
                  indicatorWeight: 3,
                  tabs: [
                    Tab(
                      child: StreamBuilder<List<QueuedRequest>>(
                        stream: _queueManager.queueStream,
                        initialData: _queueManager.requests,
                        builder: (context, qSnap) {
                          final count = _queueManager.queuedCount + _queueManager.activeCount;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.queue_rounded, size: 18),
                              const SizedBox(width: 6),
                              const Text('Request Queue', style: TextStyle(fontWeight: FontWeight.bold)),
                              if (count > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_rounded, size: 18),
                          const SizedBox(width: 6),
                          const Text('Live Audit Log', style: TextStyle(fontWeight: FontWeight.bold)),
                          if (_monitorService.handoverCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade800,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_monitorService.handoverCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQueueView(),
                    _buildLogsView(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  // Active Interface Hero Widget
  Widget _buildActiveInterfaceHero(NetworkState state, Color color) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Interface Icon with pulsing colored background
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForInterface(state.interfaceType),
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),

              // Title & IP Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            state.label,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Mode badge (Live / Sim)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _monitorService.isSimulationMode
                                ? Colors.purple.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _monitorService.isSimulationMode
                                  ? Colors.purple.shade200
                                  : Colors.blue.shade200,
                            ),
                          ),
                          child: Text(
                            _monitorService.isSimulationMode ? 'SIMULATOR' : 'HARDWARE LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _monitorService.isSimulationMode
                                  ? Colors.purple.shade800
                                  : Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.isConnected
                          ? 'Active IP: ${state.ipAddress} • Latency: ~${state.latencyMs}ms'
                          : 'No active data route • Pending requests queued',
                      style: TextStyle(
                        fontSize: 13,
                        color: state.isConnected ? Colors.grey.shade700 : Colors.red.shade700,
                        fontWeight: state.isConnected ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Live Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.isConnected ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Handover Banner Notice if handover occurred
          if (_monitorService.previousState != null &&
              _monitorService.previousState!.interfaceType != state.interfaceType) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Handover detected: ${_monitorService.previousState!.label} ➔ ${state.label}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Handover Simulation & Testing Buttons
  Widget _buildHandoverControls(NetworkState currentState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: Color(0xFF475569)),
                  SizedBox(width: 6),
                  Text(
                    'Handover Simulation Controls',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              if (_monitorService.isSimulationMode)
                InkWell(
                  onTap: () {
                    _monitorService.restoreHardwareLiveMode();
                    setState(() {});
                  },
                  child: Text(
                    'Reset to Live HW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSimButton(
                  label: 'Switch to Wi-Fi',
                  icon: Icons.wifi,
                  isActive: currentState.interfaceType == NetworkInterfaceType.wifi,
                  activeColor: const Color(0xFF00C853),
                  onTap: () => _monitorService.simulateWifi(),
                ),
                const SizedBox(width: 8),
                _buildSimButton(
                  label: 'Switch to Cellular (5G)',
                  icon: Icons.signal_cellular_alt,
                  isActive: currentState.interfaceType == NetworkInterfaceType.cellular,
                  activeColor: const Color(0xFF2979FF),
                  onTap: () => _monitorService.simulateCellular(),
                ),
                const SizedBox(width: 8),
                _buildSimButton(
                  label: 'Drop Connection (Offline)',
                  icon: Icons.wifi_off_rounded,
                  isActive: currentState.interfaceType == NetworkInterfaceType.offline,
                  activeColor: const Color(0xFFFF1744),
                  onTap: () => _monitorService.simulateOffline(),
                ),
                const SizedBox(width: 8),
                _buildSimButton(
                  label: 'Quick Toggle (Wi-Fi ⇄ 5G)',
                  icon: Icons.swap_horiz_rounded,
                  isActive: false,
                  activeColor: const Color(0xFF7C3AED),
                  onTap: () => _monitorService.toggleHandoverBetweenWifiAndCellular(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.shade300,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? activeColor : const Color(0xFF475569),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? activeColor : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Real-Time Request Queue Metrics
  Widget _buildMetricsStrip() {
    return StreamBuilder<List<QueuedRequest>>(
      stream: _queueManager.queueStream,
      initialData: _queueManager.requests,
      builder: (context, snapshot) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                label: 'Active (Running)',
                value: '${_queueManager.activeCount}',
                color: Colors.blue.shade700,
                icon: Icons.sync_rounded,
              ),
              _buildVerticalDivider(),
              _buildMetricItem(
                label: 'Queued / Paused',
                value: '${_queueManager.queuedCount}',
                color: Colors.orange.shade800,
                icon: Icons.pause_circle_outline_rounded,
              ),
              _buildVerticalDivider(),
              _buildMetricItem(
                label: 'Recovered / Done',
                value: '${_queueManager.completedCount}',
                color: Colors.green.shade700,
                icon: Icons.check_circle_outline_rounded,
              ),
              _buildVerticalDivider(),
              _buildMetricItem(
                label: 'Handovers',
                value: '${_monitorService.handoverCount}',
                color: Colors.purple.shade700,
                icon: Icons.change_circle_outlined,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.grey.shade300,
    );
  }

  // Tab 1: Request Queue List View
  Widget _buildQueueView() {
    return StreamBuilder<List<QueuedRequest>>(
      stream: _queueManager.queueStream,
      initialData: _queueManager.requests,
      builder: (context, snapshot) {
        final requests = _queueManager.requests;

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_download_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'No Requests in Queue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap "Fetch Large Dataset" below to simulate continuous streaming & handover.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _queueManager.enqueueLargeDatasetFetch(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Start Large Dataset Fetch'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return _buildRequestCard(req);
          },
        );
      },
    );
  }

  // Request Card with live progress and handover status
  Widget _buildRequestCard(QueuedRequest req) {
    final statusColor = _getStatusColor(req.status);
    final isHandoverPaused = req.status == RequestStatus.pausedHandover;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isHandoverPaused ? Colors.orange.shade400 : Colors.grey.shade200,
          width: isHandoverPaused ? 1.5 : 1,
        ),
      ),
      elevation: isHandoverPaused ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Request ID & Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    req.id,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Category: ${req.category} • Size: ${req.formattedTransferredSize}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                // Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    _getStatusChipText(req.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: req.progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isHandoverPaused ? Colors.orange.shade800 : statusColor,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Progress Details Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chunks: ${req.completedChunks}/${req.totalChunks} (${req.progressPercent}%)',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                if (req.speedKbps > 0)
                  Text(
                    'Speed: ${(req.speedKbps / 1024).toStringAsFixed(2)} MB/s',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                  ),
                if (req.retryAttempts > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Text(
                      'Retries: ${req.retryAttempts}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
                    ),
                  ),
              ],
            ),

            // Handover Interception Warning Message if paused
            if (isHandoverPaused) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange.shade900),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Interrupted during network transition. Safely queued without crashing. Will auto-resume on stable interface.',
                        style: TextStyle(fontSize: 10.5, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Item actions if completed or failed
            if (req.status != RequestStatus.inProgress) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (req.status == RequestStatus.pausedHandover || req.status == RequestStatus.failed)
                    TextButton.icon(
                      onPressed: () => _queueManager.retryRequest(req.id),
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('Retry Now', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                  TextButton.icon(
                    onPressed: () => _queueManager.cancelRequest(req.id),
                    icon: const Icon(Icons.close_rounded, size: 14, color: Colors.red),
                    label: const Text('Cancel', style: TextStyle(fontSize: 11, color: Colors.red)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Tab 2: Live Handover & Audit Log View
  Widget _buildLogsView() {
    return StreamBuilder<String>(
      stream: _queueManager.auditStream,
      builder: (context, _) {
        final logs = _monitorService.eventLogs;

        if (logs.isEmpty) {
          return const Center(
            child: Text('No events recorded yet.', style: TextStyle(color: Colors.grey)),
          );
        }

        return Container(
          color: const Color(0xFF0F172A), // Dark slate console
          padding: const EdgeInsets.all(12),
          child: ListView.builder(
            controller: _logScrollController,
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final line = logs[index];
              Color textColor = Colors.white70;

              if (line.contains('Handover') || line.contains('➔')) {
                textColor = const Color(0xFFFBBF24); // Amber
              } else if (line.contains('auto-recovery') || line.contains('Completed') || line.contains('finished')) {
                textColor = const Color(0xFF4ADE80); // Bright Green
              } else if (line.contains('lost') || line.contains('Offline') || line.contains('Error') || line.contains('CAUGHT')) {
                textColor = const Color(0xFFF87171); // Light Red
              } else if (line.contains('Started') || line.contains('Resuming') || line.contains('Enqueued')) {
                textColor = const Color(0xFF60A5FA); // Light Blue
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  line,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Bottom Persistent Action Bar
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: () {
                  _queueManager.enqueueLargeDatasetFetch();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enqueued Continuous Dataset Fetch request.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_download_rounded, size: 18),
                label: const Text(
                  'Fetch Large Dataset',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: () {
                  _queueManager.enqueueBatchDatasetRequests();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added 3 batch network requests to queue.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.playlist_add_rounded, size: 18),
                label: const Text(
                  'Add Batch (3)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Clear completed requests',
              icon: const Icon(Icons.cleaning_services_rounded, color: Color(0xFF475569)),
              onPressed: () => _queueManager.clearCompleted(),
            ),
          ],
        ),
      ),
    );
  }
}