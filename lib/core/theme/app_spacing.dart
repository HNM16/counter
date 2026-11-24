import 'package:material_ui/material_ui.dart';

/// 4pt spacing scale used across the app for consistent rhythm.
abstract final class Space {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal page gutter.
  static const double gutter = 20;

  static const pagePadding = EdgeInsets.symmetric(horizontal: gutter);
}

abstract final class Radii {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 480);
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
}
