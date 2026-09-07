import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_service.dart';

class LevelProgress {
  const LevelProgress({this.completed = false, this.bestScore = 0, this.bestTime, this.attempts = 0});

  final bool completed;
  final int bestScore;
  final double? bestTime;
  final int attempts;

  LevelProgress copyWith({bool? completed, int? bestScore, double? bestTime, int? attempts}) => LevelProgress(
        completed: completed ?? this.completed,
        bestScore: bestScore ?? this.bestScore,
        bestTime: bestTime ?? this.bestTime,
        attempts: attempts ?? this.attempts,
      );

  Map<String, dynamic> toJson() => {
        'completed': completed,
        'bestScore': bestScore,
        'bestTime': bestTime,
        'attempts': attempts,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> json) => LevelProgress(
        completed: json['completed'] == true,
        bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
        bestTime: (json['bestTime'] as num?)?.toDouble(),
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      );
}

class ProgressState {
  ProgressState(this.levels);

  final Map<int, LevelProgress> levels;

  int get totalCompleted => levels.values.where((entry) => entry.completed).length;
  int get highestUnlocked {
    var unlocked = 1;
    while (levels[unlocked]?.completed == true && unlocked < 15) {
      unlocked++;
    }
    return unlocked;
  }

  LevelProgress forLevel(int id) => levels[id] ?? const LevelProgress();
}

class ProgressRepository {
  ProgressRepository._();
  static final instance = ProgressRepository._();
  static const _storageKey = 'darktrace.progress.v1';

  Future<ProgressState> load() async {
    final preferences = await SharedPreferences.getInstance();
    final local = _decode(preferences.getString(_storageKey));
    final cloudRows = await SupabaseService.instance.loadProgress();
    final cloud = cloudRows.map((id, row) => MapEntry(id, LevelProgress(
          completed: row['completed'] == true,
          bestScore: (row['best_score'] as num?)?.toInt() ?? 0,
          bestTime: (row['best_time'] as num?)?.toDouble(),
          attempts: (row['attempts'] as num?)?.toInt() ?? 0,
        )));
    final merged = <int, LevelProgress>{};
    for (var id = 1; id <= 15; id++) {
      final localEntry = local[id] ?? const LevelProgress();
      final cloudEntry = cloud[id] ?? const LevelProgress();
      merged[id] = LevelProgress(
        completed: localEntry.completed || cloudEntry.completed,
        bestScore: localEntry.bestScore > cloudEntry.bestScore ? localEntry.bestScore : cloudEntry.bestScore,
        bestTime: _bestTime(localEntry.bestTime, cloudEntry.bestTime),
        attempts: localEntry.attempts > cloudEntry.attempts ? localEntry.attempts : cloudEntry.attempts,
      );
    }
    final state = ProgressState(merged);
    await _write(state);
    return state;
  }

  Future<ProgressState> recordAttempt(ProgressState state, int levelId, {required int score, required double time}) async {
    final current = state.forLevel(levelId);
    final updated = ProgressState({...state.levels, levelId: current.copyWith(
      completed: true,
      bestScore: score > current.bestScore ? score : current.bestScore,
      bestTime: _bestTime(current.bestTime, time),
      attempts: current.attempts + 1,
    )});
    await _write(updated);
    await SupabaseService.instance.submitLevelScore(level: levelId, score: score, time: time, stars: 1, coins: 0);
    return updated;
  }

  Map<int, LevelProgress> _decode(String? value) {
    if (value == null || value.isEmpty) return {};
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(int.parse(key), LevelProgress.fromJson(Map<String, dynamic>.from(value as Map))));
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(ProgressState state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(state.levels.map((key, value) => MapEntry('$key', value.toJson()))));
  }

  double? _bestTime(double? first, double? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first < second ? first : second;
  }
}
