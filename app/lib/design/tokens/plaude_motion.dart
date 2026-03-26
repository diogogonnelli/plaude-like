import 'package:flutter/animation.dart';

class PlaudeMotion {
  const PlaudeMotion._();

  static const fast = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 360);
  static const reveal = Duration(milliseconds: 520);

  static const curve = Curves.easeOutCubic;
  static const curveEmphatic = Curves.easeOutQuart;
  static const curveIn = Curves.easeInOutCubic;
}
