import 'package:flutter/material.dart';

import '../theme.dart';

/// Бүртгэл / Нэвтрэх дэлгэцийн дээд талын зууван ногоон толгой.
class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const AuthHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: -width * 0.2,
              right: -width * 0.2,
              top: -250,
              height: 500,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: headerGradient,
                  borderRadius:
                      BorderRadius.all(Radius.elliptical(400, 250)),
                ),
              ),
            ),
            Positioned(
              left: -70,
              top: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: const BoxDecoration(
                  color: Color(0xCC8FE3F0),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: -110,
              child: Container(
                width: 170,
                height: 170,
                decoration: const BoxDecoration(
                  color: Color(0xCCB5F0FF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 18),
                    Text(subtitle!,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Цагаан, дугуй булантай оролтын талбар.
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: c),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          border: border(Colors.transparent),
          enabledBorder: border(Colors.transparent),
          focusedBorder: border(AppColors.primary),
          errorBorder: border(AppColors.expense),
          focusedErrorBorder: border(AppColors.expense),
        ),
      ),
    );
  }
}

/// Бүртгэл / Нэвтрэх дэлгэцийн том ногоон товч.
class AuthButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.button,
          disabledBackgroundColor: AppColors.button,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(label,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
