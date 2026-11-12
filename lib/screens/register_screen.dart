import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/common.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.register(_name.text, _email.text, _password.text);
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
            const AuthHeader(
              title: 'Тавтай морилно уу?',
              subtitle: 'Орлого, зарлага хянахад тань туслана',
            ),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Form(
                key: _form,
                child: Column(
                  children: [
                    AuthField(
                      controller: _name,
                      hint: 'Бүтэн нэрээ оруулна уу?',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Нэрээ оруулна уу'
                          : null,
                    ),
                    AuthField(
                      controller: _email,
                      hint: 'Имэйлээ оруулна уу?',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Зөв имэйл хаяг оруулна уу'
                          : null,
                    ),
                    AuthField(
                      controller: _password,
                      hint: 'Нууц үгээ оруулаарай',
                      obscure: true,
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Нууц үг дор хаяж 6 тэмдэгт байна'
                          : null,
                    ),
                    AuthField(
                      controller: _confirm,
                      hint: 'Нууц үгээ давтан оруулаарай',
                      obscure: true,
                      validator: (v) => v != _password.text
                          ? 'Нууц үг таарахгүй байна'
                          : null,
                    ),
                    const SizedBox(height: 36),
                    AuthButton(
                      label: 'Бүртгүүлэх',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Хэрэглэгчийн эрхтэй юу?',
                            style: TextStyle(fontSize: 12)),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          ),
                          child: const Text('Нэвтрэх',
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
