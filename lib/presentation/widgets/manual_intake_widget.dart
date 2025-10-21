import 'package:flutter/material.dart';
import 'custom_card.dart';

class ManualIntakeWidget extends StatefulWidget {
  final FormFieldSetter<List<TimeOfDay>>? onSaved;
  const ManualIntakeWidget({super.key, this.onSaved});

  @override
  State<ManualIntakeWidget> createState() => _ManualIntakeWidgetState();
}

class _ManualIntakeWidgetState extends State<ManualIntakeWidget> {
  /// Подсчёт разницы в минутах между двумя TimeOfDay
  int _timeDifferenceInMinutes(TimeOfDay a, TimeOfDay b) {
    final aMinutes = a.hour * 60 + a.minute;
    final bMinutes = b.hour * 60 + b.minute;
    return aMinutes - bMinutes;
  }

  Future<void> _addTime(FormFieldState<List<TimeOfDay?>> state) async {
    final time = await showTimePicker(
      helpText: 'Выберите время',
      cancelText: 'Отмена',
      confirmText: 'Сохранить',
      hourLabelText: 'Часы',
      minuteLabelText: 'Минуты',
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      final times = List<TimeOfDay>.from(state.value ?? []);

      // Проверка минимальной разницы в 5 минут
      final isTooClose = times.any((t) {
        final diff = _timeDifferenceInMinutes(t, time);
        return diff.abs() < 5;
      });

      if (isTooClose) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Некорректное время'),
                content: const Text(
                  'Минимальная разница между временем — 5 минут',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ОК'),
                  ),
                ],
              );
            },
          );
          return;
        }
      }
      // Добавляем и сортируем по возрастанию
      times.add(time);
      times.sort((a, b) {
        final aMinutes = a.hour * 60 + a.minute;
        final bMinutes = b.hour * 60 + b.minute;
        return aMinutes.compareTo(bMinutes);
      });
      setState(() {
        state.didChange(times);
      });
    }
  }

  void _removeTime(TimeOfDay time, FormFieldState<List<TimeOfDay?>> state) {
    final times = List<TimeOfDay>.from(state.value ?? []);
    times.remove(time);

    setState(() {
      state.didChange(times);
    });
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<TimeOfDay>>(
      onSaved: widget.onSaved,
      initialValue: [],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Выберите время приема лекарства';
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...?state.value?.map(
                (t) => GestureDetector(
                  onLongPress: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Удалить время?'),
                        content: Text('Вы уверены, что хотите удалить $t?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Удалить'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) _removeTime(t, state);
                  },
                  child: customCard(isSelected: false, title: formatTime(t)),
                ),
              ),

              GestureDetector(
                onTap: () {
                  //state.didChange([]);
                  _addTime(state);
                },
                child: SizedBox(
                  height: 41,
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // ширина под содержимое
                        children: [
                          Icon(
                            Icons.add_alarm,
                            size: 30,
                            color: Colors.blueGrey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
      ),
    );
  }
}
