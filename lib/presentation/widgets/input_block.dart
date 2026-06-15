import 'package:flutter/material.dart';

class InputBlock extends StatelessWidget {
  final String title;
  final String hintText;
  final TextInputType? keyboardType;
  final String? initStateTitle;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final bool obscureText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final VoidCallback? onToggleObscure;
  final int? maxLength;

  const InputBlock({
    super.key,
    required this.title,
    required this.hintText,
    this.keyboardType,
    this.initStateTitle,
    this.validator,
    this.onSaved,
    this.obscureText = false,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.onToggleObscure,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 8),
        TextFormField(
          initialValue: initStateTitle,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            errorStyle: TextStyle(fontSize: 13),
            counterText: maxLength != null ? '' : null,
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
          ),
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,

          onSaved: onSaved,
        ),
      ],
    );
  }
}
