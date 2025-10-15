import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pillura_med/presentation/widgets/custom_card.dart';

class AutomaticIntervalWidget extends StatefulWidget {
  const AutomaticIntervalWidget({super.key});

  @override
  State<AutomaticIntervalWidget> createState() =>
      _AutomaticIntervalWidgetState();
}

class _AutomaticIntervalWidgetState extends State<AutomaticIntervalWidget> {
  int selectedTime = 5;
  String errorText = 'Выберите время начала и окончания приёма';
  final List<String> formats = ['Минут', 'Часов'];
  TimeOfDay? _timesFrom;
  TimeOfDay? _timesTo;

  List<TimeOfDay> _times = [];

  final minutes = List.generate(10, (i) => i + 1); // от 1 до 10

  void calculateTime(int timesCount) {
    if (_timesFrom != null && _timesTo != null) {
      final start = DateTime(0, 1, 1, _timesFrom!.hour, _timesFrom!.minute);
      final end = DateTime(0, 1, 1, _timesTo!.hour, _timesTo!.minute);
      final diff = end.difference(start);

      if (timesCount < 2) {
        errorText = 'Некорректное количество приёмов';
        return;
      }
      if (diff.inMinutes < 0) {
        errorText = 'Время окончания не может быть раньше времени начала';
        return;
      }
      final step = diff ~/ (timesCount - 1);
      if (step.inMinutes < 5) {
        errorText = 'Слишком много приёмов для выбранного интервала';
        return;
      }

      _times = List.generate(timesCount, (i) {
        final time = start.add(step * i);
        return TimeOfDay(hour: time.hour, minute: time.minute);
      });
    } else {
      errorText = 'Выберите время начала и окончания приёма';
    }
  }

  Future<void> _addTime(bool isFrom, TimeOfDay? initialTime) async {
    final time = await showTimePicker(
      helpText: 'Выберите время',
      cancelText: 'Отмена',
      confirmText: 'Сохранить',
      hourLabelText: 'Часы',
      minuteLabelText: 'Минуты',
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _times.clear();
        if (isFrom) {
          _timesFrom = time;
        } else {
          _timesTo = time;
        }
        calculateTime(selectedTime);
      });
    }
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Начиная С'),
            SizedBox(width: 8),
            _timesFrom == null
                ? GestureDetector(
                    onTap: () => _addTime(true, null),
                    child: SizedBox(
                      height: 41,
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min, // ширина под содержимое
                            children: [
                              Icon(
                                Icons.watch_later_outlined,
                                size: 25,
                                color: Colors.blueGrey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () => _addTime(true, _timesFrom),
                    child: customCard(
                      title: formatTime(_timesFrom!),
                      isSelected: true,
                    ),
                  ),
            SizedBox(width: 5),
            Text('ПО'),
            SizedBox(width: 5),
            _timesTo == null
                ? GestureDetector(
                    onTap: () => _addTime(false, null),
                    child: SizedBox(
                      height: 41,
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min, // ширина под содержимое
                            children: [
                              Icon(
                                Icons.watch_later_outlined,
                                size: 25,
                                color: Colors.blueGrey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () => _addTime(false, _timesTo),
                    child: customCard(
                      title: formatTime(_timesTo!),
                      isSelected: true,
                    ),
                  ),
            SizedBox(width: 8),
            SizedBox(
              height: 82,
              width: 80,
              child: CupertinoPicker(
                itemExtent: 41,
                looping: true,
                scrollController: FixedExtentScrollController(
                  initialItem: selectedTime - 1,
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedTime = index + 1;
                    _times.clear();
                    calculateTime(selectedTime);
                  });
                },
                children: minutes.map((e) {
                  return Center(child: Text(e.toString()));
                }).toList(),
              ),
            ),
            Text('в день'),
          ],
        ),
        _times.isEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(errorText, style: TextStyle(color: Colors.red)),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _times
                    .map(
                      (t) =>
                          customCard(isSelected: false, title: formatTime(t)),
                    )
                    .toList(),
              ),
      ],
    );
  }
}
