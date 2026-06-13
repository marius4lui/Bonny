import '../models/settings.dart';
import '../onboarding/onboarding_step.dart';
import 'debug_log_service.dart';

class OnboardingService {
  const OnboardingService();

  Settings markStarted(Settings settings) {
    return settings.copyWith(
      onboardingCompleted: false,
      onboardingSkipped: false,
      onboardingLastStep: OnboardingStep.welcome.name,
      clearOnboardingCompletedAt: true,
    );
  }

  Settings markStep(Settings settings, OnboardingStep step) {
    return settings.copyWith(onboardingLastStep: step.name);
  }

  Settings markSkipped(Settings settings) {
    return settings.copyWith(
      onboardingCompleted: true,
      onboardingSkipped: true,
      onboardingCompletedAt: DateTime.now(),
    );
  }

  Settings markCompleted(Settings settings) {
    return settings.copyWith(
      onboardingCompleted: true,
      onboardingSkipped: false,
      onboardingCompletedAt: DateTime.now(),
      onboardingLastStep: OnboardingStep.ready.name,
      hasSeenReviewExplanation: true,
      hasSeenPrivacyExplanation: true,
    );
  }

  Settings markApiSaved(Settings settings, String? lastFour) {
    return settings.copyWith(
      apiSetupCompleted: lastFour?.isNotEmpty == true,
      apiKeyLastFour: lastFour,
    );
  }

  Settings markRulesConfigured(Settings settings, List<String> keywords) {
    return settings.copyWith(
      excludedKeywords: keywords,
      initialRulesConfigured: true,
    );
  }

  Settings markDemoCompleted(Settings settings) {
    return settings.copyWith(firstReceiptDemoCompleted: true);
  }

  Future<void> log(
    DebugLogService debugLog,
    String event, [
    Map<String, dynamic>? data,
  ]) {
    return debugLog.log('onboarding', event, {
      'event': event,
      'timestamp': DateTime.now().toIso8601String(),
      ...?data,
    });
  }
}
