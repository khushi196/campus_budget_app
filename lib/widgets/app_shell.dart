import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../screens/ai_advisor/ai_advisor_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/ledgers/ledgers_screen.dart';
import '../screens/piggybanks/piggybanks_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../services/expense_service.dart';
import '../services/expense_store_factory.dart';
import 'sidebar_nav.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  late final ExpenseService _expenseService = ExpenseService.demo(
    store: createExpenseStore(),
  );

  static const _items = [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded),
    NavItem(label: 'Expenses', icon: Icons.receipt_long_rounded),
    NavItem(label: 'Categories', icon: Icons.category_rounded),
    NavItem(label: 'Ledgers', icon: Icons.group_rounded),
    NavItem(label: 'Piggybanks', icon: Icons.savings_rounded),
    NavItem(label: 'AI Advisor', icon: Icons.auto_awesome_rounded),
    NavItem(label: 'Reports', icon: Icons.analytics_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 940;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                SidebarNav(
                  items: _items,
                  selectedIndex: _selectedIndex,
                  onSelected: _selectScreen,
                ),
                Expanded(child: _MainArea(child: _buildScreen())),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Campus Budget'),
            backgroundColor: AppColors.surface,
            surfaceTintColor: AppColors.surface,
          ),
          drawer: Drawer(
            child: SidebarNav(
              items: _items,
              selectedIndex: _selectedIndex,
              onSelected: (index) {
                _selectScreen(index);
                Navigator.of(context).pop();
              },
            ),
          ),
          body: _MainArea(child: _buildScreen()),
        );
      },
    );
  }

  void _selectScreen(int index) {
    setState(() => _selectedIndex = index);
  }

  void _refreshData() {
    setState(() {});
  }

  Widget _buildScreen() {
    return switch (_selectedIndex) {
      0 => DashboardScreen(
        expenseService: _expenseService,
        onDataChanged: _refreshData,
      ),
      1 => ExpensesScreen(
        expenseService: _expenseService,
        onDataChanged: _refreshData,
      ),
      2 => CategoriesScreen(
        expenseService: _expenseService,
        onDataChanged: _refreshData,
      ),
      3 => LedgersScreen(
        expenseService: _expenseService,
        onDataChanged: _refreshData,
      ),
      4 => PiggybanksScreen(
        expenseService: _expenseService,
        onDataChanged: _refreshData,
      ),
      5 => const AiAdvisorScreen(),
      6 => ReportsScreen(expenseService: _expenseService),
      _ => DashboardScreen(
        expenseService: _expenseService,
        onDataChanged: _refreshData,
      ),
    };
  }
}

class _MainArea extends StatelessWidget {
  const _MainArea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 26),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Text(
                  'Campus Budget',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Search',
                  onPressed: () {},
                  icon: const Icon(Icons.search_rounded, color: AppColors.blue),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.coral.withValues(alpha: 0.16),
                  child: const Text(
                    'K',
                    style: TextStyle(
                      color: AppColors.coral,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
