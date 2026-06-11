import 'package:flutter/material.dart';

/// Цвета профилей по типу связи (share / ward / свой).
abstract final class ProfileLinkColors {
  // Share — по коду (зелёная ветка)
  static const shareCardBackground = Color(0xFFEEF6D8);
  static const shareBorder = Color(0xFF5B8C3E);
  static const shareBorderSelected = Color(0xFF3D6B28);
  static const shareProfileSelectedBg = Color(0xFFE0EDCF);
  static const shareIcon = Color(0xFF5B8C3E);

  // Ward — подопечный (оранжевая ветка)
  static const wardCardBackground = Color(0xFFFFF0E5);
  static const wardBorder = Color(0xFFE8913A);
  static const wardBorderSelected = Color(0xFFC76B12);
  static const wardProfileSelectedBg = Color(0xFFFFE8CC);
  static const wardIcon = Color(0xFFE8913A);

  // Свой профиль (синяя ветка)
  static const ownBorder = Color(0xFF3F51B5);
  static const ownBorderSelected = Color(0xFF303F9F);
  static const ownProfileSelectedBg = Color(0xFFD7E4FA);
  static const ownIcon = Color(0xFF5C6BC0);
}
