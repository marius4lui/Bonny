import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/bonny_app.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final appState = AppState();
  await appState.initialize();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    appState.logError(
      details.exception,
      details.stack ?? StackTrace.current,
      context: 'Flutter framework error',
      data: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    appState.logError(error, stackTrace, context: 'Platform dispatcher error');
    return false;
  };

  runZonedGuarded(() => runApp(BonnyApp(appState: appState)), (
    error,
    stackTrace,
  ) {
    appState.logError(error, stackTrace, context: 'Uncaught zone error');
  });
}
