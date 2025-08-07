import 'package:flutter/material.dart';

/// Helper class for responsive design breakpoints and utilities
/// Based on Tailwind CSS breakpoints for consistency
class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 992;
  
  static bool isMobile(BuildContext context) => 
    MediaQuery.of(context).size.width < mobileBreakpoint;
    
  static bool isTablet(BuildContext context) => 
    MediaQuery.of(context).size.width >= mobileBreakpoint && 
    MediaQuery.of(context).size.width < tabletBreakpoint;
    
  static bool isDesktop(BuildContext context) => 
    MediaQuery.of(context).size.width >= tabletBreakpoint;

  // Get appropriate padding based on screen size
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 80);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 40);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16);
    }
  }

  // Get appropriate grid columns based on screen size
  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) {
      return 3;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 1;
    }
  }

  // Get appropriate font size based on screen size
  static double getResponsiveFontSize(BuildContext context, {
    double mobile = 16,
    double tablet = 18,
    double desktop = 20,
  }) {
    if (isDesktop(context)) {
      return desktop;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return mobile;
    }
  }
}
