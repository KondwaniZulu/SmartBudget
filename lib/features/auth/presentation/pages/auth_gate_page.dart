import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartbudget_app/features/auth/presentation/pages/sign_in_page.dart';
import 'package:smartbudget_app/features/navigation/presentation/pages/dashboard_shell_page.dart';

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  late final SupabaseClient _client;
  StreamSubscription<AuthState>? _authSubscription;
  Session? _session;
  bool _authReady = false;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _session = _client.auth.currentSession;
    debugPrint(
      '[AUTH_DEBUG] AuthGate init. hasSession=${_session != null} '
      'user=${_session?.user.id}',
    );

    _authSubscription = _client.auth.onAuthStateChange.listen((
      AuthState state,
    ) {
      debugPrint(
        '[AUTH_DEBUG] AuthGate stream event=${state.event.name} '
        'hasSession=${state.session != null} '
        'user=${state.session?.user.id}',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _session = state.session;
        _authReady = true;
      });
    });

    // Allow Supabase a brief moment to recover persisted session on cold start.
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || _authReady) {
        return;
      }
      setState(() {
        _session = _client.auth.currentSession;
        _authReady = true;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[AUTH_DEBUG] AuthGate build authReady=$_authReady '
      'hasSession=${_session != null} user=${_session?.user.id}',
    );

    if (!_authReady && _session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_session == null) {
      return const SignInPage();
    }
    return const DashboardShellPage();
  }
}
