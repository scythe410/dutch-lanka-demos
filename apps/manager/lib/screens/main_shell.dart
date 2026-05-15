import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

/// Bottom-nav shell. Per design.md §10 the manager has 4 tabs
/// (Dashboard, Orders, Products, More). Inventory lives behind a
/// dedicated route reached from the dashboard's low-stock KPI tile —
/// pulling it into the bottom-nav would push the row past 4 tabs and
/// strain the design system's tap-target guidance.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static const _tabs = <_Tab>[
    _Tab(path: '/dashboard', icon: LucideIcons.layout_dashboard, label: 'Home'),
    _Tab(path: '/orders', icon: LucideIcons.clipboard_list, label: 'Orders'),
    _Tab(path: '/products', icon: LucideIcons.box, label: 'Products'),
    _Tab(path: '/more', icon: LucideIcons.menu, label: 'More'),
  ];

  int get _index {
    if (location.startsWith('/inventory')) return 0;
    final i = _tabs.indexWhere((t) => location.startsWith(t.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surfaceElevated,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        selectedIndex: _index,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon, color: AppColors.textTertiary),
              selectedIcon: Icon(t.icon, color: AppColors.primary),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab({required this.path, required this.icon, required this.label});
  final String path;
  final IconData icon;
  final String label;
}
