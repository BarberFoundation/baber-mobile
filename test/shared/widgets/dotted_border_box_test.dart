import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/shared/widgets/dotted_border_box.dart';

void main() {
  testWidgets('DottedBorderBox renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DottedBorderBox(child: Text('conteúdo')),
      ),
    );

    expect(find.text('conteúdo'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
