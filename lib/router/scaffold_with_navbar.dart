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
  bool _isNavigating = false;

  Future<void> _onFabPressed(BuildContext context) async {
    if (_isNavigating) return; // защитa от дабл-тапа
    setState(() => _isNavigating = true);
    try {
      await context.push('/addMedication');
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    // matchedLocation in shell can include parent segments, so check via contains
    final bool isOnAddMedication = location.contains('/addMedication');
    final bool isOnProfilePage = location.contains('/profilePage');

    // Если ушли с /addMedication не через pop (например, переключили таб),
    // сбрасываем блокировку кнопки.
    if (_isNavigating && !isOnAddMedication) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isNavigating = false);
      });
    }

    return Scaffold(
      body: widget.navigationShell,
      floatingActionButton: isOnAddMedication || !isOnProfilePage
          ? null
          : FloatingActionButton(
              onPressed: _isNavigating ? null : () => _onFabPressed(context),
              elevation: 1,
              shape: const CircleBorder(),
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, size: 45, color: Colors.white),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
            const SizedBox(width: 48),
            _NavIcon(
              label: 'Добавить',
              icon: Icons.person_add_outlined,
              isSelected: widget.navigationShell.currentIndex == 1,
              onTap: () => _onTap(context, 1),
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
      child: Container(
        width: MediaQuery.of(context).size.width / 3,
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
      onTap: onTap,
    );
  }
}
