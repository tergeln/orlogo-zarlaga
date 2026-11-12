import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.login(_email.text, _password.text);
      if (!mounted) return;
      tabIndex.value = 0;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showMessage(context, AuthService.errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthHeader(title: 'Тавтай морилно уу !'),
            const SizedBox(height: 4),
            Image.asset(
              'assets/images/login.png',
              width: MediaQuery.of(context).size.width * 0.66,
              filterQuality: FilterQuality.medium,
            ),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Form(
                key: _form,
                child: Column(
                  children: [
                    AuthField(
                      controller: _email,
                      hint: 'Enter your email address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Зөв имэйл хаяг оруулна уу'
                          : null,
                    ),
                    AuthField(
                      controller: _password,
                      hint: 'Enter your password',
                      obscure: true,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Нууц үгээ оруулна уу'
                          : null,
                    ),
                    const SizedBox(height: 30),
                    AuthButton(
                      label: 'Нэвтрэх',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Text('Бүртгэлгүй юу?',
                              style: TextStyle(fontSize: 16)),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                          child: const Text('Бүртгүүлэх',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    SizedBox(
                        height: 24 + MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
