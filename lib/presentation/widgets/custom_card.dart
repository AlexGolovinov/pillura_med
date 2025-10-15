import 'package:flutter/material.dart';

Widget customCard({required String title, required bool isSelected}) {
  return SizedBox(
    height: 41,
    child: Card(
      margin: EdgeInsets.zero,
      color: isSelected ? const Color(0xFF4459D4) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min, // ширина под содержимое
          children: [
            Text(
              title,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
