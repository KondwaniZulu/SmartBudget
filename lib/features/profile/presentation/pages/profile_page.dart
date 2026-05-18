import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartbudget_app/core/theme/app_colors.dart';
import 'package:smartbudget_app/core/utils/currency_formatter.dart';
import 'package:smartbudget_app/features/home/presentation/widgets/section_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const int _defaultSemesterTargetNgwee = 300000;

  bool _loadingProfile = true;
  bool _loadingSnapshot = true;
  bool _loadingSemesterGoal = true;
  bool _savingProfile = false;
  bool _savingSemesterTarget = false;
  String? _profileError;
  String? _snapshotError;
  String? _semesterGoalError;
  _ProfileData? _profile;
  int _monthlyIncomeNgwee = 0;
  int _monthlySpentNgwee = 0;
  int _semesterSavedNgwee = 0;
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get _currentUser => _client?.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  Future<void> _loadPageData() async {
    await Future.wait<void>([
      _loadProfile(),
      _loadMonthlySnapshot(),
      _loadSemesterGoalSnapshot(),
    ]);
  }

  Future<void> _loadProfile() async {
    final SupabaseClient? client = _client;
    final User? user = _currentUser;
    if (client == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingProfile = false;
        _profileError = null;
      });
      return;
    }
    if (user == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingProfile = false;
        _profileError = 'No signed-in user found.';
      });
      return;
    }

    try {
      final dynamic row = await client
          .from('profiles')
          .select(
            'full_name, avatar_url, semester_target_ngwee, opening_balance_ngwee',
          )
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) {
        return;
      }
      setState(() {
        _profile = _ProfileData.fromRow(row as Map<String, dynamic>?);
        _loadingProfile = false;
        _profileError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingProfile = false;
        _profileError = 'Failed to load profile.';
      });
    }
  }

  Future<void> _loadMonthlySnapshot() async {
    final SupabaseClient? client = _client;
    final User? user = _currentUser;
    if (client == null || user == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingSnapshot = false;
        _snapshotError = null;
        _monthlyIncomeNgwee = 0;
        _monthlySpentNgwee = 0;
      });
      return;
    }

    final DateTime monthStart = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final DateTime nextMonthStart = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      1,
    );
    final String startDate = monthStart.toIso8601String().split('T').first;
    final String endDate = nextMonthStart
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .split('T')
        .first;

    try {
      final List<dynamic> rows = await client
          .from('transactions')
          .select('amount_ngwee, type, transaction_date')
          .eq('user_id', user.id)
          .gte('transaction_date', startDate)
          .lte('transaction_date', endDate);

      int income = 0;
      int spent = 0;
      for (final dynamic row in rows) {
        final Map<String, dynamic> item = row as Map<String, dynamic>;
        final int amount = item['amount_ngwee'] as int? ?? 0;
        final String type = item['type'] as String? ?? '';
        if (type == 'income') {
          income += amount;
        } else if (type == 'expense') {
          spent += amount;
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _monthlyIncomeNgwee = income;
        _monthlySpentNgwee = spent;
        _loadingSnapshot = false;
        _snapshotError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingSnapshot = false;
        _snapshotError = 'Failed to load monthly snapshot.';
      });
    }
  }

  Future<void> _loadSemesterGoalSnapshot() async {
    final SupabaseClient? client = _client;
    final User? user = _currentUser;
    if (client == null || user == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingSemesterGoal = false;
        _semesterGoalError = null;
        _semesterSavedNgwee = 0;
      });
      return;
    }

    final DateTime now = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final DateTime semesterStart = _semesterStart(now);
    final String startDate = semesterStart.toIso8601String().split('T').first;
    final String endDate = now.toIso8601String().split('T').first;

    try {
      final List<dynamic> rows = await client
          .from('transactions')
          .select('amount_ngwee, type, transaction_date')
          .eq('user_id', user.id)
          .gte('transaction_date', startDate)
          .lte('transaction_date', endDate);

      int income = 0;
      int spent = 0;
      for (final dynamic row in rows) {
        final Map<String, dynamic> item = row as Map<String, dynamic>;
        final int amount = item['amount_ngwee'] as int? ?? 0;
        final String type = item['type'] as String? ?? '';
        if (type == 'income') {
          income += amount;
        } else if (type == 'expense') {
          spent += amount;
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _semesterSavedNgwee = income - spent;
        _loadingSemesterGoal = false;
        _semesterGoalError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingSemesterGoal = false;
        _semesterGoalError = 'Failed to load semester savings goal.';
      });
    }
  }

  Future<void> _openEditNameSheet() async {
    if (_savingProfile) {
      return;
    }

    final String initialName = _displayName;
    String? validationError;
    String draftName = initialName;

    final String? updatedName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit profile name',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: initialName,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Full name',
                      errorText: validationError,
                    ),
                    onChanged: (value) {
                      draftName = value;
                    },
                    onFieldSubmitted: (_) {
                      final String name = draftName.trim();
                      if (name.isEmpty) {
                        setModalState(() {
                          validationError = 'Name is required.';
                        });
                        return;
                      }
                      Navigator.of(context).pop(name);
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final String name = draftName.trim();
                        if (name.isEmpty) {
                          setModalState(() {
                            validationError = 'Name is required.';
                          });
                          return;
                        }
                        Navigator.of(context).pop(name);
                      },
                      child: const Text('Save Name'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (updatedName == null) {
      return;
    }

    await _saveProfileName(updatedName);
  }

  Future<void> _saveProfileName(String fullName) async {
    final SupabaseClient? client = _client;
    final User? user = _currentUser;
    if (client == null || user == null) {
      return;
    }

    setState(() {
      _savingProfile = true;
      _profileError = null;
    });

    try {
      await client.from('profiles').upsert({
        'id': user.id,
        'full_name': fullName,
        'avatar_url': _avatarUrl,
      }, onConflict: 'id');

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = (_profile ?? const _ProfileData()).copyWith(
          fullName: fullName,
          avatarUrl: _avatarUrl,
        );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _profileError = error.message;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _profileError = 'Failed to update profile.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingProfile = false;
        });
      }
    }
  }

  Future<void> _openEditSemesterTargetSheet() async {
    if (_savingSemesterTarget) {
      return;
    }

    final String initialTarget = formatNgweeForInput(_semesterTargetNgwee);
    String draftTarget = initialTarget;
    String? validationError;

    final int? updatedTargetNgwee = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit semester goal',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: initialTarget,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Target amount',
                      prefixText: 'ZMW ',
                      errorText: validationError,
                    ),
                    onChanged: (value) {
                      draftTarget = value;
                    },
                    onFieldSubmitted: (_) {
                      final int? valueNgwee = parseZmwInputToNgwee(draftTarget);
                      if (valueNgwee == null || valueNgwee <= 0) {
                        setModalState(() {
                          validationError = 'Enter a valid target amount.';
                        });
                        return;
                      }
                      Navigator.of(context).pop(valueNgwee);
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final int? valueNgwee = parseZmwInputToNgwee(
                          draftTarget,
                        );
                        if (valueNgwee == null || valueNgwee <= 0) {
                          setModalState(() {
                            validationError = 'Enter a valid target amount.';
                          });
                          return;
                        }
                        Navigator.of(context).pop(valueNgwee);
                      },
                      child: const Text('Save Goal'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (updatedTargetNgwee == null) {
      return;
    }

    await _saveSemesterTarget(updatedTargetNgwee);
  }

  Future<void> _saveSemesterTarget(int targetNgwee) async {
    final SupabaseClient? client = _client;
    final User? user = _currentUser;
    if (client == null || user == null) {
      return;
    }

    setState(() {
      _savingSemesterTarget = true;
      _semesterGoalError = null;
    });

    try {
      await client.from('profiles').upsert({
        'id': user.id,
        'semester_target_ngwee': targetNgwee,
      }, onConflict: 'id');

      if (!mounted) {
        return;
      }
      setState(() {
        _profile = (_profile ?? const _ProfileData()).copyWith(
          semesterTargetNgwee: targetNgwee,
        );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semester goal updated.')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _semesterGoalError = 'Failed to update semester goal.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update semester goal.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingSemesterTarget = false;
        });
      }
    }
  }

  int get _semesterTargetNgwee {
    final int value =
        _profile?.semesterTargetNgwee ?? _defaultSemesterTargetNgwee;
    return value <= 0 ? _defaultSemesterTargetNgwee : value;
  }

  int get _openingBalanceNgwee {
    final int value = _profile?.openingBalanceNgwee ?? 0;
    return value < 0 ? 0 : value;
  }

  Future<void> _openEditOpeningBalanceSheet() async {
    final String initialValue = formatNgweeForInput(_openingBalanceNgwee);
    String draftValue = initialValue;
    String? validationError;

    final int? updatedBalanceNgwee = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set opening balance',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: initialValue,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Opening balance',
                      prefixText: 'ZMW ',
                      errorText: validationError,
                    ),
                    onChanged: (value) => draftValue = value,
                    onFieldSubmitted: (_) {
                      final int? parsed = parseZmwInputToNgwee(draftValue);
                      if (parsed == null || parsed < 0) {
                        setModalState(() {
                          validationError = 'Enter a valid amount.';
                        });
                        return;
                      }
                      Navigator.of(context).pop(parsed);
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final int? parsed = parseZmwInputToNgwee(draftValue);
                        if (parsed == null || parsed < 0) {
                          setModalState(() {
                            validationError = 'Enter a valid amount.';
                          });
                          return;
                        }
                        Navigator.of(context).pop(parsed);
                      },
                      child: const Text('Save Balance'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (updatedBalanceNgwee == null) {
      return;
    }

    await _saveOpeningBalance(updatedBalanceNgwee);
  }

  Future<void> _saveOpeningBalance(int openingBalanceNgwee) async {
    final SupabaseClient? client = _client;
    final User? user = _currentUser;
    if (client == null || user == null) {
      return;
    }

    try {
      await client.from('profiles').upsert({
        'id': user.id,
        'opening_balance_ngwee': openingBalanceNgwee,
      }, onConflict: 'id');

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = (_profile ?? const _ProfileData()).copyWith(
          openingBalanceNgwee: openingBalanceNgwee,
        );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Opening balance updated.')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update opening balance.')),
      );
    }
  }

  String get _displayName {
    final User? user = _currentUser;
    final String? fromProfile = _profile?.fullName;
    if (fromProfile != null && fromProfile.trim().isNotEmpty) {
      return fromProfile.trim();
    }

    final Map<String, dynamic>? metadata = user?.userMetadata;
    final String? fromMetadata =
        metadata?['full_name'] as String? ?? metadata?['name'] as String?;
    if (fromMetadata != null && fromMetadata.trim().isNotEmpty) {
      return fromMetadata.trim();
    }

    final String? email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Student';
  }

  String? get _avatarUrl {
    final User? user = _currentUser;
    final String? fromProfile = _profile?.avatarUrl;
    if (fromProfile != null && fromProfile.trim().isNotEmpty) {
      return fromProfile.trim();
    }

    final Map<String, dynamic>? metadata = user?.userMetadata;
    final String? fromMetadata =
        metadata?['avatar_url'] as String? ?? metadata?['picture'] as String?;
    if (fromMetadata == null || fromMetadata.trim().isEmpty) {
      return null;
    }
    return fromMetadata.trim();
  }

  String get _subtitle {
    final String? email = _currentUser?.email;
    if (email == null || email.isEmpty) {
      return 'Student account';
    }
    return email;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double horizontalPadding = width >= 520 ? 28 : 20;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadPageData,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            14,
            horizontalPadding,
            28,
          ),
          children: [
            _ProfileHeader(
              displayName: _displayName,
              subtitle: _subtitle,
              avatarUrl: _avatarUrl,
              loading: _loadingProfile,
            ),
            if (_profileError != null) ...[
              const SizedBox(height: 12),
              Text(
                _profileError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            if (_snapshotError != null) ...[
              const SizedBox(height: 8),
              Text(
                _snapshotError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            if (_semesterGoalError != null) ...[
              const SizedBox(height: 8),
              Text(
                _semesterGoalError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 18),
            _MonthSwitcher(
              label: _monthLabel(_selectedMonth),
              onPrevious: _goToPreviousMonth,
              onNext: _goToNextMonth,
            ),
            const SizedBox(height: 12),
            _StudentSnapshotCard(
              monthLabel: _monthLabel(_selectedMonth),
              incomeNgwee: _monthlyIncomeNgwee,
              spentNgwee: _monthlySpentNgwee,
              loading: _loadingSnapshot,
            ),
            const SizedBox(height: 18),
            _SemesterGoalCard(
              targetNgwee: _semesterTargetNgwee,
              savedNgwee: _semesterSavedNgwee,
              semesterLabel: _semesterLabel(_selectedMonth),
              loading: _loadingSemesterGoal,
            ),
            const SizedBox(height: 18),
            const _HabitsCard(),
            const SizedBox(height: 18),
            _AccountCard(
              onEditProfile: _openEditNameSheet,
              savingProfile: _savingProfile,
              onEditSemesterGoal: _openEditSemesterTargetSheet,
              savingSemesterGoal: _savingSemesterTarget,
              onEditOpeningBalance: _openEditOpeningBalanceSheet,
            ),
          ],
        ),
      ),
    );
  }

  String _monthLabel(DateTime date) {
    const List<String> months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  DateTime _semesterStart(DateTime date) {
    if (date.month <= 6) {
      return DateTime(date.year, 1, 1);
    }
    return DateTime(date.year, 7, 1);
  }

  String _semesterLabel(DateTime date) {
    return date.month <= 6 ? 'Jan-Jun ${date.year}' : 'Jul-Dec ${date.year}';
  }

  Future<void> _goToPreviousMonth() async {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });
    await Future.wait<void>([
      _loadMonthlySnapshot(),
      _loadSemesterGoalSnapshot(),
    ]);
  }

  Future<void> _goToNextMonth() async {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
    });
    await Future.wait<void>([
      _loadMonthlySnapshot(),
      _loadSemesterGoalSnapshot(),
    ]);
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final Future<void> Function() onPrevious;
  final Future<void> Function() onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => onPrevious(),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          onPressed: () => onNext(),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _ProfileData {
  const _ProfileData({
    this.fullName,
    this.avatarUrl,
    this.semesterTargetNgwee,
    this.openingBalanceNgwee,
  });

  final String? fullName;
  final String? avatarUrl;
  final int? semesterTargetNgwee;
  final int? openingBalanceNgwee;

  _ProfileData copyWith({
    String? fullName,
    String? avatarUrl,
    int? semesterTargetNgwee,
    int? openingBalanceNgwee,
  }) {
    return _ProfileData(
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      semesterTargetNgwee: semesterTargetNgwee ?? this.semesterTargetNgwee,
      openingBalanceNgwee: openingBalanceNgwee ?? this.openingBalanceNgwee,
    );
  }

  factory _ProfileData.fromRow(Map<String, dynamic>? row) {
    if (row == null) {
      return const _ProfileData();
    }

    return _ProfileData(
      fullName: row['full_name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      semesterTargetNgwee: (row['semester_target_ngwee'] as num?)?.toInt(),
      openingBalanceNgwee: (row['opening_balance_ngwee'] as num?)?.toInt(),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.subtitle,
    required this.avatarUrl,
    required this.loading,
  });

  final String displayName;
  final String subtitle;
  final String? avatarUrl;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        _Avatar(avatarUrl: avatarUrl),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loading ? 'Loading profile...' : displayName,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = avatarUrl;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl,
          width: 68,
          height: 68,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return _AvatarFallback();
          },
        ),
      );
    }

    return _AvatarFallback();
  }
}

class _AvatarFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF6EA8FE), Color(0xFF57D4AD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
    );
  }
}

class _StudentSnapshotCard extends StatelessWidget {
  const _StudentSnapshotCard({
    required this.monthLabel,
    required this.incomeNgwee,
    required this.spentNgwee,
    required this.loading,
  });

  final String monthLabel;
  final int incomeNgwee;
  final int spentNgwee;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      borderRadius: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Finance Snapshot',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            loading ? 'Loading monthly totals...' : monthLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricCell(
                  label: 'Income',
                  valueNgwee: incomeNgwee,
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MetricCell(
                  label: 'Spent',
                  valueNgwee: spentNgwee,
                  icon: Icons.trending_down_rounded,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.valueNgwee,
    required this.icon,
    required this.color,
  });

  final String label;
  final int valueNgwee;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            formatZmwFromNgwee(valueNgwee),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _SemesterGoalCard extends StatelessWidget {
  const _SemesterGoalCard({
    required this.targetNgwee,
    required this.savedNgwee,
    required this.semesterLabel,
    required this.loading,
  });

  final int targetNgwee;
  final int savedNgwee;
  final String semesterLabel;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final int effectiveTarget = targetNgwee <= 0 ? 1 : targetNgwee;
    final double ratio = (savedNgwee / effectiveTarget).clamp(0.0, 1.0);
    final bool negativeSavings = savedNgwee < 0;
    final String subtitle = loading
        ? 'Loading semester totals...'
        : '${formatZmwFromNgwee(savedNgwee)} of ${formatZmwFromNgwee(targetNgwee)}';
    final String statusText = loading
        ? 'Loading progress...'
        : negativeSavings
        ? '${formatZmwFromNgwee(savedNgwee.abs())} below zero | Keep reducing expenses'
        : '${(ratio * 100).toStringAsFixed(0)}% complete | Keep logging weekly expenses';

    return SectionCard(
      borderRadius: 10,
      backgroundColor: AppColors.cardDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semester Savings Goal',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            semesterLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentYellow,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: negativeSavings ? AppColors.danger : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitsCard extends StatelessWidget {
  const _HabitsCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      borderRadius: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _CardTitle(title: 'Money Habits'),
          SizedBox(height: 10),
          _HabitRow(
            label: 'Daily expense logging',
            status: 'On track',
            complete: true,
          ),
          SizedBox(height: 10),
          _HabitRow(
            label: 'Weekend spend review',
            status: 'Due in 2 days',
            complete: false,
          ),
          SizedBox(height: 10),
          _HabitRow(
            label: 'Campus meal budget',
            status: 'Within budget',
            complete: true,
          ),
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.label,
    required this.status,
    required this.complete,
  });

  final String label;
  final String status;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAF7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            complete ? Icons.check_circle_rounded : Icons.schedule_rounded,
            color: complete ? AppColors.success : AppColors.accentOrange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(status, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.onEditProfile,
    required this.savingProfile,
    required this.onEditSemesterGoal,
    required this.savingSemesterGoal,
    required this.onEditOpeningBalance,
  });

  final Future<void> Function() onEditProfile;
  final bool savingProfile;
  final Future<void> Function() onEditSemesterGoal;
  final bool savingSemesterGoal;
  final Future<void> Function() onEditOpeningBalance;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      borderRadius: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(title: 'Account'),
          const SizedBox(height: 6),
          _AccountRow(
            icon: Icons.edit_outlined,
            label: savingProfile ? 'Saving profile...' : 'Edit profile name',
            onTap: savingProfile ? null : () => onEditProfile(),
          ),
          _AccountRow(
            icon: Icons.flag_outlined,
            label: savingSemesterGoal
                ? 'Saving semester goal...'
                : 'Edit semester savings goal',
            onTap: savingSemesterGoal ? null : () => onEditSemesterGoal(),
          ),
          _AccountRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Edit opening balance',
            onTap: () => onEditOpeningBalance(),
          ),
          const _AccountRow(
            icon: Icons.school_outlined,
            label: 'University details',
          ),
          const _AccountRow(
            icon: Icons.notifications_none_rounded,
            label: 'Reminder preferences',
          ),
          const _AccountRow(
            icon: Icons.lock_outline_rounded,
            label: 'Privacy and security',
          ),
          const _AccountRow(
            icon: Icons.help_outline_rounded,
            label: 'Help center',
          ),
          const _SignOutRow(),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineMedium);
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _SignOutRow extends StatelessWidget {
  const _SignOutRow();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Supabase.instance.client.auth.signOut();
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: const [
            Icon(Icons.logout_rounded, color: AppColors.danger),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sign out',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
