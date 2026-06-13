import 'package:uuid/uuid.dart';

const _queueUuid = Uuid();

enum ReceiptImportQueueStatus {
  idle,
  processing,
  reviewing,
  completed,
  cancelled,
}

class ReceiptImportQueue {
  ReceiptImportQueue({
    required this.id,
    required this.imagePaths,
    required this.currentIndex,
    required this.processedReceiptIds,
    required this.skippedImagePaths,
    required this.failedImagePaths,
    required this.retryCountsByImagePath,
    required this.startedAt,
    this.completedAt,
    required this.status,
  });

  factory ReceiptImportQueue.create(List<String> imagePaths) {
    return ReceiptImportQueue(
      id: _queueUuid.v4(),
      imagePaths: List.unmodifiable(imagePaths),
      currentIndex: 0,
      processedReceiptIds: const [],
      skippedImagePaths: const [],
      failedImagePaths: const [],
      retryCountsByImagePath: const {},
      startedAt: DateTime.now(),
      status: ReceiptImportQueueStatus.processing,
    );
  }

  final String id;
  final List<String> imagePaths;
  final int currentIndex;
  final List<String> processedReceiptIds;
  final List<String> skippedImagePaths;
  final List<String> failedImagePaths;
  final Map<String, int> retryCountsByImagePath;
  final DateTime startedAt;
  final DateTime? completedAt;
  final ReceiptImportQueueStatus status;

  int get totalCount => imagePaths.length;
  String get currentImagePath => imagePaths[currentIndex];
  bool get isMultiReceipt => totalCount > 1;
  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex >= totalCount - 1;
  String get progressLabel => 'Receipt ${currentIndex + 1} of $totalCount';
  double get progressPercent =>
      totalCount == 0 ? 0 : (currentIndex + 1) / totalCount;

  ReceiptImportQueue copyWith({
    String? id,
    List<String>? imagePaths,
    int? currentIndex,
    List<String>? processedReceiptIds,
    List<String>? skippedImagePaths,
    List<String>? failedImagePaths,
    Map<String, int>? retryCountsByImagePath,
    DateTime? startedAt,
    DateTime? completedAt,
    ReceiptImportQueueStatus? status,
  }) {
    return ReceiptImportQueue(
      id: id ?? this.id,
      imagePaths: imagePaths ?? this.imagePaths,
      currentIndex: currentIndex ?? this.currentIndex,
      processedReceiptIds: processedReceiptIds ?? this.processedReceiptIds,
      skippedImagePaths: skippedImagePaths ?? this.skippedImagePaths,
      failedImagePaths: failedImagePaths ?? this.failedImagePaths,
      retryCountsByImagePath:
          retryCountsByImagePath ?? this.retryCountsByImagePath,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePaths': imagePaths,
      'currentIndex': currentIndex,
      'totalCount': totalCount,
      'processedReceiptIds': processedReceiptIds,
      'skippedImagePaths': skippedImagePaths,
      'failedImagePaths': failedImagePaths,
      'retryCountsByImagePath': retryCountsByImagePath,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status.name,
      'progressLabel': progressLabel,
      'progressPercent': progressPercent,
    };
  }
}
