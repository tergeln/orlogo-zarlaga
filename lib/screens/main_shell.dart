import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'add_expense_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'statistics_screen.dart';
import 'wallet_screen.dart';

/// Нэвтэрсний дараах үндсэн бүтэц: 4 таб + голын "+" товч.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: tabIndex,
      builder: (context, index, _) {
        final showFab = index < 2;
        return Scaffold(
          backgroundColor: Colors.white,
          body: IndexedStack(
            index: index,
            children: const [
              HomeScreen(),
              StatisticsScreen(),
              WalletScreen(),
              ProfileScreen(),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: showFab
              ? FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AddExpenseScreen()),
                  ),
                  child: const Icon(Icons.add, size: 30),
                )
              : null,
          bottomNavigationBar: AppBottomNav(current: index, notch: showFab),
        );
      },
    );
  }
}
