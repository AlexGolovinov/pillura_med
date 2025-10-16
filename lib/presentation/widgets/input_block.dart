import 'package:flutter/material.dart';

class InputBlock extends StatelessWidget {
  final String title;
  final String hintText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;

  const InputBlock({
    super.key,
    required this.title,
    required this.hintText,
    this.keyboardType,
    this.controller,
    this.validator,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            errorStyle: TextStyle(fontSize: 13),
          ),
          keyboardType: keyboardType,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,

          onSaved: onSaved,
        ),
      ],
    );
  }
}
