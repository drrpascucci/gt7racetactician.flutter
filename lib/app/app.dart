import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';

import 'config/app_config_service.dart';
import 'config/shared_preferences_app_config_store.dart';
import 'runtime/app_runtime_controller.dart';
import 'runtime/runtime_shell.dart';
import 'splash/splash_screen.dart';

class GT7RaceTactician extends StatefulWidget {
  const GT7RaceTactician({super.key});

  @override
  State<GT7RaceTactician> createState() => _GT7RaceTacticianState();
}

class _GT7RaceTacticianState extends State<GT7RaceTactician>
    with WidgetsBindingObserver {
  late final AppConfigService _configService;
  late final AppRuntimeController _runtimeController;
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _configService = AppConfigService(store: SharedPreferencesAppConfigStore());
    _runtimeController = AppRuntimeController(configService: _configService);
    unawaited(_runtimeController.initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _runtimeController.dispose();
    _configService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_splashDone) {
          // unawaited(WakelockPlus.enable());
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // unawaited(WakelockPlus.disable());
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onSplashReady() {
    if (!mounted) {
      return;
    }
    setState(() => _splashDone = true);
    //unawaited(WakelockPlus.enable());
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
