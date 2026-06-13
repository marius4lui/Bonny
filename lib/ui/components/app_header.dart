import 'package:flutter/material.dart';

import '../../app/bonny_app.dart';
import '../../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.headlineLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: context.text.bodyMedium),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final isDark = app.settings.darkModeEnabled;
    return IconButton.filledTonal(
      style: IconButton.styleFrom(
        backgroundColor: context.colors.secondarySurface,
        foregroundColor: context.colors.primaryText,
        fixedSize: const Size(54, 54),
      ),
      onPressed: () {
        app.saveSettings(app.settings.copyWith(darkModeEnabled: !isDark));
      },
      icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
      tooltip: isDark ? 'Use light mode' : 'Use dark mode',
    );
  }
}
