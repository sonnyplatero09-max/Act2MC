enum RequestStatus {
  pending,
  inProgress,
  pausedHandover,
  retrying,
  completed,
  failed,
  cancelled,
}

class QueuedRequest {
  final String id;
  final String title;
  final String category;
  final int totalChunks;
  int completedChunks;
  RequestStatus status;
  final DateTime createdAt;
  DateTime updatedAt;
  int retryAttempts;
  final List<String> logs;
  final double totalSizeKb;
  double speedKbps;
  String? lastError;

  QueuedRequest({
    required this.id,
    required this.title,
    required this.category,
    required this.totalChunks,
    this.completedChunks = 0,
    this.status = RequestStatus.pending,
    required this.createdAt,
    DateTime? updatedAt,
    this.retryAttempts = 0,
    List<String>? logs,
    required this.totalSizeKb,
    this.speedKbps = 0.0,
    this.lastError,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        logs = logs ?? [];

  double get progress =>
      totalChunks == 0 ? 0.0 : (completedChunks / totalChunks).clamp(0.0, 1.0);

  int get progressPercent => (progress * 100).toInt();

  double get transferredSizeKb =>
      totalChunks == 0 ? 0.0 : totalSizeKb * progress;

  String get formattedTransferredSize {
    if (totalSizeKb >= 1024) {
      final curMb = (transferredSizeKb / 1024).toStringAsFixed(1);
      final totMb = (totalSizeKb / 1024).toStringAsFixed(1);
      return '$curMb / $totMb MB';
    } else {
      return '${transferredSizeKb.toStringAsFixed(0)} / ${totalSizeKb.toStringAsFixed(0)} KB';
    }
  }

  void addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    logs.insert(0, '[$timestamp] $message');
    if (logs.length > 50) logs.removeLast();
  }

  QueuedRequest copyWith({
    int? completedChunks,
    RequestStatus? status,
    int? retryAttempts,
    double? speedKbps,
    String? lastError,
  }) {
    return QueuedRequest(
      id: id,
      title: title,
      category: category,
      totalChunks: totalChunks,
      completedChunks: completedChunks ?? this.completedChunks,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      retryAttempts: retryAttempts ?? this.retryAttempts,
      logs: List<String>.from(logs),
      totalSizeKb: totalSizeKb,
      speedKbps: speedKbps ?? this.speedKbps,
      lastError: lastError ?? this.lastError,
    );
  }
}

