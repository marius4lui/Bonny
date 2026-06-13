import '../models/settings.dart';
import 'onboarding_step.dart';

class OnboardingState {
  const OnboardingState({
    required this.status,
    required this.step,
    required this.completedAt,
    required this.apiSetupCompleted,
    required this.firstReceiptDemoCompleted,
    required this.initialRulesConfigured,
  });

  factory OnboardingState.fromSettings(Settings settings) {
    final completed = settings.onboardingCompleted;
    return OnboardingState(
      status: completed
          ? (settings.onboardingSkipped
                ? OnboardingStatus.skipped
                : settings.apiSetupCompleted
                ? OnboardingStatus.completed
                : OnboardingStatus.apiMissing)
          : OnboardingStatus.inProgress,
      step: OnboardingStep.fromName(settings.onboardingLastStep),
      completedAt: settings.onboardingCompletedAt,
      apiSetupCompleted: settings.apiSetupCompleted,
      firstReceiptDemoCompleted: settings.firstReceiptDemoCompleted,
      initialRulesConfigured: settings.initialRulesConfigured,
    );
  }

  final OnboardingStatus status;
  final OnboardingStep step;
  final DateTime? completedAt;
  final bool apiSetupCompleted;
  final bool firstReceiptDemoCompleted;
  final bool initialRulesConfigured;
}
