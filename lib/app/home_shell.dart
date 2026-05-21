import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nasz_budzet_domowy/features/budgets/presentation/budgets_screen.dart';
import 'package:nasz_budzet_domowy/features/categories/presentation/categories_screen.dart';
import 'package:nasz_budzet_domowy/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nasz_budzet_domowy/features/investments/presentation/investments_screen.dart';
import 'package:nasz_budzet_domowy/features/transactions/presentation/transactions_list_screen.dart';
import 'package:nasz_budzet_domowy/shared/widgets/brand_watermark.dart';
import 'package:nasz_budzet_domowy/shared/widgets/glowing_button.dart';
import 'package:nasz_budzet_domowy/shared/widgets/neon_gradient_background.dart';

/// Główny shell apki z dolną nawigacją M3.
/// Pięć zakładek: Dashboard, Transakcje, Budżety, Inwestycje, Kategorie.
/// FAB (+) zawsze widoczny — na Inwestycjach dodaje pozycję portfela,
/// w pozostałych zakładkach dodaje transakcję.
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
    InvestmentsScreen(),
    CategoriesScreen(),
  ];

  static const _investmentsIndex = 3;

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
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up),
            label: 'Inwestycje',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Kategorie',
          ),
        ],
      ),
      floatingActionButton: GlowingFAB(
        onPressed: () => context.push(
          _index == _investmentsIndex
              ? '/investments/add'
              : '/transactions/add',
        ),
        tooltip: _index == _investmentsIndex
            ? 'Dodaj inwestycję'
            : 'Dodaj transakcję',
        child: const Icon(Icons.add),
      ),
    );
  }
}
