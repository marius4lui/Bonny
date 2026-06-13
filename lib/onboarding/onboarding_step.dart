enum OnboardingStep {
  welcome,
  features,
  scanning,
  reviewRetry,
  exclusionRules,
  apiSetup,
  privacy,
  ready;

  static OnboardingStep fromName(String? name) {
    return OnboardingStep.values.firstWhere(
      (step) => step.name == name,
      orElse: () => OnboardingStep.welcome,
    );
  }
}

enum OnboardingStatus { notStarted, inProgress, apiMissing, completed, skipped }
