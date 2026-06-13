class Settings {
  const Settings({
    required this.excludedKeywords,
    required this.darkModeEnabled,
    required this.saveImages,
    required this.showItemFrequency,
    required this.debugModeEnabled,
    required this.onboardingCompleted,
    required this.onboardingCompletedAt,
    required this.onboardingSkipped,
    required this.onboardingLastStep,
    required this.apiSetupCompleted,
    required this.apiKeyLastFour,
    required this.firstReceiptDemoCompleted,
    required this.initialRulesConfigured,
    required this.hasSeenReviewExplanation,
    required this.hasSeenPrivacyExplanation,
  });

  factory Settings.defaults() {
    return const Settings(
      excludedKeywords: [
        'Fanta',
        'Cola',
        'Chips',
        'Energy',
        'Sweets',
        'Candy',
        'Haribo',
        'Red Bull',
      ],
      darkModeEnabled: false,
      saveImages: true,
      showItemFrequency: true,
      debugModeEnabled: false,
      onboardingCompleted: false,
      onboardingCompletedAt: null,
      onboardingSkipped: false,
      onboardingLastStep: 'welcome',
      apiSetupCompleted: false,
      apiKeyLastFour: null,
      firstReceiptDemoCompleted: false,
      initialRulesConfigured: false,
      hasSeenReviewExplanation: false,
      hasSeenPrivacyExplanation: false,
    );
  }

  factory Settings.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return Settings.defaults();
    return Settings(
      excludedKeywords: (json['excludedKeywords'] as List? ?? [])
          .map((keyword) => keyword.toString())
          .where((keyword) => keyword.trim().isNotEmpty)
          .toList(),
      darkModeEnabled: json['darkModeEnabled'] as bool? ?? false,
      saveImages: json['saveImages'] as bool? ?? true,
      showItemFrequency: json['showItemFrequency'] as bool? ?? true,
      debugModeEnabled: json['debugModeEnabled'] as bool? ?? false,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      onboardingCompletedAt: DateTime.tryParse(
        json['onboardingCompletedAt']?.toString() ?? '',
      ),
      onboardingSkipped: json['onboardingSkipped'] as bool? ?? false,
      onboardingLastStep: json['onboardingLastStep'] as String? ?? 'welcome',
      apiSetupCompleted: json['apiSetupCompleted'] as bool? ?? false,
      apiKeyLastFour: json['apiKeyLastFour'] as String?,
      firstReceiptDemoCompleted:
          json['firstReceiptDemoCompleted'] as bool? ?? false,
      initialRulesConfigured: json['initialRulesConfigured'] as bool? ?? false,
      hasSeenReviewExplanation:
          json['hasSeenReviewExplanation'] as bool? ?? false,
      hasSeenPrivacyExplanation:
          json['hasSeenPrivacyExplanation'] as bool? ?? false,
    );
  }

  final List<String> excludedKeywords;
  final bool darkModeEnabled;
  final bool saveImages;
  final bool showItemFrequency;
  final bool debugModeEnabled;
  final bool onboardingCompleted;
  final DateTime? onboardingCompletedAt;
  final bool onboardingSkipped;
  final String onboardingLastStep;
  final bool apiSetupCompleted;
  final String? apiKeyLastFour;
  final bool firstReceiptDemoCompleted;
  final bool initialRulesConfigured;
  final bool hasSeenReviewExplanation;
  final bool hasSeenPrivacyExplanation;

  Settings copyWith({
    List<String>? excludedKeywords,
    bool? darkModeEnabled,
    bool? saveImages,
    bool? showItemFrequency,
    bool? debugModeEnabled,
    bool? onboardingCompleted,
    DateTime? onboardingCompletedAt,
    bool clearOnboardingCompletedAt = false,
    bool? onboardingSkipped,
    String? onboardingLastStep,
    bool? apiSetupCompleted,
    String? apiKeyLastFour,
    bool clearApiKeyLastFour = false,
    bool? firstReceiptDemoCompleted,
    bool? initialRulesConfigured,
    bool? hasSeenReviewExplanation,
    bool? hasSeenPrivacyExplanation,
  }) {
    return Settings(
      excludedKeywords: excludedKeywords ?? this.excludedKeywords,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      saveImages: saveImages ?? this.saveImages,
      showItemFrequency: showItemFrequency ?? this.showItemFrequency,
      debugModeEnabled: debugModeEnabled ?? this.debugModeEnabled,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingCompletedAt: clearOnboardingCompletedAt
          ? null
          : (onboardingCompletedAt ?? this.onboardingCompletedAt),
      onboardingSkipped: onboardingSkipped ?? this.onboardingSkipped,
      onboardingLastStep: onboardingLastStep ?? this.onboardingLastStep,
      apiSetupCompleted: apiSetupCompleted ?? this.apiSetupCompleted,
      apiKeyLastFour: clearApiKeyLastFour
          ? null
          : (apiKeyLastFour ?? this.apiKeyLastFour),
      firstReceiptDemoCompleted:
          firstReceiptDemoCompleted ?? this.firstReceiptDemoCompleted,
      initialRulesConfigured:
          initialRulesConfigured ?? this.initialRulesConfigured,
      hasSeenReviewExplanation:
          hasSeenReviewExplanation ?? this.hasSeenReviewExplanation,
      hasSeenPrivacyExplanation:
          hasSeenPrivacyExplanation ?? this.hasSeenPrivacyExplanation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'excludedKeywords': excludedKeywords,
      'darkModeEnabled': darkModeEnabled,
      'saveImages': saveImages,
      'showItemFrequency': showItemFrequency,
      'debugModeEnabled': debugModeEnabled,
      'onboardingCompleted': onboardingCompleted,
      'onboardingCompletedAt': onboardingCompletedAt?.toIso8601String(),
      'onboardingSkipped': onboardingSkipped,
      'onboardingLastStep': onboardingLastStep,
      'apiSetupCompleted': apiSetupCompleted,
      'apiKeyLastFour': apiKeyLastFour,
      'firstReceiptDemoCompleted': firstReceiptDemoCompleted,
      'initialRulesConfigured': initialRulesConfigured,
      'hasSeenReviewExplanation': hasSeenReviewExplanation,
      'hasSeenPrivacyExplanation': hasSeenPrivacyExplanation,
    };
  }
}
