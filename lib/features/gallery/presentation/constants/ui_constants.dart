import 'package:flutter/material.dart';

/// UI Constants for Gallery Feature
class UIConstants {
  // Grid Dimensions
  static const double mobileGridMaxCrossAxisExtent = 120.0;
  static const double desktopGridMaxCrossAxisExtent = 180.0;
  static const double gridMainAxisSpacing = 8.0;
  static const double gridCrossAxisSpacing = 8.0;
  static const double gridChildAspectRatio = 1.0;

  // Padding and Margins
  static const EdgeInsets gridPadding = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets sectionPadding = EdgeInsets.fromLTRB(
    24.0,
    24.0,
    24.0,
    12.0,
  );

  // Bottom Action Bar
  static const double bottomActionBarHeight = 60.0;
  static const double bottomActionBarBottomMargin = 30.0;
  static const double bottomActionBarSideMargin = 40.0;
  static const double bottomActionBarBorderRadius = 30.0;

  // Text Sizes
  static const double pinInputFontSize = 24.0;
  static const double pinInputLetterSpacing = 5.0;
  static const double sectionHeaderFontSize = 12.0;
  static const double sectionHeaderLetterSpacing = 1.5;

  // Colors
  static const Color dialogBackgroundColor = Color(0xFF1E1E1E);
  static const Color dialogSecondaryBackgroundColor = Color(0xFF202020);
  static const double glassBlurSigmaX = 10.0;
  static const double glassBlurSigmaY = 10.0;

  // PIN Validation
  static const int pinMinLength = 4;
  static const int pinMaxLength = 10;

  // Network
  static const String defaultHostname = '127.0.0.1';
  static const int networkPort = 4545;
  static const Duration networkTimeout = Duration(seconds: 3);

  // Scan Timeout
  static const Duration directoryScanTimeout = Duration(seconds: 30);

  // Footer Spacing
  static const double bottomSliverSpacing = 100.0;

  // Icon Size
  static const double navBarIconSize = 22.0;
  static const double navBarSplashRadius = 20.0;

  // Glass Effect
  static const double glassBackgroundOpacity = 0.6;
  static const double glassBlurSigma = 10.0;
  static const double glassBlurShadowOpacity = 0.5;
  static const double glassBlurShadowBlurRadius = 20.0;
}
