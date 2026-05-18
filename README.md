# SmartBudget App

Flutter mobile app backed by Supabase authentication and database tables.

## Run on a physical device (Android)

1. Connect your phone with USB debugging enabled.
2. Verify Flutter sees the device:

```bash
flutter devices
```

3. Run the app using your Supabase project values:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_ANON_KEY
```

## Build installable APKs

Debug APK:

```bash
flutter build apk --debug
```

Release APK:

```bash
flutter build apk --release
```

Output files:

- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/flutter-apk/app-release.apk`

## Supabase backend checklist

- Run your SQL migrations in `supabase/migrations/`.
- Confirm `profiles`, `transactions`, and `budget_limits` tables exist.
- Confirm RLS policies allow authenticated users to read/write their own rows.
- Use the same Supabase project URL/key values in your Flutter run/build command.
