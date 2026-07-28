import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baber_mobile/shared/widgets/skeleton_loader.dart';

void main() {
  testWidgets('SkeletonBox renders with given width and height', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: SkeletonBox(width: 100, height: 20))),
    );

    final size = tester.getSize(find.byType(SkeletonBox));
    expect(size.width, 100);
    expect(size.height, 20);
  });

  testWidgets('SkeletonBox opacity pulses over time', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SkeletonBox(width: 100, height: 20)));

    Opacity opacityAt() => tester.widget<Opacity>(find.byType(Opacity));

    final initial = opacityAt().opacity;
    await tester.pump(const Duration(milliseconds: 500));
    final mid = opacityAt().opacity;

    expect(mid, isNot(equals(initial)));
  });

  testWidgets('ServiceSkeletonRow renders an icon block and two text lines', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ServiceSkeletonRow()));

    expect(find.byType(SkeletonBox), findsNWidgets(3));
  });
}
