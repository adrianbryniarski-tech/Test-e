import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nasz_budzet_domowy/features/budgets/presentation/budgets_screen.dart';
import 'package:nasz_budzet_domowy/features/categories/presentation/categories_screen.dart';
import 'package:nasz_budzet_domowy/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nasz_budzet_domowy/features/transactions/presentation/transactions_list_screen.dart';
import 'package:nasz_budzet_domowy/shared/widgets/brand_watermark.dart';
import 'package:nasz_budzet_domowy/shared/widgets/glowing_button.dart';
import 'package:nasz_budzet_domowy/shared/widgets/neon_gradient_background.dart';

/// Główny shell apki z dolną nawigacją M3.
/// Cztery zakładki: Dashboard, Transakcje, Budżety, Kategorie.
/// FAB (+) zawsze widoczny — otwiera ekran dodawania transakcji.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    TransactionsListScreen(),
    BudgetsScreen(),
    CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonGradientBackground(
        child: Stack(
          children: [
            IndexedStack(
              index: _index,
              children: _screens,
            ),
            // Znak wodny przyklejony w lewym dolnym — pokrywa wszystkie
            // 4 zakładki, nie scrolluje z treścią.
            const BrandWatermark(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transakcje',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Budżety',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Kategorie',
          ),
        ],
      ),
      floatingActionButton: GlowingFAB(
        onPressed: () => context.push('/transactions/add'),
        tooltip: 'Dodaj transakcję',
        child: const Icon(Icons.add),
      ),
    );
  }
}
