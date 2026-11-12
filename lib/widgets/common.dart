import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/db.dart';
import '../theme.dart';
import 'motion.dart';

/// Доод цэсний идэвхтэй таб (0 нүүр, 1 статистик, 2 түрийвч, 3 профайл).
final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 40)
      ..quadraticBezierTo(
          size.width / 2, size.height + 40, size.width, size.height - 40)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Дээд талын ногоон, доошоо нумарсан толгой хэсэг.
class HeaderBackground extends StatelessWidget {
  final double height;
  const HeaderBackground({super.key, this.height = 260});

  Widget _ring(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: opacity),
            width: 22,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _HeaderClipper(),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(gradient: headerGradient),
        child: Stack(
          children: [
            Positioned(left: -40, top: -70, child: _ring(210, 0.06)),
            Positioned(left: 40, top: -30, child: _ring(130, 0.06)),
          ],
        ),
      ),
    );
  }
}

/// Хонхны товч: хүлээгдэж буй төлбөрүүдийг мэдэгдэл болгон харуулна.
class BellButton extends StatelessWidget {
  const BellButton({super.key});

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Мэдэгдэл',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Flexible(
                child: StreamBuilder<List<Bill>>(
                  stream: Db.pendingBills(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return EmptyState('Алдаа: ${snap.error}',
                          icon: Icons.error_outline);
                    }
                    if (!snap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final bills = snap.data!;
                    if (bills.isEmpty) {
                      return const EmptyState('Шинэ мэдэгдэл алга.',
                          icon: Icons.notifications_none);
                    }
                    return ListView(
                      shrinkWrap: true,
                      children: [
                        for (final b in bills)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: BrandLogo(b.name),
                            title: Text('${b.name} төлбөр хүлээгдэж байна',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            subtitle: Text(
                                '${shortDate(b.dueDate)} хүртэл · ${money(b.total)}'),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: _bell(),
    );
  }

  Widget _bell() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.notifications_none, color: Colors.white),
          Positioned(
            right: 9,
            top: 9,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFFAB7B),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Толгой хэсгийн "•••" товч: хурдан шилжих цэс.
class HeaderMoreButton extends StatelessWidget {
  const HeaderMoreButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_horiz, color: Colors.white),
      color: Colors.white,
      onSelected: (index) {
        tabIndex.value = index;
        Navigator.of(context).popUntil((r) => r.isFirst);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 0, child: Text('Нүүр хуудас')),
        PopupMenuItem(value: 1, child: Text('Статистик')),
        PopupMenuItem(value: 2, child: Text('Түрийвч')),
        PopupMenuItem(value: 3, child: Text('Профайл')),
      ],
    );
  }
}

/// Дотоод хуудсуудын нийтлэг бүтэц: ногоон толгой + дугуй булантай цагаан хэсэг.
class PageScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  final int? navIndex;
  final VoidCallback? onBack;

  const PageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.navIndex,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar:
          navIndex == null ? null : AppBottomNav(current: navIndex!),
      body: Stack(
        children: [
          const HeaderBackground(height: 260),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed:
                            onBack ?? () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.chevron_left,
                            color: Colors.white, size: 30),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Center(child: action ?? const SizedBox()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(36)),
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Доод цэс. [notch] = true үед голд нь "+" товчны ховил гарна.
class AppBottomNav extends StatelessWidget {
  final int current;
  final bool notch;
  const AppBottomNav({super.key, required this.current, this.notch = false});

  Widget _item(BuildContext context, int index, IconData icon, IconData active) {
    final selected = index == current;
    return IconButton(
      onPressed: () {
        tabIndex.value = index;
        Navigator.of(context).popUntil((r) => r.isFirst);
      },
      icon: Icon(
        selected ? active : icon,
        size: 30,
        color: selected ? AppColors.primary : AppColors.lightGrey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 16,
      shadowColor: Colors.black,
      surfaceTintColor: Colors.white,
      height: 72,
      notchMargin: 8,
      shape: notch ? const CircularNotchedRectangle() : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _item(context, 0, Icons.home_outlined, Icons.home),
          _item(context, 1, Icons.bar_chart_outlined, Icons.bar_chart),
          if (notch) const SizedBox(width: 48),
          _item(context, 2, Icons.account_balance_wallet_outlined,
              Icons.account_balance_wallet),
          _item(context, 3, Icons.person_outline, Icons.person),
        ],
      ),
    );
  }
}

/// Сүүдэртэй ногоон гол товч ("Эхлэх", "Төлөх", "Баталгаажуулах").
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: loading ? null : onPressed,
      child: Container(
        height: 60,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF69AEA9), Color(0xFF3F8782)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Хүрээтэй цагаан товч ("ИЛГЭЭХ", "ДАРААХ", "Share Receipt").
class OutlinePillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const OutlinePillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          shape: const StadiumBorder(),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Text(
                label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

/// Хоёр сонголттой шилжүүлэгч ("Картууд | Аккаунт").
class SegmentTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const SegmentTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.segment,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Гүйлгээ / төлбөрийн нэрээр таних жижиг лого.
class BrandLogo extends StatelessWidget {
  final String name;
  final double size;
  final bool circle;
  const BrandLogo(this.name, {super.key, this.size = 50, this.circle = false});

  Widget _mark() {
    final n = name.toLowerCase();
    final s = size * 0.52;
    if (n.contains('youtube')) {
      return Container(
        width: s * 1.15,
        height: s * 0.8,
        decoration: BoxDecoration(
          color: const Color(0xFFE02020),
          borderRadius: BorderRadius.circular(s * 0.22),
        ),
        child: Icon(Icons.play_arrow, color: Colors.white, size: s * 0.7),
      );
    }
    if (n.contains('upwork')) {
      return Text('Up',
          style: TextStyle(
              color: const Color(0xFF37A000),
              fontSize: s * 0.85,
              fontWeight: FontWeight.w900));
    }
    if (n.contains('paypal')) {
      return Icon(Icons.paypal, color: const Color(0xFF003087), size: s * 1.1);
    }
    if (n.contains('netflix')) {
      return Container(
        width: s * 1.1,
        height: s * 1.1,
        alignment: Alignment.center,
        decoration:
            const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
        child: Text('N',
            style: TextStyle(
                color: const Color(0xFFE50914),
                fontSize: s * 0.75,
                fontWeight: FontWeight.w900)),
      );
    }
    if (n.contains('spotify')) {
      return Container(
        width: s * 1.1,
        height: s * 1.1,
        decoration: const BoxDecoration(
            color: Color(0xFF1DB954), shape: BoxShape.circle),
        child: Icon(Icons.graphic_eq, color: Colors.white, size: s * 0.75),
      );
    }
    IconData? icon;
    if (n.contains('electric') || n.contains('цахилгаан')) icon = Icons.bolt;
    if (n.contains('rent') || n.contains('түрээс')) icon = Icons.home;
    if (n.contains('цэнэглэлт')) icon = Icons.account_balance_wallet;
    if (n.contains('шилжүүлэг') || n.contains('transfer')) icon = Icons.person;
    if (n.contains('цалин')) icon = Icons.payments;
    if (n.contains('хоол') || n.contains('хүнс')) icon = Icons.restaurant;
    if (icon != null) {
      return Icon(icon, color: AppColors.primary, size: s * 1.1);
    }
    return Text(
      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
      style: TextStyle(
          color: AppColors.primary,
          fontSize: s * 0.85,
          fontWeight: FontWeight.w700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: circle ? const Color(0xFFFAFAFA) : AppColors.tile,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(8),
      ),
      child: _mark(),
    );
  }
}

/// Гүйлгээний жагсаалтын нэг мөр.
class TransactionTile extends StatelessWidget {
  final TxModel tx;
  const TransactionTile(this.tx, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          BrandLogo(tx.title),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(friendlyDate(tx.date),
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.grey)),
              ],
            ),
          ),
          Text(
            '${tx.isIncome ? '+' : '-'} ${money(tx.amount)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: tx.isIncome ? AppColors.income : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Үнэ ........ $ 11.99" маягийн мөр.
class AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final Widget? trailing;
  const AmountRow(
    this.label,
    this.value, {
    super.key,
    this.bold = false,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 15,
                  color: bold ? AppColors.text : AppColors.grey,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                color: valueColor ?? AppColors.text,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String text;
  final IconData icon;
  const EmptyState(this.text, {super.key, this.icon = Icons.receipt_long});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.lightGrey),
          const SizedBox(height: 10),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey)),
        ],
      ),
    );
  }
}

/// Тасархай хүрээ зурагч ("+ Төлбөр нэмэх" товч).
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const DashedBorderPainter({required this.color, this.radius = 8});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
