import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthhome/responsive/responsive_wrapper.dart';

void main() {
  const widths = <double>[
    320, 360, 375, 390, 412, 430, 600, 768, 834, 1024,
    1280, 1366, 1440, 1600, 1920,
  ];

  testWidgets('responsive wrapper fits the requested viewport matrix',
      (tester) async {
    for (final width in widths) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveWrapper(
              child: SizedBox.expand(
                key: const ValueKey('responsive-content'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'width: $width');
      final contentSize = tester.getSize(
        find.byKey(const ValueKey('responsive-content')),
      );
      expect(contentSize.width, lessThanOrEqualTo(width));
      if (width <= 1400) {
        expect(contentSize.width, width);
      } else {
        expect(contentSize.width, 1400);
      }
    }

    await tester.binding.setSurfaceSize(null);
  });
}
