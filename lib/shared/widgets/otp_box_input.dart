import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 6-box OTP code entry: auto-advances focus as digits are typed, accepts a
/// pasted full code into any box, and hops back a box on backspace-when-empty.
class OtpBoxInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;

  const OtpBoxInput({super.key, this.length = 6, required this.onChanged});

  @override
  State<OtpBoxInput> createState() => _OtpBoxInputState();
}

class _OtpBoxInputState extends State<OtpBoxInput> {
  late final _controllers = List.generate(widget.length, (_) => TextEditingController());
  late final _focusNodes = List.generate(widget.length, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(_controllers.map((c) => c.text).join());

  void _handleChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      for (var i = 0; i < digits.length && index + i < widget.length; i++) {
        _controllers[index + i].text = digits[i];
      }
      final nextIndex = (index + digits.length).clamp(0, widget.length - 1);
      _focusNodes[nextIndex].requestFocus();
    } else {
      if (_controllers[index].text != digits) _controllers[index].text = digits;
      if (digits.isNotEmpty && index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    }
    _emit();
  }

  KeyEventResult _handleBackspace(int index, KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (_controllers[index].text.isNotEmpty || index == 0) return KeyEventResult.ignored;
    _controllers[index - 1].clear();
    _focusNodes[index - 1].requestFocus();
    _emit();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        return SizedBox(
          width: 44,
          child: Focus(
            onKeyEvent: (node, event) => _handleBackspace(i, event),
            child: TextField(
              key: ValueKey('otp-box-$i'),
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: const InputDecoration(counterText: '', border: OutlineInputBorder()),
              onChanged: (value) => _handleChanged(i, value),
            ),
          ),
        );
      }),
    );
  }
}

