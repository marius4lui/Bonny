import '../models/receipt_import_queue.dart';

class ReceiptImportQueueService {
  ReceiptImportQueue create(List<String> imagePaths) {
    return ReceiptImportQueue.create(imagePaths);
  }

  ReceiptImportQueue markProcessing(ReceiptImportQueue queue) {
    return queue.copyWith(status: ReceiptImportQueueStatus.processing);
  }

  ReceiptImportQueue markReviewing(ReceiptImportQueue queue) {
    return queue.copyWith(status: ReceiptImportQueueStatus.reviewing);
  }

  ReceiptImportQueue markFailedCurrent(ReceiptImportQueue queue) {
    final failed = {...queue.failedImagePaths, queue.currentImagePath}.toList();
    return queue.copyWith(
      failedImagePaths: failed,
      status: ReceiptImportQueueStatus.reviewing,
    );
  }

  ReceiptImportQueue markProcessed(ReceiptImportQueue queue, String receiptId) {
    return queue.copyWith(
      processedReceiptIds: [...queue.processedReceiptIds, receiptId],
    );
  }

  ReceiptImportQueue markSkipped(ReceiptImportQueue queue) {
    return queue.copyWith(
      skippedImagePaths: [...queue.skippedImagePaths, queue.currentImagePath],
    );
  }

  ReceiptImportQueue advanceOrComplete(ReceiptImportQueue queue) {
    if (queue.isLast) {
      return queue.copyWith(
        status: ReceiptImportQueueStatus.completed,
        completedAt: DateTime.now(),
      );
    }
    return queue.copyWith(
      currentIndex: queue.currentIndex + 1,
      status: ReceiptImportQueueStatus.processing,
    );
  }

  ReceiptImportQueue cancel(ReceiptImportQueue queue) {
    return queue.copyWith(
      status: ReceiptImportQueueStatus.cancelled,
      completedAt: DateTime.now(),
    );
  }

  ReceiptImportQueue incrementRetry(
    ReceiptImportQueue queue,
    String imagePath,
  ) {
    final counts = Map<String, int>.from(queue.retryCountsByImagePath);
    counts[imagePath] = (counts[imagePath] ?? 0) + 1;
    return queue.copyWith(retryCountsByImagePath: counts);
  }
}
