import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../onboarding/onboarding_flow_screen.dart';
import '../ui/screens/main_shell.dart';

class BonnyApp extends StatelessWidget {
  const BonnyApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return AppStateScope(
          notifier: appState,
          child: MaterialApp(
            title: 'Bonny',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: appState.settings.darkModeEnabled
                ? ThemeMode.dark
                : ThemeMode.light,
            home: appState.settings.onboardingCompleted
                ? const MainShell()
                : const OnboardingFlowScreen(),
          ),
        );
      },
    );
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree');
    return scope!.notifier!;
  }
}
