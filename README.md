# DARKTRACE

A Flutter + Flame puzzle/action game built around `LIGHT -> PLAYER -> SHADOW`.

## Run

```powershell
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

The app starts in offline mode when those defines are absent, so the local level path remains playable. Run [supabase/schema.sql](supabase/schema.sql) in the Supabase SQL Editor before using cloud profiles and progress. The schema uses RLS and a `security definer` score RPC; never place a service-role key in the app.

The first vertical slice includes the responsive shell, 30 level definitions, keyboard-ready Flame gameplay, projected shadow rendering, level hazards/coins/exit, lives, scoring, and a cloud progress boundary. Further level configuration can be loaded by replacing `seedLevels()` with rows from `levels.config` JSONB.
