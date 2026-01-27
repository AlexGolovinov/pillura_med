import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatefulWidget {
  /// Constructs an [ScaffoldWithNavBar].
  const ScaffoldWithNavBar({required this.navigationShell, Key? key})
    : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomAppBar(
        height: 70,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavIcon(
              label: 'Статистика',
              icon: Icons.bar_chart_rounded,
              isSelected: widget.navigationShell.currentIndex == 0,
              onTap: () => _onTap(context, 0),
            ),
            _NavIcon(
              label: 'Лекарства',
              icon: Icons.medical_services,
              isSelected: widget.navigationShell.currentIndex == 1,
              onTap: () => _onTap(context, 1),
            ),
            _NavIcon(
              label: 'Добавить',
              icon: Icons.person_add_outlined,
              isSelected: widget.navigationShell.currentIndex == 2,
              onTap: () => _onTap(context, 2),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.onTap,
    required this.isSelected,
    required this.label,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Theme.of(context).colorScheme.primary;
    final Color inactiveColor =
        Theme.of(context).iconTheme.color ?? Colors.black54;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        child: Column(
          children: [
            Icon(icon, color: isSelected ? activeColor : inactiveColor),
            Text(
              label,
              style: TextStyle(color: isSelected ? activeColor : inactiveColor),
            ),
          ],
        ),
      ),
    );
  }
}
