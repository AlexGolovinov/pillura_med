enum DosageType { pill, ml, mg, drops, inhalations, injections, sprays }

extension DosageTypeLabel on DosageType {
  String get label {
    switch (this) {
      case DosageType.pill:
        return 'Таблетки';
      case DosageType.ml:
        return 'Мл';
      case DosageType.mg:
        return 'Мг';
      case DosageType.drops:
        return 'Капли';
      case DosageType.inhalations:
        return 'Ингаляции';
      case DosageType.injections:
        return 'Инъекции';
      case DosageType.sprays:
        return 'Спреи';
    }
  }
}
