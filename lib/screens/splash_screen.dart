import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _next);
  }

  void _next() {
    if (!mounted) return;
    tabIndex.value = 0;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AuthService.user == null
            ? const OnboardingScreen()
            : const MainShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF63B5AF), Color(0xFF438883)],
          ),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Сайн уу?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 50,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
