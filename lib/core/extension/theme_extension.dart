import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  // Быстрый доступ к теме
  ThemeData get theme => Theme.of(this);

  // Быстрый доступ к текстам
  TextTheme get textTheme => theme.textTheme;

  // Быстрый доступ к цветам
  ColorScheme get colors => theme.colorScheme;

  // Быстрый доступ к основному цвету (так как ты используешь primaryColor)
  Color get primaryColor => theme.primaryColor;
}
