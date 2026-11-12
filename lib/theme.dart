import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppColors {
  static const primary = Color(0xFF438883);
  static const primaryDark = Color(0xFF2F7E79);
  static const primaryLight = Color(0xFF63B5AF);
  static const button = Color(0xFF3E7C78);
  static const text = Color(0xFF222222);
  static const grey = Color(0xFF666666);
  static const lightGrey = Color(0xFFAAAAAA);
  static const income = Color(0xFF25A969);
  static const expense = Color(0xFFF95B51);
  static const tile = Color(0xFFF0F6F5);
  static const pill = Color(0xFFECF9F8);
  static const segment = Color(0xFFF4F6F6);
  static const authBg = Color(0xFFF0F0F0);
}

const headerGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF429690), Color(0xFF2A7C76)],
);

final _moneyFormat = NumberFormat('#,##0.00');
final _dateFormat = DateFormat('MMM d, yyyy');

String money(double v) => '\$ ${_moneyFormat.format(v)}';

String shortDate(DateTime d) => _dateFormat.format(d);

/// "Өнөөдөр" / "Өчигдөр" эсвэл "Jan 30, 2022".
String friendlyDate(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Өнөөдөр';
  if (diff == 1) return 'Өчигдөр';
  return shortDate(d);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.text),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
