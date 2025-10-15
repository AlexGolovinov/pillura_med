import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'custom_card.dart';

class ManualIntakeWidget extends StatefulWidget {
  const ManualIntakeWidget({super.key});

  @override
  State<ManualIntakeWidget> createState() => _ManualIntakeWidgetState();
}

class _ManualIntakeWidgetState extends State<ManualIntakeWidget> {
  final List<String> _times = [];

  Future<void> _addTime() async {
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
      final now = DateTime.now();
      final dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      final formatted = DateFormat('HH:mm').format(dateTime);
      setState(() {
        _times.add(formatted);
      });
    }
  }

  void _removeTime(String time) {
    setState(() {
      _times.remove(time);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._times.map(
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

              if (confirm == true) _removeTime(t);
            },
            child: customCard(isSelected: false, title: t),
          ),
        ),

        GestureDetector(
          onTap: _addTime,
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
                    Icon(Icons.add_alarm, size: 30, color: Colors.blueGrey),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
