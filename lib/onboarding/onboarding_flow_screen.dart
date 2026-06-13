import 'package:flutter/material.dart';

import '../app/bonny_app.dart';
import 'onboarding_step.dart';
import 'screens/onboarding_api_setup_screen.dart';
import 'screens/onboarding_exclusion_rules_screen.dart';
import 'screens/onboarding_features_screen.dart';
import 'screens/onboarding_privacy_screen.dart';
import 'screens/onboarding_ready_screen.dart';
import 'screens/onboarding_review_retry_screen.dart';
import 'screens/onboarding_scanning_screen.dart';
import 'screens/onboarding_welcome_screen.dart';
import 'widgets/api_key_setup_card.dart';
import 'widgets/onboarding_footer.dart';
import 'widgets/onboarding_scaffold.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({
    super.key,
    this.replay = false,
    this.initialStep,
  });

  final bool replay;
  final OnboardingStep? initialStep;

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  static const _steps = OnboardingStep.values;
  static const _defaultKeywords = [
    'Fanta',
    'Cola',
    'Chips',
    'Energy',
    'Red Bull',
    'Monster',
    'Süßigkeiten',
    'Schokolade',
    'Haribo',
  ];

  late final PageController _pageController;
  late int _index;
  late List<String> _keywords;
  final _apiKey = TextEditingController();
  bool _initialized = false;
  ApiSetupStatus _apiStatus = ApiSetupStatus.notConfigured;
  bool _obscureApiKey = true;
  String? _apiError;
  String? _apiWarning;

  OnboardingStep get _step => _steps[_index];

  @override
  void initState() {
    super.initState();
    _index = 0;
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final app = AppStateScope.of(context);
    final resumeStep =
        widget.initialStep ??
        (widget.replay ? OnboardingStep.welcome : app.onboardingState.step);
    _index = _steps.indexOf(resumeStep).clamp(0, _steps.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(_index);
      }
    });
    _keywords = app.settings.initialRulesConfigured
        ? [...app.settings.excludedKeywords]
        : [..._defaultKeywords];
    if (app.hasApiKey) {
      _apiStatus = ApiSetupStatus.saved;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<bool> _handleBack() async {
    if (_index > 0) {
      await _goTo(_index - 1);
      return false;
    }
    await _confirmSkip();
    return false;
  }

  Future<void> _goTo(int index) async {
    final app = AppStateScope.of(context);
    setState(() => _index = index);
    await app.saveOnboardingStep(_steps[index]);
    if (!mounted) return;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 420);
    await _pageController.animateToPage(
      index,
      duration: duration,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _continue() async {
    final app = AppStateScope.of(context);
    await app.completeOnboardingStep(_step);
    if (_step == OnboardingStep.exclusionRules) {
      await app.saveInitialExclusionRules(_keywords);
    }
    if (_step == OnboardingStep.ready) {
      await _finish();
      return;
    }
    await _goTo(_index + 1);
  }

  Future<void> _finish() async {
    final app = AppStateScope.of(context);
    await app.completeOnboarding();
    if (!mounted) return;
    if (widget.replay) {
      Navigator.of(context).pop();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ready to scan your first receipt.')),
    );
  }

  Future<void> _confirmSkip() async {
    final skip = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip setup?'),
        content: const Text('You can replay onboarding anytime in Settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue setup'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
    if (skip != true || !mounted) return;
    final app = AppStateScope.of(context);
    await app.skipOnboarding();
    if (!mounted) return;
    if (widget.replay) Navigator.of(context).pop();
  }

  Future<void> _saveApiKey() async {
    final app = AppStateScope.of(context);
    final value = _apiKey.text.trim();
    setState(() {
      _apiError = null;
      _apiWarning = app.looksLikeOpenRouterKey(value)
          ? null
          : 'This does not look like an OpenRouter key.';
    });
    if (value.isEmpty) {
      setState(() => _apiError = 'Enter an API key first.');
      return;
    }
    try {
      await app.saveApiKey(value);
      if (!mounted) return;
      setState(() => _apiStatus = ApiSetupStatus.saved);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API key saved securely.')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _apiStatus = ApiSetupStatus.failed;
        _apiError = 'Could not save API key securely.';
      });
    }
  }

  Future<void> _testApiKey() async {
    final app = AppStateScope.of(context);
    final value = _apiKey.text.trim().isNotEmpty
        ? _apiKey.text.trim()
        : (app.openRouterApiKey ?? '');
    if (value.trim().isEmpty) {
      setState(() => _apiError = 'Enter and save an API key first.');
      return;
    }
    setState(() {
      _apiStatus = ApiSetupStatus.testing;
      _apiError = null;
    });
    try {
      await app.testOpenRouter(value);
      if (!mounted) return;
      setState(() => _apiStatus = ApiSetupStatus.connected);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _apiStatus = ApiSetupStatus.failed;
        _apiError =
            'Connection failed. Check your API key and internet connection.';
      });
    }
  }

  Future<void> _startDemo() async {
    final app = AppStateScope.of(context);
    await app.markDemoModeStarted();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo receipt'),
        content: const Text(
          'This preview is demo data only. Bonny will not save it unless you create a real receipt later.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _handleBack(),
      child: OnboardingScaffold(
        footer: _footer(app),
        child: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) async {
            setState(() => _index = index);
            await app.saveOnboardingStep(_steps[index]);
          },
          children: [
            OnboardingWelcomeScreen(
              onThemeToggle: () => app.saveSettings(
                app.settings.copyWith(
                  darkModeEnabled: !app.settings.darkModeEnabled,
                ),
              ),
            ),
            OnboardingFeaturesScreen(onBack: _handleBack),
            OnboardingScanningScreen(onBack: _handleBack),
            OnboardingReviewRetryScreen(onBack: _handleBack),
            OnboardingExclusionRulesScreen(
              onBack: _handleBack,
              keywords: _keywords,
              onKeywordsChanged: (value) => setState(() => _keywords = value),
            ),
            OnboardingApiSetupScreen(
              onBack: _handleBack,
              controller: _apiKey,
              status: _apiStatus,
              obscureText: _obscureApiKey,
              onToggleObscure: () {
                setState(() => _obscureApiKey = !_obscureApiKey);
              },
              onSave: _saveApiKey,
              onTest: _testApiKey,
              maskedKey: app.maskedApiKey,
              errorText: _apiError,
              warningText: _apiWarning,
            ),
            OnboardingPrivacyScreen(onBack: _handleBack),
            OnboardingReadyScreen(
              apiConfigured: app.settings.apiSetupCompleted,
              onDemo: _startDemo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(dynamic app) {
    if (_step == OnboardingStep.welcome) {
      return OnboardingFooter(
        primaryLabel: 'Get started',
        onPrimary: _continue,
        tertiaryLabel: 'Skip for now',
        onTertiary: _confirmSkip,
      );
    }
    if (_step == OnboardingStep.apiSetup) {
      return OnboardingFooter(
        primaryLabel: 'Continue',
        primaryEnabled: app.settings.apiSetupCompleted,
        onPrimary: _continue,
        secondaryLabel: 'Back',
        onSecondary: _handleBack,
        tertiaryLabel: 'Skip API setup',
        onTertiary: _continue,
      );
    }
    if (_step == OnboardingStep.ready) {
      return OnboardingFooter(
        primaryLabel: 'Start using Bonny',
        onPrimary: _finish,
        secondaryLabel: 'Back',
        onSecondary: _handleBack,
        tertiaryLabel: app.hasApiKey
            ? 'Scan first receipt'
            : 'Explore with demo data',
        onTertiary: app.hasApiKey ? _finish : _startDemo,
      );
    }
    return OnboardingFooter(
      primaryLabel: _step == OnboardingStep.exclusionRules
          ? 'Save rules'
          : 'Continue',
      onPrimary: _continue,
      secondaryLabel: 'Back',
      onSecondary: _handleBack,
    );
  }
}
