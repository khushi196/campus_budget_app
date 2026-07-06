import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../screens/ai_advisor/ai_advisor_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/ledgers/ledgers_screen.dart';
import '../screens/piggybanks/piggybanks_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../services/aws_auth_service.dart';
import '../services/aws_budget_api.dart';
import '../services/aws_config.dart';
import '../services/aws_expense_store.dart';
import '../services/backend_expense_store.dart';
import '../services/expense_service.dart';
import '../services/expense_store.dart';
import '../services/expense_store_factory.dart';
import 'sidebar_nav.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.awsSession, this.onSignOut});

  final AwsSession? awsSession;
  final VoidCallback? onSignOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  ExpenseService? _expenseService;
  bool _usingBackend = false;
  bool _usingCloud = false;
  AwsSyncState _syncState = const AwsSyncState(AwsSyncStatus.idle);

  @override
  void initState() {
    super.initState();
    _initStore();
  }

  Future<void> _initStore() async {
    ExpenseStore store;
    bool usingBackend = false;
    bool usingCloud = false;
    try {
      final session = widget.awsSession;
      if (session != null && AwsConfig.isConfigured) {
        final cloudStore = AwsExpenseStore(
          AwsBudgetApi(baseUrl: AwsConfig.apiBaseUrl, idToken: session.idToken),
          backupStore: createExpenseStore(),
          onSyncStateChanged: (state) {
            if (!mounted) return;
            setState(() => _syncState = state);
          },
        );
        await cloudStore.primeCache();
        store = cloudStore;
        usingCloud = true;
      } else {
        // Try C++ backend first; fall back to localStorage within 1 second.
        store = await createExpenseStoreAsync();
        usingBackend = store is BackendExpenseStore;
      }
    } catch (_) {
      store = createExpenseStore();
    }
    if (!mounted) return;
    setState(() {
      _expenseService = ExpenseService.demo(store: store);
      _usingBackend = usingBackend;
      _usingCloud = usingCloud;
    });
  }

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
    // Show a brief loading screen while probing for the C++ backend (max 1s)
    if (_expenseService == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.teal),
              SizedBox(height: 16),
              Text('Starting up…', style: TextStyle(color: AppColors.mutedInk)),
            ],
          ),
        ),
      );
    }

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
                Expanded(
                  child: _MainArea(
                    usingBackend: _usingBackend,
                    usingCloud: _usingCloud,
                    syncState: _syncState,
                    onSearchSelected: _selectScreen,
                    onSignOut: widget.onSignOut,
                    child: _buildScreen(),
                  ),
                ),
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
          body: _MainArea(
            usingBackend: _usingBackend,
            usingCloud: _usingCloud,
            syncState: _syncState,
            onSearchSelected: _selectScreen,
            onSignOut: widget.onSignOut,
            child: _buildScreen(),
          ),
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
    final svc = _expenseService!;
    return switch (_selectedIndex) {
      0 => DashboardScreen(
        expenseService: svc,
        onDataChanged: _refreshData,
        onOpenAiAdvisor: () => _selectScreen(5),
      ),
      1 => ExpensesScreen(expenseService: svc, onDataChanged: _refreshData),
      2 => CategoriesScreen(expenseService: svc, onDataChanged: _refreshData),
      3 => LedgersScreen(expenseService: svc, onDataChanged: _refreshData),
      4 => PiggybanksScreen(expenseService: svc, onDataChanged: _refreshData),
      5 => AiAdvisorScreen(
        expenseService: svc,
        aiBackendUrl: _usingCloud ? AwsConfig.apiBaseUrl : null,
        aiBearerToken: _usingCloud ? widget.awsSession?.idToken : null,
      ),
      6 => ReportsScreen(expenseService: svc),
      _ => DashboardScreen(
        expenseService: svc,
        onDataChanged: _refreshData,
        onOpenAiAdvisor: () => _selectScreen(5),
      ),
    };
  }
}

class _MainArea extends StatelessWidget {
  const _MainArea({
    required this.child,
    required this.usingBackend,
    required this.usingCloud,
    required this.syncState,
    required this.onSearchSelected,
    this.onSignOut,
  });

  final Widget child;
  final bool usingBackend;
  final bool usingCloud;
  final AwsSyncState syncState;
  final ValueChanged<int> onSearchSelected;
  final VoidCallback? onSignOut;

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
                const SizedBox(width: 12),
                // Backend status badge
                Tooltip(
                  message: usingCloud
                      ? 'Connected to AWS Cognito, API Gateway, Lambda, and DynamoDB'
                      : usingBackend
                      ? 'Connected to C++ backend API (localhost:8080)'
                      : 'Using browser localStorage (C++ server not running)',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: usingBackend
                          ? AppColors.teal.withValues(alpha: 0.12)
                          : usingCloud
                          ? AppColors.blue.withValues(alpha: 0.12)
                          : AppColors.mutedInk.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: usingCloud
                            ? AppColors.blue.withValues(alpha: 0.35)
                            : usingBackend
                            ? AppColors.teal.withValues(alpha: 0.35)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          usingCloud
                              ? Icons.cloud_done_rounded
                              : usingBackend
                              ? Icons.dns_rounded
                              : Icons.storage_rounded,
                          size: 11,
                          color: usingCloud
                              ? AppColors.blue
                              : usingBackend
                              ? AppColors.teal
                              : AppColors.mutedInk,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          usingCloud
                              ? 'AWS'
                              : usingBackend
                              ? 'C++ API'
                              : 'Local',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: usingCloud
                                ? AppColors.blue
                                : usingBackend
                                ? AppColors.teal
                                : AppColors.mutedInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (usingCloud) ...[
                  const SizedBox(width: 8),
                  _SyncStatusBadge(state: syncState),
                ],
                const Spacer(),
                IconButton(
                  tooltip: 'Search',
                  onPressed: () => _showSearchDialog(context),
                  icon: const Icon(Icons.search_rounded, color: AppColors.blue),
                ),
                if (onSignOut != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: onSignOut,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.mutedInk,
                    ),
                  ),
                ],
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

  Future<void> _showSearchDialog(BuildContext context) async {
    final selectedIndex = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Search pages'),
          children: [
            for (var i = 0; i < _AppShellState._items.length; i++)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(i),
                child: Row(
                  children: [
                    Icon(
                      _AppShellState._items[i].icon,
                      color: AppColors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(_AppShellState._items[i].label),
                  ],
                ),
              ),
          ],
        );
      },
    );

    if (selectedIndex != null) {
      onSearchSelected(selectedIndex);
    }
  }
}

class _SyncStatusBadge extends StatelessWidget {
  const _SyncStatusBadge({required this.state});

  final AwsSyncState state;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color, tooltip) = switch (state.status) {
      AwsSyncStatus.loading => (
        'Loading',
        Icons.cloud_sync_rounded,
        AppColors.blue,
        'Loading your latest AWS budget data',
      ),
      AwsSyncStatus.syncing => (
        'Syncing',
        Icons.sync_rounded,
        AppColors.amber,
        'Saving your latest changes to AWS',
      ),
      AwsSyncStatus.synced => (
        'Saved',
        Icons.cloud_done_rounded,
        AppColors.green,
        'Your latest changes are saved',
      ),
      AwsSyncStatus.error => (
        'Sync error',
        Icons.cloud_off_rounded,
        AppColors.red,
        state.message ?? 'AWS sync failed',
      ),
      AwsSyncStatus.idle => (
        'Ready',
        Icons.cloud_queue_rounded,
        AppColors.mutedInk,
        'AWS sync is ready',
      ),
    };

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
