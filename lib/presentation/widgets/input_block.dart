import 'package:flutter/material.dart';

class InputBlock extends StatelessWidget {
  final String title;
  final String hintText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;

  const InputBlock({
    super.key,
    required this.title,
    required this.hintText,
    this.keyboardType,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 8),
        SizedBox(
          height: 41,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hintText),
            keyboardType: keyboardType,
          ),
        ),
      ],
    );
  }
}
