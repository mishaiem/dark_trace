import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  bool enabled = false;
  SupabaseClient? get client => enabled ? Supabase.instance.client : null;

  Future<void> initialize() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isEmpty || anonKey.isEmpty) return;
    await Supabase.initialize(url: url, publishableKey: anonKey);
    enabled = true;
  }

  Future<void> signOut() async => client?.auth.signOut();

  Future<Map<int, Map<String, dynamic>>> loadProgress() async {
    final user = client?.auth.currentUser;
    if (user == null) return {};
    try {
      final rows = await client!.from('player_progress').select('level_id,best_score,best_time,attempts,completed').eq('user_id', user.id);
      return {for (final row in rows) row['level_id'] as int: Map<String, dynamic>.from(row)};
    } catch (_) {
      return {};
    }
  }

  Future<void> submitLevelScore({required int level, required int score, required double time, required int stars, required int coins}) async {
    final user = client?.auth.currentUser;
    if (user == null) return;
    await client!.rpc('submit_level_score', params: {
      'p_level_id': level,
      'p_score': score,
      'p_time': time,
      'p_stars': stars,
      'p_coins': coins,
    });
  }
}
