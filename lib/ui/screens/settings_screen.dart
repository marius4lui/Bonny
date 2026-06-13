import 'package:flutter/material.dart';

import '../../app/bonny_app.dart';
import '../../onboarding/onboarding_flow_screen.dart';
import '../../onboarding/onboarding_step.dart';
import '../../theme/app_theme.dart';
import '../components/app_header.dart';
import '../components/bonny_card.dart';
import 'debug_console_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController? _apiKey;
  final TextEditingController _keyword = TextEditingController();
  bool _testing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apiKey ??= TextEditingController();
  }

  @override
  void dispose() {
    _apiKey?.dispose();
    _keyword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final settings = app.settings;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          const AppHeader(title: 'Settings', subtitle: 'Rules and preferences'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                BonnyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'OpenRouter'),
                      const SizedBox(height: 14),
                      if (app.hasApiKey) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colors.cardTint,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.colors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: context.colors.secondaryAccent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Saved key: ${app.maskedApiKey}',
                                  style: context.text.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _apiKey,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'API Key',
                          hintText: 'Paste a new key to replace the saved one',
                          prefixIcon: Icon(Icons.key_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                await app.saveApiKey(_apiKey!.text);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('API key saved securely.'),
                                  ),
                                );
                              },
                              child: const Text('Save API Key'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _testing
                                  ? null
                                  : () => _testConnection(app),
                              child: Text(
                                _testing ? 'Testing...' : 'Test Connection',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Model: google/gemma-4-26b-a4b-it:free',
                        style: context.text.labelMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                BonnyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'Help & Onboarding'),
                      const SizedBox(height: 8),
                      Text(
                        'Replay the setup guide, revisit API setup, or reset first-launch state.',
                        style: context.text.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      _SettingsActionButton(
                        icon: Icons.replay_rounded,
                        label: 'Replay Onboarding',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const OnboardingFlowScreen(replay: true),
                          ),
                        ),
                      ),
                      _SettingsActionButton(
                        icon: Icons.route_rounded,
                        label: 'Open Setup Guide',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const OnboardingFlowScreen(replay: true),
                          ),
                        ),
                      ),
                      _SettingsActionButton(
                        icon: Icons.restart_alt_rounded,
                        label: 'Reset Onboarding State',
                        onPressed: () => _resetOnboarding(app),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                BonnyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'Exclusion Rules'),
                      const SizedBox(height: 8),
                      Text(
                        'Matching products are marked as excluded automatically.',
                        style: context.text.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final keyword in settings.excludedKeywords)
                            InputChip(
                              label: Text(keyword),
                              onDeleted: () => _removeKeyword(app, keyword),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              backgroundColor: context.colors.secondarySurface,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _keyword,
                              decoration: const InputDecoration(
                                hintText: 'Add keyword',
                                prefixIcon: Icon(Icons.block_rounded),
                              ),
                              onSubmitted: (_) => _addKeyword(app),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filled(
                            onPressed: () => _addKeyword(app),
                            icon: const Icon(Icons.add_rounded),
                            tooltip: 'Add keyword',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                BonnyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'Preferences'),
                      const SizedBox(height: 8),
                      _PreferenceSwitch(
                        title: 'Dark Mode',
                        subtitle: 'Use the premium dark interface.',
                        value: settings.darkModeEnabled,
                        onChanged: (value) => app.saveSettings(
                          settings.copyWith(darkModeEnabled: value),
                        ),
                      ),
                      _PreferenceSwitch(
                        title: 'Save original images',
                        subtitle: 'Keep a local copy with each receipt.',
                        value: settings.saveImages,
                        onChanged: (value) => app.saveSettings(
                          settings.copyWith(saveImages: value),
                        ),
                      ),
                      _PreferenceSwitch(
                        title: 'Show item frequency',
                        subtitle: 'Include top purchased items in reports.',
                        value: settings.showItemFrequency,
                        onChanged: (value) => app.saveSettings(
                          settings.copyWith(showItemFrequency: value),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                BonnyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'Debug Mode'),
                      const SizedBox(height: 8),
                      Text(
                        'Local diagnostics for requests, extraction, storage, rules, and errors.',
                        style: context.text.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      _PreferenceSwitch(
                        title: 'Enable Debug Mode',
                        subtitle:
                            'Logs stay local and are sanitized before export.',
                        value: settings.debugModeEnabled,
                        onChanged: (value) => app.saveSettings(
                          settings.copyWith(debugModeEnabled: value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DebugConsoleScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.terminal_rounded),
                          label: const Text('Open Debug Console'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const OnboardingFlowScreen(
                                    replay: true,
                                    initialStep: OnboardingStep.apiSetup,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.key_rounded),
                              label: const Text('API setup'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DebugConsoleScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.bug_report_rounded),
                              label: const Text('Debug'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection(dynamic app) async {
    setState(() => _testing = true);
    try {
      await app.testOpenRouter(_apiKey!.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OpenRouter connection works.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _resetOnboarding(dynamic app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset onboarding state?'),
        content: const Text(
          'The next app launch will open onboarding again. Your receipts and API key stay unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await app.resetOnboardingState();
  }

  void _addKeyword(dynamic app) {
    final keyword = _keyword.text.trim();
    if (keyword.isEmpty) return;
    final current = app.settings.excludedKeywords;
    final exists = current.any(
      (entry) => entry.toLowerCase() == keyword.toLowerCase(),
    );
    if (!exists) {
      app.saveSettings(
        app.settings.copyWith(excludedKeywords: [...current, keyword]),
      );
    }
    _keyword.clear();
  }

  void _removeKeyword(dynamic app, String keyword) {
    final next = app.settings.excludedKeywords
        .where((entry) => entry != keyword)
        .toList();
    app.saveSettings(app.settings.copyWith(excludedKeywords: next));
  }
}

class _SettingsActionButton extends StatelessWidget {
  const _SettingsActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.bodyLarge),
                const SizedBox(height: 3),
                Text(subtitle, style: context.text.labelMedium),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
