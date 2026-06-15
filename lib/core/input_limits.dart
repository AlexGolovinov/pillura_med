const int kPersonNameMaxLength = 50;

String? validatePersonName(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return 'Введите имя';
  if (trimmed.length > kPersonNameMaxLength) {
    return 'Не больше $kPersonNameMaxLength символов';
  }
  return null;
}
