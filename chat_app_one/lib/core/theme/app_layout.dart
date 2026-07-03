import 'package:flutter/material.dart';

class AppLayout {
  static double bubbleMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width * 0.78).clamp(220.0, 520.0);
  }

  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > 900 ? 720.0 : width;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 360 ? 12.0 : (width > 900 ? 24.0 : 16.0);
    return EdgeInsets.symmetric(horizontal: horizontal);
  }
}
