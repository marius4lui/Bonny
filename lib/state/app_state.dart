import 'package:flutter/material.dart';

import '../models/draft_receipt.dart';
import '../models/receipt.dart';
import '../models/receipt_import_queue.dart';
import '../models/report.dart';
import '../models/settings.dart';
import '../models/debug_log.dart';
import '../onboarding/onboarding_state.dart';
import '../onboarding/onboarding_step.dart';
import '../services/api_connection_test_service.dart';
import '../services/api_key_service.dart';
import '../services/debug_log_service.dart';
import '../services/exclusion_service.dart';
import '../services/onboarding_service.dart';
import '../services/openrouter_service.dart';
import '../services/receipt_image_service.dart';
import '../services/receipt_import_queue_service.dart';
import '../services/receipt_repository.dart';
import '../services/report_service.dart';
import '../services/retry_analysis_service.dart';
import '../services/settings_repository.dart';

class AppState extends ChangeNotifier {
  AppState()
    : debugLog = DebugLogService(),
      _receiptsRepository = ReceiptRepository(),
      _settingsRepository = SettingsRepository(),
      _openRouter = OpenRouterService(),
      _apiKeyService = const ApiKeyService(),
      _exclusion = ExclusionService(),
      _onboarding = const OnboardingService(),
      _retryAnalysis = RetryAnalysisService();

  final DebugLogService debugLog;
  late final ReceiptRepository _receiptsRepository;
  late final SettingsRepository _settingsRepository;
  late final OpenRouterService _openRouter;
  late final ApiKeyService _apiKeyService;
  late final ExclusionService _exclusion;
  late final OnboardingService _onboarding;
  late final RetryAnalysisService _retryAnalysis;
  final ReceiptImageService _imageService = ReceiptImageService();
  final ReceiptImportQueueService _queueService = ReceiptImportQueueService();
  final ReportService _reportService = ReportService();

  Settings settings = Settings.defaults();
  List<Receipt> receipts = [];
  String? openRouterApiKey;
  bool isExtracting = false;
  String? extractionError;
  ReceiptImportQueue? activeImportQueue;

  Future<void> initialize() async {
    await debugLog.open();
    _wireDebugLog();
    await _receiptsRepository.open();
    await _settingsRepository.open();
    settings = _settingsRepository.load();
    debugLog.enabled = settings.debugModeEnabled;
    openRouterApiKey = await _settingsRepository.loadApiKey();
    receipts = _receiptsRepository.all();
    await debugLog.logAppInfo({
      'settings': settings.toJson(),
      'receiptCount': receipts.length,
      'hasApiKey': hasApiKey,
      'debugEntries': debugLog.entries().length,
    });
  }

  bool get hasApiKey => openRouterApiKey?.trim().isNotEmpty == true;

  OnboardingState get onboardingState => OnboardingState.fromSettings(settings);

  String get maskedApiKey {
    return _apiKeyService.mask(
      settings.apiKeyLastFour ??
          _apiKeyService.lastFour(openRouterApiKey ?? ''),
    );
  }

  Future<void> saveSettings(Settings next) async {
    settings = next;
    debugLog.enabled = settings.debugModeEnabled;
    await _settingsRepository.save(settings);
    notifyListeners();
  }

  Future<void> saveApiKey(String apiKey) async {
    openRouterApiKey = _apiKeyService.normalize(apiKey);
    await _settingsRepository.saveApiKey(openRouterApiKey!);
    settings = _onboarding.markApiSaved(
      settings,
      _apiKeyService.lastFour(openRouterApiKey!),
    );
    await _settingsRepository.save(settings);
    await _onboarding.log(debugLog, 'api_key_saved_redacted', {
      'apiKeyLastFour': settings.apiKeyLastFour,
      'apiSetupCompleted': settings.apiSetupCompleted,
    });
    notifyListeners();
  }

  Future<void> testOpenRouter(String apiKey) async {
    try {
      await _onboarding.log(debugLog, 'api_connection_test_started', {
        'hasKey': apiKey.trim().isNotEmpty,
      });
      await ApiConnectionTestService(_openRouter).test(apiKey);
      await _onboarding.log(debugLog, 'api_connection_test_success');
    } catch (error, stackTrace) {
      await _onboarding.log(debugLog, 'api_connection_test_failed', {
        'error': error.toString(),
      });
      await debugLog.logError(
        error,
        stackTrace,
        context: 'OpenRouter connection test failed',
      );
      rethrow;
    }
  }

  bool looksLikeOpenRouterKey(String apiKey) {
    return _apiKeyService.looksLikeOpenRouterKey(apiKey);
  }

  Future<void> startOnboarding({bool reset = false}) async {
    settings = _onboarding.markStarted(settings);
    if (reset) {
      settings = settings.copyWith(
        apiSetupCompleted: hasApiKey,
        apiKeyLastFour: _apiKeyService.lastFour(openRouterApiKey ?? ''),
        firstReceiptDemoCompleted: false,
        initialRulesConfigured: false,
        hasSeenReviewExplanation: false,
        hasSeenPrivacyExplanation: false,
      );
    }
    await _settingsRepository.save(settings);
    await _onboarding.log(debugLog, 'onboarding_started', {'reset': reset});
    notifyListeners();
  }

  Future<void> saveOnboardingStep(OnboardingStep step) async {
    settings = _onboarding.markStep(settings, step);
    await _settingsRepository.save(settings);
    await _onboarding.log(debugLog, 'onboarding_step_viewed', {
      'step': step.name,
    });
    notifyListeners();
  }

  Future<void> completeOnboardingStep(OnboardingStep step) async {
    settings = _onboarding.markStep(settings, step);
    if (step == OnboardingStep.reviewRetry) {
      settings = settings.copyWith(hasSeenReviewExplanation: true);
    }
    if (step == OnboardingStep.privacy) {
      settings = settings.copyWith(hasSeenPrivacyExplanation: true);
    }
    await _settingsRepository.save(settings);
    await _onboarding.log(debugLog, 'onboarding_step_completed', {
      'step': step.name,
    });
    notifyListeners();
  }

  Future<void> skipOnboarding() async {
    settings = _onboarding.markSkipped(settings);
    await _settingsRepository.save(settings);
    await _onboarding.log(debugLog, 'onboarding_skipped');
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    settings = _onboarding.markCompleted(settings);
    await _settingsRepository.save(settings);
    await _onboarding.log(debugLog, 'onboarding_completed', {
      'apiSetupCompleted': settings.apiSetupCompleted,
      'initialRulesConfigured': settings.initialRulesConfigured,
    });
    notifyListeners();
  }

  Future<void> resetOnboardingState() async {
    settings = settings.copyWith(
      onboardingCompleted: false,
      onboardingSkipped: false,
      onboardingLastStep: OnboardingStep.welcome.name,
      clearOnboardingCompletedAt: true,
      firstReceiptDemoCompleted: false,
      initialRulesConfigured: false,
      hasSeenReviewExplanation: false,
      hasSeenPrivacyExplanation: false,
    );
    await _settingsRepository.save(settings);
    await _onboarding.log(debugLog, 'onboarding_started', {'reset': true});
    notifyListeners();
  }

  Future<void> saveInitialExclusionRules(List<String> keywords) async {
    final normalized = <String>[];
    for (final keyword in keywords) {
      final trimmed = keyword.trim();
      final exists = normalized.any(
        (entry) => entry.toLowerCase() == trimmed.toLowerCase(),
      );
      if (trimmed.isNotEmpty && !exists) normalized.add(trimmed);
    }
    settings = _onboarding.markRulesConfigured(settings, normalized);
    await _settingsRepository.save(settings);
    await _onboarding.log(debugLog, 'exclusion_rules_initialized', {
      'count': normalized.length,
      'keywords': normalized,
    });
    notifyListeners();
  }

  Future<void> markDemoModeStarted() async {
    settings = _onboarding.markDemoCompleted(settings);
    await _settingsRepository.save(settings);
    await _onboarding.log(debugLog, 'demo_mode_started');
    notifyListeners();
  }

  Future<DraftReceipt?> extractDraft(
    String imagePath, {
    Map<String, dynamic>? queueMetadata,
  }) async {
    isExtracting = true;
    extractionError = null;
    notifyListeners();

    try {
      if (queueMetadata != null) {
        await debugLog.logQueue('Queue extraction started', {
          ...queueMetadata,
          'imagePath': imagePath,
          'startedAt': DateTime.now().toIso8601String(),
        }, type: DebugLogType.queueExtraction);
      }
      final storedPath = await _imageService.persistImage(
        imagePath,
        saveImages: settings.saveImages,
      );
      final extraction = await _openRouter.extractReceipt(
        apiKey: openRouterApiKey ?? '',
        imagePath: storedPath,
        debugMetadata: {...?queueMetadata, 'imagePath': storedPath},
      );
      final preRuleJson = extraction.items
          .map((item) => item.toJson())
          .toList();
      final items = _exclusion.applyRules(
        extraction.items,
        settings.excludedKeywords,
      );
      final postRuleJson = items.map((item) => item.toJson()).toList();
      await debugLog.log(DebugLogType.extraction, 'Receipt extraction trace', {
        ...extraction.trace,
        ...?queueMetadata,
        'preRuleJson': preRuleJson,
        'postRuleJson': postRuleJson,
        'totals': {
          'preRule': _totalsJson(calculateTotals(extraction.items)),
          'postRule': _totalsJson(calculateTotals(items)),
          'receiptTotal': extraction.receiptTotal,
        },
      });
      if (queueMetadata != null) {
        await debugLog.logQueue('Queue extraction completed', {
          ...queueMetadata,
          'imagePath': storedPath,
          'status': 'success',
          'merchant': extraction.merchant,
          'receiptTotal': extraction.receiptTotal,
          'itemCount': items.length,
        }, type: DebugLogType.queueExtraction);
      }
      return DraftReceipt(
        imagePath: storedPath,
        merchant: extraction.merchant,
        purchaseDate: extraction.date,
        currency: extraction.currency,
        receiptTotal: extraction.receiptTotal,
        items: items,
        extractionId: extraction.trace['extractionId']?.toString(),
        warnings: (extraction.trace['validationWarnings'] as List? ?? [])
            .map((warning) => warning.toString())
            .toList(),
      );
    } catch (error, stackTrace) {
      extractionError = error.toString();
      if (queueMetadata != null) {
        await debugLog.logQueue('Queue extraction failed', {
          ...queueMetadata,
          'imagePath': imagePath,
          'status': 'failed',
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        }, type: DebugLogType.queueExtraction);
      }
      await debugLog.logError(
        error,
        stackTrace,
        context: 'Receipt extraction failed',
        data: {'imagePath': imagePath},
      );
      return null;
    } finally {
      isExtracting = false;
      notifyListeners();
    }
  }

  DraftReceipt manualDraft(String imagePath) {
    return DraftReceipt(
      imagePath: imagePath,
      merchant: '',
      purchaseDate: DateTime.now(),
      currency: 'EUR',
      receiptTotal: 0,
      items: const [],
    );
  }

  Future<DraftReceipt?> retryAnalysis({
    required String imagePath,
    required RetrySource source,
    DraftReceipt? oldDraft,
    String? queueId,
    int? queueIndex,
    int? queueTotal,
    String? receiptId,
    String? retryOfRequestId,
    String? retryOfExtractionId,
    String? replacedSavedReceiptId,
  }) async {
    isExtracting = true;
    extractionError = null;
    notifyListeners();
    try {
      final draft = await _retryAnalysis.retryExtraction(
        imagePath: imagePath,
        source: source,
        apiKey: openRouterApiKey ?? '',
        saveImages: settings.saveImages,
        excludedKeywords: settings.excludedKeywords,
        oldDraft: oldDraft,
        queueId: queueId,
        queueIndex: queueIndex,
        queueTotal: queueTotal,
        receiptId: receiptId,
        retryOfRequestId: retryOfRequestId,
        retryOfExtractionId: retryOfExtractionId,
        replacedSavedReceiptId: replacedSavedReceiptId,
        imageService: _imageService,
        openRouter: _openRouter,
        exclusion: _exclusion,
        debugLog: debugLog,
      );
      if (queueId != null && activeImportQueue != null) {
        activeImportQueue = _queueService.incrementRetry(
          activeImportQueue!,
          imagePath,
        );
      }
      return draft;
    } catch (error, stackTrace) {
      extractionError = error.toString();
      await debugLog.logError(
        error,
        stackTrace,
        context: 'Retry analysis failed',
        data: {
          'imagePath': imagePath,
          'source': source.name,
          'queueId': queueId,
          'queueIndex': queueIndex,
          'receiptId': receiptId,
          'retryOfRequestId': retryOfRequestId,
          'retryOfExtractionId': retryOfExtractionId,
        },
      );
      return null;
    } finally {
      isExtracting = false;
      notifyListeners();
    }
  }

  ReceiptImportQueue startReceiptQueue(List<String> imagePaths) {
    final queue = _queueService.create(imagePaths);
    activeImportQueue = queue;
    debugLog.logQueue('Multi-image selection received', {
      'count': imagePaths.length,
      'imagePaths': imagePaths,
    });
    debugLog.logQueue('Receipt import queue created', queue.toJson());
    notifyListeners();
    return queue;
  }

  ReceiptImportQueue? markQueueProcessing() {
    final queue = activeImportQueue;
    if (queue == null) return null;
    activeImportQueue = _queueService.markProcessing(queue);
    debugLog.logQueue('Queue index processing', activeImportQueue!.toJson());
    notifyListeners();
    return activeImportQueue;
  }

  ReceiptImportQueue? markQueueReviewing() {
    final queue = activeImportQueue;
    if (queue == null) return null;
    activeImportQueue = _queueService.markReviewing(queue);
    debugLog.logQueue('Queue item reviewing', activeImportQueue!.toJson());
    notifyListeners();
    return activeImportQueue;
  }

  ReceiptImportQueue? markQueueExtractionFailed() {
    final queue = activeImportQueue;
    if (queue == null) return null;
    activeImportQueue = _queueService.markFailedCurrent(queue);
    debugLog.logQueue('Queue item marked failed', activeImportQueue!.toJson());
    notifyListeners();
    return activeImportQueue;
  }

  ReceiptImportQueue? recordQueueSavedReceipt(String receiptId) {
    final queue = activeImportQueue;
    if (queue == null) return null;
    activeImportQueue = _queueService.markProcessed(queue, receiptId);
    debugLog.logQueue('Queue review confirmed', {
      ...activeImportQueue!.toJson(),
      'receiptId': receiptId,
    }, type: DebugLogType.queueReview);
    notifyListeners();
    return activeImportQueue;
  }

  ReceiptImportQueue? skipCurrentQueueReceipt() {
    final queue = activeImportQueue;
    if (queue == null) return null;
    activeImportQueue = _queueService.markSkipped(queue);
    debugLog.logQueue(
      'Queue receipt skipped',
      activeImportQueue!.toJson(),
      type: DebugLogType.queueReview,
    );
    notifyListeners();
    return activeImportQueue;
  }

  ReceiptImportQueue? advanceQueueOrComplete() {
    final queue = activeImportQueue;
    if (queue == null) return null;
    activeImportQueue = _queueService.advanceOrComplete(queue);
    debugLog.logQueue(
      activeImportQueue!.status == ReceiptImportQueueStatus.completed
          ? 'Receipt import queue completed'
          : 'Receipt import queue advanced',
      activeImportQueue!.toJson(),
    );
    notifyListeners();
    return activeImportQueue;
  }

  ReceiptImportQueue? cancelQueue() {
    final queue = activeImportQueue;
    if (queue == null) return null;
    activeImportQueue = _queueService.cancel(queue);
    debugLog.logQueue(
      'Receipt import queue cancelled',
      activeImportQueue!.toJson(),
    );
    notifyListeners();
    return activeImportQueue;
  }

  void clearQueue() {
    activeImportQueue = null;
    notifyListeners();
  }

  Map<String, dynamic>? activeQueueMetadata() {
    final queue = activeImportQueue;
    if (queue == null) return null;
    return {
      'queueId': queue.id,
      'queueIndex': queue.currentIndex,
      'queueTotal': queue.totalCount,
      'progressLabel': queue.progressLabel,
    };
  }

  List<ReceiptItem> applyExclusionRules(List<ReceiptItem> items) {
    return _exclusion.applyRules(items, settings.excludedKeywords);
  }

  Future<void> saveReceipt(Receipt receipt) async {
    try {
      await _receiptsRepository.save(receipt);
      receipts = _receiptsRepository.all();
      notifyListeners();
    } catch (error, stackTrace) {
      await debugLog.logError(
        error,
        stackTrace,
        context: 'Receipt save failed',
        data: {'receipt': receipt.toJson()},
      );
      rethrow;
    }
  }

  Future<void> deleteReceipt(String id) async {
    try {
      await _receiptsRepository.delete(id);
      receipts = _receiptsRepository.all();
      notifyListeners();
    } catch (error, stackTrace) {
      await debugLog.logError(
        error,
        stackTrace,
        context: 'Receipt delete failed',
        data: {'receiptId': id},
      );
      rethrow;
    }
  }

  MonthlyReport monthlyReport(DateTime month) {
    return _reportService.buildMonthlyReport(receipts, month);
  }

  List<DebugLogEntry> debugEntries({
    String? type,
    List<String>? types,
    String? queueId,
  }) {
    return debugLog.entries(type: type, types: types, queueId: queueId);
  }

  String exportDebugBundle() => debugLog.exportBundle();

  Future<void> clearDebugLogs() async {
    await debugLog.clear();
    notifyListeners();
  }

  Future<void> logManualEdit({
    required String action,
    required Map<String, dynamic> before,
    required Map<String, dynamic> after,
  }) async {
    await debugLog.log(DebugLogType.manualEdit, 'Receipt review $action', {
      'action': action,
      'before': before,
      'after': after,
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  Future<void> logError(
    Object error,
    StackTrace stackTrace, {
    String context = 'App error',
    Map<String, dynamic>? data,
  }) async {
    await debugLog.logError(error, stackTrace, context: context, data: data);
    notifyListeners();
  }

  void _wireDebugLog() {
    _receiptsRepository.debugLog = debugLog;
    _settingsRepository.debugLog = debugLog;
    _openRouter.debugLog = debugLog;
    _exclusion.debugLog = debugLog;
  }

  Map<String, dynamic> _totalsJson(ReceiptTotals totals) {
    return {
      'total': totals.total,
      'reimbursable': totals.reimbursable,
      'excluded': totals.excluded,
    };
  }
}
