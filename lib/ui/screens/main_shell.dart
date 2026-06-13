import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'add_receipt_screen.dart';
import 'home_dashboard_screen.dart';
import 'monthly_report_screen.dart';
import 'receipts_list_screen.dart';
import 'settings_screen.dart';

class MainShellController {
  static final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);

  static void selectTab(int index) {
    selectedIndex.value = index;
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    HomeDashboardScreen(),
    ReceiptsListScreen(),
    MonthlyReportScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    MainShellController.selectedIndex.addListener(_syncSelectedTab);
  }

  @override
  void dispose() {
    MainShellController.selectedIndex.removeListener(_syncSelectedTab);
    super.dispose();
  }

  void _syncSelectedTab() {
    if (_index == MainShellController.selectedIndex.value) return;
    setState(() => _index = MainShellController.selectedIndex.value);
  }

  void _selectTab(int index) {
    MainShellController.selectTab(index);
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return MainShellScope(
      selectTab: _selectTab,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _screens[_index],
              ),
            ),
            _FloatingBottomControls(
              selectedIndex: _index,
              onChanged: _selectTab,
              onAddPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddReceiptScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainShellScope extends InheritedWidget {
  const MainShellScope({
    super.key,
    required this.selectTab,
    required super.child,
  });

  final ValueChanged<int> selectTab;

  static MainShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellScope>();
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) {
    return selectTab != oldWidget.selectTab;
  }
}

class _FloatingBottomControls extends StatelessWidget {
  const _FloatingBottomControls({
    required this.selectedIndex,
    required this.onChanged,
    required this.onAddPressed,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottom = bottomInset + 18;
    return Positioned(
      left: 24,
      right: 24,
      bottom: bottom,
      child: SizedBox(
        height: 72,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 80,
              top: 0,
              bottom: 0,
              child: _FloatingNavBar(
                selectedIndex: selectedIndex,
                onChanged: onChanged,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _FloatingAddButton(onPressed: onAddPressed),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 72,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? colors.surface
            : colors.hero,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: colors.inverseText.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
            Icons.home_rounded,
            'Home',
            selectedIndex == 0,
            () => onChanged(0),
          ),
          _NavItem(
            Icons.receipt_long_rounded,
            'Receipts',
            selectedIndex == 1,
            () => onChanged(1),
          ),
          _NavItem(
            Icons.pie_chart_rounded,
            'Report',
            selectedIndex == 2,
            () => onChanged(2),
          ),
          _NavItem(
            Icons.tune_rounded,
            'Settings',
            selectedIndex == 3,
            () => onChanged(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(this.icon, this.label, this.selected, this.onTap);

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? colors.surface.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              icon,
              color: selected ? colors.inverseText : colors.mutedText,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingAddButton extends StatelessWidget {
  const _FloatingAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.18),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: onPressed,
          elevation: 0,
          backgroundColor: context.colors.hero,
          foregroundColor: context.colors.inverseText,
          shape: const CircleBorder(),
          tooltip: 'Add Receipt',
          child: const Icon(Icons.add_rounded, size: 34),
        ),
      ),
    );
  }
}
