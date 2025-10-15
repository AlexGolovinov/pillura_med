import 'package:flutter/material.dart';

class DropdownCard<T> extends StatelessWidget {
  final List<DropdownMenuEntry<T>> items;
  final T? initialValue;
  final void Function(T?) onSelected;

  const DropdownCard({
    super.key,
    required this.items,
    this.initialValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 41,
      child: DropdownMenu<T>(
        width: double.infinity, // поле тянется на всю ширину
        initialSelection: initialValue,
        dropdownMenuEntries: items,
        onSelected: onSelected,
        menuStyle: MenuStyle(
          alignment: AlignmentDirectional.topStart, // выпадение слева
          backgroundColor: WidgetStateProperty.all(Colors.white),
          maximumSize: WidgetStateProperty.all(
            const Size.fromWidth(200), // ширина списка ограничена
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
