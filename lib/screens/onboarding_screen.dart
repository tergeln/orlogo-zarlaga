import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFEEF9F5),
              child: SafeArea(
                bottom: false,
                child: Image.asset(
                  'assets/images/onboarding.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  alignment: Alignment.bottomCenter,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ухаалаг Зарцуулж\nИлүү Хэмнэе',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: PrimaryButton(
              label: 'Эхлэх',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Хэрэглэгчийн Эрх Бий Юу?',
                  style: TextStyle(fontSize: 14, color: AppColors.grey)),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Нэвтрэх',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
