import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

import 'config/app_config_service.dart';
import 'config/shared_preferences_app_config_store.dart';
import 'runtime/app_runtime_controller.dart';
import 'runtime/runtime_shell.dart';
import 'splash/splash_screen.dart';

class Gt7TelemetryApp extends StatefulWidget {
  const Gt7TelemetryApp({super.key});

  @override
  State<Gt7TelemetryApp> createState() => _Gt7TelemetryAppState();
}

class _Gt7TelemetryAppState extends State<Gt7TelemetryApp> {
  late final AppConfigService _configService;
  late final AppRuntimeController _runtimeController;
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    _configService = AppConfigService(store: SharedPreferencesAppConfigStore());
    _runtimeController = AppRuntimeController(configService: _configService);
    unawaited(_runtimeController.initialize());
  }

  @override
  void dispose() {
    _runtimeController.dispose();
    _configService.dispose();
    super.dispose();
  }

  void _onSplashReady() {
    if (!mounted) {
      return;
    }
    setState(() => _splashDone = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GT7 Telemetry',
      theme: Gt7AppTheme.light(),
      darkTheme: Gt7AppTheme.dark(),
      home: _splashDone
          ? RuntimeShell(controller: _runtimeController)
          : SplashScreen(onReady: _onSplashReady),
    );
  }
}
