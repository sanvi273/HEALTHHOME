
import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Keep the app usable on small screens.
        if (width < 600) {
          return child;
        }

        // Tablet and desktop layouts.
        return ColoredBox(
          color: const Color(0xFFF5F7F9),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: width >= 1100 ? 1600 : 1200,
              ),
              child: SizedBox(
                width: double.infinity,
                height: constraints.maxHeight,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
