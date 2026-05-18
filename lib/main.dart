import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartbudget_app/app/smart_budget_app.dart';
import 'package:smartbudget_app/core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.publishableKey,
  );
  final SupabaseClient client = Supabase.instance.client;
  debugPrint(
    '[AUTH_DEBUG] Supabase initialized. hasSession='
    '${client.auth.currentSession != null}',
  );
  client.auth.onAuthStateChange.listen((AuthState state) {
    debugPrint(
      '[AUTH_DEBUG] onAuthStateChange event=${state.event.name} '
      'hasSession=${state.session != null} '
      'user=${state.session?.user.id}',
    );
  });
  runApp(const SmartBudgetApp(requireAuth: true));
}
