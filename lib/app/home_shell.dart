import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nasz_budzet_domowy/features/categories/presentation/categories_screen.dart';
import 'package:nasz_budzet_domowy/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nasz_budzet_domowy/features/transactions/presentation/transactions_list_screen.dart';

/// Główny shell apki z dolną nawigacją M3.
/// Trzy zakładki: Dashboard, Transakcje, Kategorie.
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
    CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
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
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Kategorie',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        tooltip: 'Dodaj transakcję',
        child: const Icon(Icons.add),
      ),
    );
  }
}
