import 'package:flutter/material.dart';

extension TimeFormatExt on TimeOfDay {
  String get hhmm =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
