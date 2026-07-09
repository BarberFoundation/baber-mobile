import 'package:flutter/material.dart';
import 'stripe_bar.dart';

/// Standard screen header: themed AppBar with the signature stripe underneath.
class BarberAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const BarberAppBar({super.key, required this.title, this.actions, this.leading});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(4),
        child: StripeBar(),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);
}
