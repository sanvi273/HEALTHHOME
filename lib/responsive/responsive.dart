
import 'package:flutter/material.dart';

class Responsive {
  // Screen width
  static double width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  // Screen height
  static double height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  // Device type detection
  static bool isMobile(BuildContext context) =>
      width(context) < 600;

  static bool isTablet(BuildContext context) =>
      width(context) >= 600 && width(context) < 1100;

  static bool isDesktop(BuildContext context) =>
      width(context) >= 1100;

  // Responsive value selection
  static T value<T>(
    BuildContext context, {
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive horizontal padding
  static double horizontalPadding(BuildContext context) {
    return value(
      context,
      mobile: 16,
      tablet: 24,
      desktop: 32,
    );
  }

  // Maximum content width
  static double maxContentWidth(BuildContext context) {
    return isDesktop(context) ? 1400 : double.infinity;
  }

  // Responsive grid columns
  static int gridColumns(BuildContext context) {
    return value(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }
}
