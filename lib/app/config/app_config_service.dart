import 'package:flutter/foundation.dart';

import 'app_config.dart';

abstract interface class AppConfigStore {
  Future<Map<String, Object?>?> read();
  Future<void> write(Map<String, Object?> data);
}

class MemoryAppConfigStore implements AppConfigStore {
  Map<String, Object?>? _data;

  @override
  Future<Map<String, Object?>?> read() async {
    return _data == null ? null : Map<String, Object?>.from(_data!);
  }

  @override
  Future<void> write(Map<String, Object?> data) async {
    _data = Map<String, Object?>.from(data);
  }
}

class AppConfigService extends ChangeNotifier {
  AppConfigService({AppConfigStore? store, AppConfig? initialConfig})
    : _store = store ?? MemoryAppConfigStore(),
      _config = initialConfig ?? const AppConfig.defaults();

  final AppConfigStore _store;
  AppConfig _config;
  bool _loaded = false;

  AppConfig get config => _config;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) {
      return;
    }

    final storedData = await _store.read();
    if (storedData != null) {
      _config = AppConfig.fromJson(storedData);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> save(AppConfig config) async {
    if (mapEquals(_config.toJson(), config.toJson())) {
      return;
    }

    _config = config.copyWith(
      manualPlaystationIp: config.normalizedManualPlaystationIp,
      clearManualPlaystationIp: config.normalizedManualPlaystationIp == null,
    );
    await _store.write(_config.toJson());
    notifyListeners();
  }

  Future<void> update(AppConfig Function(AppConfig current) transform) {
    return save(transform(_config));
  }
}
