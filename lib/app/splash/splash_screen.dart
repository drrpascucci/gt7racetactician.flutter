import 'dart:async';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onReady});

  final VoidCallback onReady;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _readyTimer;

  @override
  void initState() {
    super.initState();
    _readyTimer = Timer(const Duration(seconds: 2), widget.onReady);
  }

  @override
  void dispose() {
    _readyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(100) ,
                  color: Colors.white),
              child: SizedBox(
                width: 118,
                height: 118,
                child: Image.asset('assets/images/gt7_tactician_icon.png'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'GT7 RACE TACTICIAN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Telemetry Monitor',
              style: TextStyle(color: Color(0xFF888888), fontSize: 14),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Color(0xFFE63946)),
          ],
        ),
      ),
    );
  }
}
