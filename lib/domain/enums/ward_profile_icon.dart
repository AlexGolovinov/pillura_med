import 'package:flutter/material.dart';

enum WardProfileIcon {
  person,
  elderlyMan,
  elderlyWoman,
  pet,
  man,
  boy,
  woman,
  girl,
  
}

extension WardProfileIconX on WardProfileIcon {
  IconData get iconData {
    switch (this) {
      case WardProfileIcon.person:
        return Icons.person_outline_rounded;
      case WardProfileIcon.elderlyMan:
        return Icons.elderly;
      case WardProfileIcon.elderlyWoman:
        return Icons.elderly_woman;
      case WardProfileIcon.pet:
        return Icons.pets_outlined;
      case WardProfileIcon.man:
        return Icons.man_outlined;
      case WardProfileIcon.woman:
        return Icons.woman_outlined;
      case WardProfileIcon.girl:
        return Icons.girl_outlined;
      case WardProfileIcon.boy:
        return Icons.boy_outlined;
    }
  }

  static WardProfileIcon fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return WardProfileIcon.person;
    }
    return WardProfileIcon.values.firstWhere(
      (icon) => icon.name == value,
      orElse: () => WardProfileIcon.person,
    );
  }
}
