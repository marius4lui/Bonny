import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import '../models/settings.dart';
import 'debug_log_service.dart';

class SettingsRepository {
  SettingsRepository({this.debugLog});

  static const _boxName = 'settings';
  static const _settingsKey = 'app_settings';
  static const _apiKey = 'openrouter_api_key';

  DebugLogService? debugLog;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Box<Map>? _box;

  Future<void> open() async {
    final stopwatch = Stopwatch()..start();
    try {
      _box = await Hive.openBox<Map>(_boxName);
      await debugLog?.logStorage(
        operation: 'open',
        entity: 'settings_box',
        success: true,
        duration: stopwatch.elapsed,
      );
    } catch (error, stackTrace) {
      await debugLog?.logStorage(
        operation: 'open',
        entity: 'settings_box',
        success: false,
        duration: stopwatch.elapsed,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Settings load() {
    final stopwatch = Stopwatch()..start();
    try {
      final settings = Settings.fromJson(_box!.get(_settingsKey));
      debugLog?.logStorage(
        operation: 'read',
        entity: 'settings',
        entityId: _settingsKey,
        success: true,
        duration: stopwatch.elapsed,
        payload: settings.toJson(),
      );
      return settings;
    } catch (error, stackTrace) {
      debugLog?.logStorage(
        operation: 'read',
        entity: 'settings',
        entityId: _settingsKey,
        success: false,
        duration: stopwatch.elapsed,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> save(Settings settings) async {
    final stopwatch = Stopwatch()..start();
    final payload = settings.toJson();
    try {
      await _box!.put(_settingsKey, payload);
      await debugLog?.logStorage(
        operation: 'create_or_update',
        entity: 'settings',
        entityId: _settingsKey,
        success: true,
        duration: stopwatch.elapsed,
        payload: payload,
      );
    } catch (error, stackTrace) {
      await debugLog?.logStorage(
        operation: 'create_or_update',
        entity: 'settings',
        entityId: _settingsKey,
        success: false,
        duration: stopwatch.elapsed,
        payload: payload,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<String?> loadApiKey() async {
    final stopwatch = Stopwatch()..start();
    try {
      final value = await _secureStorage.read(key: _apiKey);
      await debugLog?.logStorage(
        operation: 'read',
        entity: 'secure_api_key',
        entityId: _apiKey,
        success: true,
        duration: stopwatch.elapsed,
        payload: {'present': value?.isNotEmpty == true},
      );
      return value;
    } catch (error, stackTrace) {
      await debugLog?.logStorage(
        operation: 'read',
        entity: 'secure_api_key',
        entityId: _apiKey,
        success: false,
        duration: stopwatch.elapsed,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> saveApiKey(String apiKey) {
    final stopwatch = Stopwatch()..start();
    return _secureStorage
        .write(key: _apiKey, value: apiKey.trim())
        .then((_) async {
          await debugLog?.logStorage(
            operation: 'create_or_update',
            entity: 'secure_api_key',
            entityId: _apiKey,
            success: true,
            duration: stopwatch.elapsed,
            payload: {'present': apiKey.trim().isNotEmpty},
          );
        })
        .catchError((Object error, StackTrace stackTrace) async {
          await debugLog?.logStorage(
            operation: 'create_or_update',
            entity: 'secure_api_key',
            entityId: _apiKey,
            success: false,
            duration: stopwatch.elapsed,
            payload: {'present': apiKey.trim().isNotEmpty},
            error: error,
            stackTrace: stackTrace,
          );
          throw error;
        });
  }
}
