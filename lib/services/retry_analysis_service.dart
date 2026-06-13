import 'dart:io';

import 'package:uuid/uuid.dart';

import '../models/debug_log.dart';
import '../models/draft_receipt.dart';
import '../models/receipt.dart';
import 'debug_log_service.dart';
import 'exclusion_service.dart';
import 'openrouter_service.dart';
import 'receipt_image_service.dart';

enum RetrySource {
  singleReview,
  queueReview,
  failedState,
  savedReceiptDetail,
  debugRequest,
  debugExtraction,
}

extension RetrySourceName on RetrySource {
  String get debugName {
    return switch (this) {
      RetrySource.singleReview => 'single_review',
      RetrySource.queueReview => 'queue_review',
      RetrySource.failedState => 'failed_state',
      RetrySource.savedReceiptDetail => 'saved_receipt_detail',
      RetrySource.debugRequest => 'debug_request',
      RetrySource.debugExtraction => 'debug_extraction',
    };
  }
}

class RetryAnalysisService {
  static const _uuid = Uuid();

  Future<DraftReceipt> retryExtraction({
    required String imagePath,
    required RetrySource source,
    required String apiKey,
    required bool saveImages,
    required List<String> excludedKeywords,
    required ReceiptImageService imageService,
    required OpenRouterService openRouter,
    required ExclusionService exclusion,
    required DebugLogService debugLog,
    DraftReceipt? oldDraft,
    String? queueId,
    int? queueIndex,
    int? queueTotal,
    String? receiptId,
    String? retryOfRequestId,
    String? retryOfExtractionId,
    String? replacedSavedReceiptId,
  }) async {
    final retryId = _uuid.v4();
    final startedAt = DateTime.now();
    final file = File(imagePath);
    final exists = await file.exists();
    final attemptNumber = _nextAttemptNumber(
      debugLog: debugLog,
      imagePath: imagePath,
      retryOfRequestId: retryOfRequestId,
      retryOfExtractionId: retryOfExtractionId,
    );
    final base = <String, dynamic>{
      'retryId': retryId,
      'source': source.debugName,
      'imagePath': imagePath,
      'imageFileExists': exists,
      'queueId': queueId,
      'queueIndex': queueIndex,
      'queueTotal': queueTotal,
      'receiptId': receiptId,
      'retryOfRequestId': retryOfRequestId,
      'retryOfExtractionId': retryOfExtractionId,
      'retryAttemptNumber': attemptNumber,
      'startedAt': startedAt.toIso8601String(),
      'oldDraftSummary': oldDraft?.summaryJson(),
      'replacedSavedReceiptId': replacedSavedReceiptId,
      'savedReceiptUntouched': replacedSavedReceiptId != null,
    };

    await debugLog.log(DebugLogType.retry, 'Retry analysis started', {
      ...base,
      'status': 'started',
    });

    if (!exists) {
      final error = StateError(
        'Original image not found. This receipt cannot be re-analyzed.',
      );
      await debugLog.log(DebugLogType.retry, 'Retry analysis failed', {
        ...base,
        'completedAt': DateTime.now().toIso8601String(),
        'status': 'failed',
        'error': error.toString(),
        'oldDraftReplaced': false,
      });
      throw error;
    }

    try {
      final storedPath = await imageService.persistImage(
        imagePath,
        saveImages: saveImages,
      );
      final metadata = <String, dynamic>{
        'triggeredFrom': source.debugName,
        'retryId': retryId,
        'retryOfRequestId': retryOfRequestId,
        'retryOfExtractionId': retryOfExtractionId,
        'retryAttemptNumber': attemptNumber,
        'imagePath': storedPath,
        'queueId': queueId,
        'queueIndex': queueIndex,
        'queueTotal': queueTotal,
        'receiptId': receiptId,
      }..removeWhere((_, value) => value == null);

      final extraction = await openRouter.extractReceipt(
        apiKey: apiKey,
        imagePath: storedPath,
        debugMetadata: metadata,
      );
      final preRuleJson = extraction.items
          .map((item) => item.toJson())
          .toList();
      final items = exclusion.applyRules(extraction.items, excludedKeywords);
      final postRuleJson = items.map((item) => item.toJson()).toList();
      final warnings = (extraction.trace['validationWarnings'] as List? ?? [])
          .map((warning) => warning.toString())
          .toList();
      final draft = DraftReceipt(
        imagePath: storedPath,
        merchant: extraction.merchant,
        purchaseDate: extraction.date,
        currency: extraction.currency,
        receiptTotal: extraction.receiptTotal,
        items: items,
        extractionId: extraction.trace['extractionId']?.toString(),
        warnings: warnings,
      );

      await debugLog.log(DebugLogType.extraction, 'Retry extraction trace', {
        ...extraction.trace,
        ...metadata,
        'replacedDraftExtractionId': oldDraft?.extractionId,
        'replacedSavedReceiptId': replacedSavedReceiptId,
        'preRuleJson': preRuleJson,
        'postRuleJson': postRuleJson,
        'totals': {
          'preRule': _totalsJson(calculateTotals(extraction.items)),
          'postRule': _totalsJson(calculateTotals(items)),
          'receiptTotal': extraction.receiptTotal,
        },
      });

      await debugLog.log(DebugLogType.retry, 'Retry analysis completed', {
        ...base,
        'completedAt': DateTime.now().toIso8601String(),
        'status': 'success',
        'newDraftSummary': draft.summaryJson(),
        'oldDraftReplaced': true,
        'savedReceiptUntouched': replacedSavedReceiptId != null,
      });
      return draft;
    } catch (error, stackTrace) {
      await debugLog.log(DebugLogType.retry, 'Retry analysis failed', {
        ...base,
        'completedAt': DateTime.now().toIso8601String(),
        'status': 'failed',
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
        'oldDraftReplaced': false,
        'savedReceiptUntouched': replacedSavedReceiptId != null,
      });
      rethrow;
    }
  }

  int _nextAttemptNumber({
    required DebugLogService debugLog,
    required String imagePath,
    String? retryOfRequestId,
    String? retryOfExtractionId,
  }) {
    final related = debugLog.entries(type: DebugLogType.retry).where((entry) {
      final data = entry.data;
      return data['imagePath'] == imagePath ||
          data['retryOfRequestId'] == retryOfRequestId &&
              retryOfRequestId != null ||
          data['retryOfExtractionId'] == retryOfExtractionId &&
              retryOfExtractionId != null;
    });
    var maxAttempt = 0;
    for (final entry in related) {
      final attempt = entry.data['retryAttemptNumber'];
      if (attempt is num && attempt > maxAttempt) maxAttempt = attempt.toInt();
    }
    return maxAttempt + 1;
  }

  Map<String, dynamic> _totalsJson(ReceiptTotals totals) {
    return {
      'total': totals.total,
      'reimbursable': totals.reimbursable,
      'excluded': totals.excluded,
    };
  }
}
