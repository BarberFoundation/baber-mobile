import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/shared/widgets/otp_box_input.dart';

void main() {
  Finder boxAt(int i) => find.byKey(ValueKey('otp-box-$i'));

  testWidgets('renders 6 boxes by default', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: OtpBoxInput(onChanged: (_) {}))));

    for (var i = 0; i < 6; i++) {
      expect(boxAt(i), findsOneWidget);
    }
  });

  testWidgets('typing a digit advances focus to the next box and reports the assembled code',
      (tester) async {
    var lastCode = '';
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: OtpBoxInput(onChanged: (code) => lastCode = code))),
    );

    for (var i = 0; i < 6; i++) {
      await tester.enterText(boxAt(i), '${i + 1}');
      await tester.pump();
    }

    expect(lastCode, '123456');
    expect(Focus.of(tester.element(boxAt(5))).hasFocus, isTrue);
  });

  testWidgets('pasting a full code into the first box fills every box', (tester) async {
    var lastCode = '';
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: OtpBoxInput(onChanged: (code) => lastCode = code))),
    );

    await tester.enterText(boxAt(0), '123456');
    await tester.pump();

    expect(lastCode, '123456');
    expect(
      tester
          .widget<EditableText>(find.descendant(of: boxAt(5), matching: find.byType(EditableText)))
          .controller
          .text,
      '6',
    );
  });

  testWidgets('backspace on an empty box moves focus to the previous box', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: OtpBoxInput(onChanged: (_) {}))));

    await tester.enterText(boxAt(0), '1');
    await tester.pump();
    // box 1 now focused and empty — backspace should hop back to box 0.
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(Focus.of(tester.element(boxAt(0))).hasFocus, isTrue);
  });
}
