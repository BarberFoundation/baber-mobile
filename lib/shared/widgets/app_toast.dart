import 'dart:async';
import 'package:flutter/material.dart';

/// Top-right toast, standing in for [ScaffoldMessenger]'s bottom SnackBar
/// (which Flutter always docks to the bottom and can't reposition).
class AppToast {
  AppToast._();

  static void show(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final snackTheme = Theme.of(context).snackBarTheme;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastCard(
        message: message,
        backgroundColor: snackTheme.backgroundColor,
        textStyle: snackTheme.contentTextStyle,
        shape: snackTheme.shape,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _ToastCard extends StatefulWidget {
  final String message;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final ShapeBorder? shape;
  final VoidCallback onDismiss;

  const _ToastCard({
    required this.message,
    required this.backgroundColor,
    required this.textStyle,
    required this.shape,
    required this.onDismiss,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), widget.onDismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      left: 0,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Padding(
              padding: const EdgeInsets.only(top: 12, right: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Material(
                  color: widget.backgroundColor,
                  shape: widget.shape,
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(widget.message, style: widget.textStyle),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
