import 'package:flutter/material.dart';

Widget customCard({required String title, required bool isSelected}) {
  return SizedBox(
    height: 41,
    child: IntrinsicWidth(
      child: Card(
        color: isSelected ? Color(0xFF4459D4) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
