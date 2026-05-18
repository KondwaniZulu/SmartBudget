import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartbudget_app/features/budget/presentation/pages/budget_page.dart';
import 'package:smartbudget_app/features/home/data/repositories/supabase_budget_repository.dart';
import 'package:smartbudget_app/features/home/data/repositories/supabase_transaction_repository.dart';
import 'package:smartbudget_app/features/home/data/student_budget_store.dart';
import 'package:smartbudget_app/features/home/presentation/pages/home_page.dart';
import 'package:smartbudget_app/features/profile/presentation/pages/profile_page.dart';
import 'package:smartbudget_app/features/transactions/presentation/pages/activity_page.dart';

class DashboardShellPage extends StatefulWidget {
  const DashboardShellPage({super.key});

  @override
  State<DashboardShellPage> createState() => _DashboardShellPageState();
}

class _DashboardShellPageState extends State<DashboardShellPage> {
  int _selectedIndex = 0;
  late StudentBudgetStore _store;
  final GlobalKey<BudgetPageState> _budgetPageKey =
      GlobalKey<BudgetPageState>();

  @override
  void initState() {
    super.initState();
    _store = StudentBudgetStore();
    _bootstrapSupabaseStore();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _bootstrapSupabaseStore() async {
    try {
      final SupabaseClient client = Supabase.instance.client;
      final Session? session = client.auth.currentSession;
      if (session == null) {
        return;
      }
      final _UserContext userContext = await _resolveUserContext(
        client: client,
        session: session,
      );

      final SupabaseTransactionRepository transactionRepository =
          await SupabaseTransactionRepository.create(
            client: client,
            userId: session.user.id,
          );
      final SupabaseBudgetRepository budgetRepository =
          await SupabaseBudgetRepository.create(
            client: client,
            userId: session.user.id,
          );

      final StudentBudgetStore oldStore = _store;
      final StudentBudgetStore liveStore = StudentBudgetStore(
        transactionRepository: transactionRepository,
        budgetRepository: budgetRepository,
        initialUserName: userContext.displayName,
        initialOpeningBalanceNgwee: userContext.openingBalanceNgwee,
      );

      if (!mounted) {
        oldStore.dispose();
        liveStore.dispose();
        return;
      }

      setState(() {
        _store = liveStore;
      });
      oldStore.dispose();
    } catch (_) {
      // Keep in-memory store fallback if Supabase is unavailable.
    }
  }

  Future<_UserContext> _resolveUserContext({
    required SupabaseClient client,
    required Session session,
  }) async {
    String? profileName;
    int? openingBalanceNgwee;
    try {
      final dynamic row = await client
          .from('profiles')
          .select('full_name, opening_balance_ngwee')
          .eq('id', session.user.id)
          .maybeSingle();
      final Map<String, dynamic>? data = row as Map<String, dynamic>?;
      profileName = data?['full_name'] as String?;
      openingBalanceNgwee = (data?['opening_balance_ngwee'] as num?)?.toInt();
      if (profileName != null && profileName.trim().isNotEmpty) {
        return _UserContext(
          displayName: profileName.trim(),
          openingBalanceNgwee: (openingBalanceNgwee ?? 0).clamp(0, 9999999999),
        );
      }
    } catch (_) {
      // Fall back to auth metadata/email.
    }

    final Map<String, dynamic> metadata =
        session.user.userMetadata ?? <String, dynamic>{};
    final String? fromMetadata =
        metadata['full_name'] as String? ?? metadata['name'] as String?;
    final int safeOpening = (openingBalanceNgwee ?? 0).clamp(0, 9999999999);
    if (fromMetadata != null && fromMetadata.trim().isNotEmpty) {
      return _UserContext(
        displayName: fromMetadata.trim(),
        openingBalanceNgwee: safeOpening,
      );
    }
    final String? email = session.user.email;
    if (email != null && email.contains('@')) {
      return _UserContext(
        displayName: email.split('@').first,
        openingBalanceNgwee: safeOpening,
      );
    }
    return _UserContext(
      displayName: 'Student',
      openingBalanceNgwee: safeOpening,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomePage(
        store: _store,
        onSetBudgetRequested: () async {
          setState(() {
            _selectedIndex = 1;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _budgetPageKey.currentState?.openBudgetEditor();
          });
        },
      ),
      BudgetPage(key: _budgetPageKey, store: _store),
      ActivityPage(store: _store),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home_rounded),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.pie_chart_rounded),
            icon: Icon(Icons.pie_chart_outline_rounded),
            label: 'Budget',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.receipt_long_rounded),
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Activity',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person_rounded),
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _UserContext {
  const _UserContext({
    required this.displayName,
    required this.openingBalanceNgwee,
  });

  final String displayName;
  final int openingBalanceNgwee;
}
