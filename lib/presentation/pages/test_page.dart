import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';

class User {
  final int id;
  final String name;
  User({required this.id, required this.name});
}

class SlideMovePage extends StatefulWidget {
  const SlideMovePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SlideMovePageState createState() => _SlideMovePageState();
}

class _SlideMovePageState extends State<SlideMovePage> {
  List<User> list = [
    User(id: 1, name: "Пользователь 1"),
    User(id: 2, name: "Пользователь 2"),
    User(id: 3, name: "Пользователь 3"),
    User(id: 4, name: "Пользователь 4"),
  ];

  void _reorderProgrammatically() {
    setState(() {
      // Твоя схема перемещения
      final u1 = list.firstWhere((e) => e.id == 1);
      final u2 = list.firstWhere((e) => e.id == 2);
      final u3 = list.firstWhere((e) => e.id == 3);
      final u4 = list.firstWhere((e) => e.id == 4);

      list = [u3, u4, u2, u1];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Только Slide, никакого Fade")),
      floatingActionButton: FloatingActionButton(
        onPressed: _reorderProgrammatically,
        child: const Icon(Icons.refresh), // Иконка смены
      ),
      body: ImplicitlyAnimatedReorderableList<User>(
        items: list,
        areItemsTheSame: (oldItem, newItem) => oldItem.id == newItem.id,
        // Длительность ПЕРЕМЕЩЕНИЯ (езда элементов друг мимо друга)
        reorderDuration: const Duration(milliseconds: 600),

        onReorderFinished: (item, from, to, newItems) {
          setState(() => list = newItems);
        },

        itemBuilder: (context, itemAnimation, lang, index) {
          return Reorderable(
            key: ValueKey(lang.id),
            builder: (context, dragAnimation, inDrag) {
              // Создаем смещение: от (1,0) — справа, до (0,0) — центр
              final slideAnimation = itemAnimation.drive(
                Tween<Offset>(
                  begin: const Offset(
                    1,
                    0,
                  ), // Начинаем за границей экрана справа
                  end: Offset.zero, // Приезжаем в обычное положение
                ).chain(CurveTween(curve: Curves.easeInOut)),
              );

              return SlideTransition(
                position: slideAnimation,
                child: _buildTile(lang),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTile(User user) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text("${user.id}")),
        title: Text(user.name),
        trailing: const Icon(Icons.drag_handle),
      ),
    );
  }
}
