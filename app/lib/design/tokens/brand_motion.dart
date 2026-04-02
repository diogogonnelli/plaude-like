import 'package:flutter/animation.dart';

class BrandMotion {
  const BrandMotion._();

  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 520);

  static const standardCurve = Curves.easeOutCubic;
  static const emphasizedCurve = Curves.easeInOutCubic;
}
