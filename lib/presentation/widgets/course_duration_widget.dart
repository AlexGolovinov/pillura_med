import 'package:flutter/material.dart';
import 'package:pillura_med/domain/entities/course_duration.dart';

import '../../domain/enums/course_duration_unit.dart';
import 'custom_card.dart';

class CourseDurationWidget extends StatefulWidget {
  final String title;
  final bool withBreak;
  final void Function(CourseDuration?)? onSaved;
  const CourseDurationWidget({
    super.key,
    required this.title,
    this.onSaved,
    required this.withBreak,
  });

  @override
  State<CourseDurationWidget> createState() => _CourseDurationWidgetState();
}

class _CourseDurationWidgetState extends State<CourseDurationWidget> {
  final List<CourseDurationUnit> _courseDuration = CourseDurationUnit.values;
  CourseDurationUnit _selectedCourseDuration = CourseDurationUnit.day;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<CourseDuration?>(
      onSaved: widget.onSaved,
      validator: (value) {
        if (widget.withBreak && value == null) {
          return 'Введите ${widget.title.toLowerCase()}';
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 8),
          SizedBox(
            height: 41,
            child: TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: 'Введите количество'),
              onChanged: (value) {
                final int? count = value.isEmpty ? null : int.tryParse(value);
                field.didChange(
                  count == null
                      ? null
                      : CourseDuration(
                          count: count,
                          unit: _selectedCourseDuration,
                        ),
                );
              },
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _courseDuration
                .map(
                  (e) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCourseDuration = e;
                      });
                      final int? count = _controller.text.isEmpty
                          ? null
                          : int.tryParse(_controller.text);

                      field.didChange(
                        count == null
                            ? null
                            : CourseDuration(
                                count: count,
                                unit: _selectedCourseDuration,
                              ),
                      );
                    },
                    child: customCard(
                      title: e.label,
                      isSelected: _selectedCourseDuration == e,
                    ),
                  ),
                )
                .toList(),
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16),
              child: Text(
                field.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
