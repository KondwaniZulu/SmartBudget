import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartbudget_app/core/theme/app_colors.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _isRegisterMode = true;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 36),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.account_balance_wallet_rounded),
                ),
                const SizedBox(height: 20),
                Text(
                  'Smart Budget',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _isRegisterMode
                      ? 'Create your account to start tracking your student income and expenses.'
                      : 'Sign in to continue tracking your student income and expenses.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (_isRegisterMode) ...[
                  TextField(
                    controller: _fullNameController,
                    enabled: !_loading,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _emailController,
                  enabled: !_loading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  enabled: !_loading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(
                      _loading
                          ? (_isRegisterMode
                                ? 'Creating account...'
                                : 'Signing in...')
                          : (_isRegisterMode ? 'Create account' : 'Sign in'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () {
                          setState(() {
                            _isRegisterMode = !_isRegisterMode;
                            _errorMessage = null;
                          });
                        },
                  child: Text(
                    _isRegisterMode
                        ? 'Already have an account? Sign in'
                        : 'Need an account? Create one',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final String fullName = _fullNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    if (_isRegisterMode && fullName.isEmpty) {
      setState(() {
        _errorMessage = 'Full name is required.';
      });
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Email and password are required.';
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        final AuthResponse response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: <String, dynamic>{'full_name': fullName},
        );
        if (!mounted) {
          return;
        }
        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created. Check your email to confirm your account.',
              ),
            ),
          );
        } else {
          await _upsertProfileRow(fullName: fullName);
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully.')),
          );
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        await _upsertProfileRow();
      }
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _isRegisterMode
            ? 'Registration failed. Please try again.'
            : 'Sign in failed. Please try again.';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            _isRegisterMode
                ? 'Registration failed.'
                : 'Sign in failed.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _upsertProfileRow({String? fullName}) async {
    final SupabaseClient client = Supabase.instance.client;
    final User? user = client.auth.currentUser;
    if (user == null) {
      return;
    }

    final String resolvedName =
        (fullName != null && fullName.trim().isNotEmpty)
            ? fullName.trim()
            : (user.userMetadata?['full_name'] as String?)?.trim().isNotEmpty ==
                  true
            ? (user.userMetadata?['full_name'] as String).trim()
            : ((user.email != null && user.email!.contains('@'))
                  ? user.email!.split('@').first
                  : 'Student');

    try {
      await client.from('profiles').upsert(<String, dynamic>{
        'id': user.id,
        'full_name': resolvedName,
      });
    } catch (_) {
      // Auth succeeded; profile bootstrap is best-effort.
    }
  }
}
