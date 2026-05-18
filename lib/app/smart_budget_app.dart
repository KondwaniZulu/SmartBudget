import 'package:flutter/material.dart';
import 'package:smartbudget_app/core/theme/app_theme.dart';
import 'package:smartbudget_app/features/auth/presentation/pages/auth_gate_page.dart';
import 'package:smartbudget_app/features/navigation/presentation/pages/dashboard_shell_page.dart';

class SmartBudgetApp extends StatelessWidget {
  const SmartBudgetApp({super.key, this.requireAuth = false});

  final bool requireAuth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Budget',
      theme: AppTheme.lightTheme,
      scrollBehavior: const _NoStretchScrollBehavior(),
      home: requireAuth ? const AuthGatePage() : const DashboardShellPage(),
    );
  }
}

class _NoStretchScrollBehavior extends MaterialScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
