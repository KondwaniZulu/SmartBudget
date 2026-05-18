class SupabaseConfig {
  static const String _rawUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jrqxrqupazukjmbpdjyh.supabase.co',
  );

  static const String _rawPublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_xq6b1gEdbCh5cpuZFf5RPA_645SLPyn',
  );

  static String _sanitizeBuildValue(String raw) {
    String value = raw.trim();

    // Some build scripts pass dart-defines wrapped like ['value'] or "value".
    bool changed = true;
    while (changed && value.isNotEmpty) {
      changed = false;
      if ((value.startsWith('[') && value.endsWith(']')) ||
          (value.startsWith('(') && value.endsWith(')'))) {
        value = value.substring(1, value.length - 1).trim();
        changed = true;
      }
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1).trim();
        changed = true;
      }
    }

    return value.replaceAll(RegExp(r'\s+'), '');
  }

  static String get url {
    final String compact = _sanitizeBuildValue(_rawUrl);
    final Uri? parsed = Uri.tryParse(compact);
    if (parsed == null || parsed.host.isEmpty || !parsed.hasScheme) {
      throw StateError('Invalid SUPABASE_URL: "$_rawUrl"');
    }
    final String normalized = parsed.toString();
    return normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
  }

  static String get publishableKey => _sanitizeBuildValue(_rawPublishableKey);
}
