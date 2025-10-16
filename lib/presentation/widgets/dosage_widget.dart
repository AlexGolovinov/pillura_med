import 'package:flutter/material.dart';

import '../../domain/enums/dosage_type.dart';
import 'custom_card.dart';
import 'input_block.dart';

class DosageWidget extends StatefulWidget {
  final void Function(DosageType?)? onSavedType;
  final void Function(int?)? onSavedDosage;
  DosageWidget({super.key, this.onSavedType, this.onSavedDosage});

  @override
  State<DosageWidget> createState() => _DosageWidgetState();
}

class _DosageWidgetState extends State<DosageWidget> {
  final List<DosageType> _baseDosageType = [DosageType.ml, DosageType.pill];
  DosageType? _extraDosageType; // выбранное из "другое"
  @override
  Widget build(BuildContext context) {
    final otherDosageType = DosageType.values
        .where((e) => !_baseDosageType.contains(e) && _extraDosageType != e)
        .toList();
    return FormField<DosageType>(
      initialValue: null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onSaved: widget.onSavedType,
      onReset: () {
        setState(() {
          _extraDosageType = null;
        });
      },
      validator: (value) {
        if (value == null) return 'Выберите тип дозировки';
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputBlock(
              title: 'Сколько принять',
              hintText: 'Введите количество',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите количество';
                }
                if (double.tryParse(value) == null) {
                  return 'Введите корректное число';
                }
                if (double.parse(value) <= 0) {
                  return 'Количество должно быть больше нуля';
                }
                return null;
              },
              onSaved: (value) {
                widget.onSavedDosage?.call(
                  value == null ? null : int.parse(value),
                );
              },
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._baseDosageType.map(
                  (e) => GestureDetector(
                    onTap: () {
                      state.didChange(e); // обновляем состояние FormField
                      setState(() {
                        _extraDosageType = null;
                      });
                    },
                    child: customCard(
                      title: e.label,
                      isSelected: state.value == e, // берём из FormField
                    ),
                  ),
                ),
                if (_extraDosageType != null)
                  GestureDetector(
                    onTap: () => state.didChange(_extraDosageType),
                    child: customCard(
                      title: _extraDosageType!.label,
                      isSelected: state.value == _extraDosageType,
                    ),
                  ),
                PopupMenuButton<DosageType>(
                  onSelected: (value) {
                    state.didChange(value);
                    setState(() {
                      _extraDosageType = value;
                    });
                  },
                  itemBuilder: (_) => otherDosageType
                      .map((e) => PopupMenuItem(value: e, child: Text(e.label)))
                      .toList(),
                  child: customCard(title: 'другое...', isSelected: false),
                ),
              ],
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
