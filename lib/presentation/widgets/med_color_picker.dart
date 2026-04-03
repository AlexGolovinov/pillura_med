import 'package:flutter/material.dart';

class MedicationColorPicker extends StatefulWidget {
  final int? initialColor;
  final ValueChanged<Color?> onColorSelected;

  const MedicationColorPicker({
    super.key,
    this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<MedicationColorPicker> createState() => _MedicationColorPickerState();
}

class _MedicationColorPickerState extends State<MedicationColorPicker> {
  late int? _selectedColor;
  int? _selectedIndex;

  final colors = [
    Color(0xFFFAF7A6),
    Color(0xFFE4F3AB),
    Color(0xFFE8EFFB),
    Color(0xFFDDEFFF),
    Color(0xFFD5D4FE),
    Color(0xFFF1E1FF),
    Color(0xFFE3E7FF),
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    if (widget.initialColor != null) {
      _selectedIndex = colors.indexWhere(
        (c) => c.toARGB32() == widget.initialColor!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48, // чуть больше для комфорта
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = _selectedIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedIndex = null;
                  _selectedColor = null;
                } else {
                  _selectedIndex = index;
                  _selectedColor = color.toARGB32();
                }
              });
              widget.onColorSelected(Color(_selectedColor!));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle, // круг — выглядит современнее
                border: Border.all(
                  color: isSelected ? Colors.black87 : Colors.black12,
                  width: isSelected ? 3 : 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 26,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
