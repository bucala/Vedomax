import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/learning.dart';
import 'legacy_cleanup.dart';

class AppStore extends ChangeNotifier {
  AppStore(this.prefs, {this.client, DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  final SharedPreferences prefs;
  final SupabaseClient? client;
  List<DailyLesson> lessons = [];
  List<List<GeoPoint>> polygons = [];
  List<List<GeoPoint>> slovakiaPolygons = [];
  PlayerProfile profile = const PlayerProfile(username: 'Prieskumník');
  List<Map<String, dynamic>> leaderboard = [];
  String? syncError;
  String? _profileOwner;
  bool get signedIn => client?.auth.currentUser != null;
  String? get userId => client?.auth.currentUser?.id;
  int get grade => prefs.getInt('v2_grade') ?? 8;
  ThemeMode get theme =>
      ThemeMode.values[prefs.getInt('v2_theme')?.clamp(0, 2) ?? 0];
  bool get reducedMotion => prefs.getBool('v2_reduced_motion') ?? false;
  bool get haptics => prefs.getBool('v2_haptics') ?? true;
  int get dailyGoal => prefs.getInt('v2_goal') ?? 12;
  DateTime get localDay {
    final now = tz.TZDateTime.from(_now(), tz.getLocation('Europe/Bratislava'));
    return DateTime.utc(now.year, now.month, now.day);
  }

  String get _owner => userId ?? 'guest';
  String get _progressKey => 'v2_progress_$_owner';
  Map<String, dynamic> get progress {
    try {
      return jsonDecode(prefs.getString(_progressKey) ?? '{}');
    } catch (_) {
      return {};
    }
  }

  int get currentDay {
    final start =
        DateTime.tryParse(prefs.getString('v2_start_$grade') ?? '') ?? localDay;
    return (localDay.difference(start).inDays + 1).clamp(1, 14);
  }

  int best(int id) => (progress['$id'] as num?)?.toInt() ?? 0;
  bool completed(int id) => progress.containsKey('$id');
  int completedOn(int day) => lessons
      .where((l) => l.grade == grade && l.day == day && completed(l.id))
      .length;
  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    final json = jsonDecode(
      await rootBundle.loadString('assets/content/fortnight.json'),
    );
    lessons = (json['lessons'] as List)
        .map((l) => DailyLesson.fromJson(l))
        .toList();
    final world = jsonDecode(
      await rootBundle.loadString('assets/maps/countries.geojson'),
    );
    for (final f in world['features']) {
      final geometry = f['geometry'];
      final parts = geometry['type'] == 'Polygon'
          ? [geometry['coordinates']]
          : geometry['coordinates'];
      for (final part in parts) {
        for (final ring in part) {
          polygons.add(
            (ring as List)
                .map(
                  (p) => GeoPoint(
                    (p[1] as num).toDouble(),
                    (p[0] as num).toDouble(),
                  ),
                )
                .toList(),
          );
          if (f['properties']['ADM0_A3'] == 'SVK') {
            slovakiaPolygons.add(polygons.last);
          }
        }
      }
    }
    for (final grade in [8, 9]) {
      if (!prefs.containsKey('v2_start_$grade')) {
        await prefs.setString('v2_start_$grade', localDay.toIso8601String());
      }
    }
    // Remove obsolete plaintext mock credentials; no password-based local accounts remain.
    await prefs.remove('vedomax_accounts');
    await prefs.remove('vedomax_current_user');
    removeLegacyCredentials();
    await refreshProfile();
  }

  Future<void> setting(String name, Object value) async {
    if (value is int) await prefs.setInt('v2_$name', value);
    if (value is bool) await prefs.setBool('v2_$name', value);
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final owner = _owner;
    syncError = null;
    if (signedIn) {
      try {
        final row = await client!
            .from('profiles')
            .select()
            .eq('id', owner)
            .single();
        final rows = await client!
            .from('user_progression')
            .select('lesson_id,high_score')
            .eq('user_id', owner);
        if (_owner != owner) return;
        profile = PlayerProfile(
          username: row['username'],
          xp: row['experience_points'],
          streak: row['streak_days'],
          visible: row['leaderboard_visible'] ?? false,
        );
        await prefs.setString(
          _progressKey,
          jsonEncode({
            for (final r in rows) '${r['lesson_id']}': r['high_score'],
          }),
        );
        _profileOwner = owner;
      } catch (_) {
        if (_owner != owner) return;
        if (_profileOwner != owner) {
          profile = const PlayerProfile(username: 'Hráč');
        }
        syncError =
            'Profil sa nepodarilo synchronizovať. Skontroluj pripojenie a skús znova.';
      }
    } else {
      _profileOwner = owner;
      final last = DateTime.tryParse(prefs.getString('v2_last_guest') ?? '');
      final streak = last == null || localDay.difference(last).inDays > 1
          ? 0
          : prefs.getInt('v2_streak_guest') ?? 0;
      profile = PlayerProfile(
        username: prefs.getString('v2_nickname') ?? 'Prieskumník',
        xp: progress.values.fold<int>(
          0,
          (sum, value) => sum + (value as num).toInt(),
        ),
        streak: streak,
      );
    }
    notifyListeners();
  }

  Future<int> completeLesson(
    DailyLesson lesson,
    List<AnswerFeedback> results,
  ) async {
    final score =
        (results.fold<int>(0, (s, r) => s + r.points) / results.length).round();
    if (signedIn) {
      final result = await client!.rpc(
        'complete_daily_lesson',
        params: {'p_lesson_id': lesson.id},
      );
      await refreshProfile();
      return (result['xp_awarded'] as num).toInt();
    }
    final old = best(lesson.id);
    final p = progress;
    p['${lesson.id}'] = score > old ? score : old;
    await prefs.setString(_progressKey, jsonEncode(p));
    final today = localDay;
    final last = DateTime.tryParse(prefs.getString('v2_last_guest') ?? '');
    final streak = last == today
        ? prefs.getInt('v2_streak_guest') ?? 1
        : last == today.subtract(const Duration(days: 1))
        ? (prefs.getInt('v2_streak_guest') ?? 0) + 1
        : 1;
    await prefs.setInt('v2_streak_guest', streak);
    await prefs.setString('v2_last_guest', today.toIso8601String());
    await refreshProfile();
    return (score - old).clamp(0, 100);
  }

  Future<void> begin(DailyLesson lesson) async {
    if (signedIn) {
      await client!.rpc(
        'start_daily_lesson',
        params: {'p_lesson_id': lesson.id},
      );
    }
  }

  Future<AnswerFeedback> answer(
    DailyLesson lesson,
    Question q,
    Object answer,
  ) async {
    if (!signedIn) return q.grade(answer);
    final result = await client!.rpc(
      'answer_daily_question',
      params: {
        'p_lesson_id': lesson.id,
        'p_question_id': q.id,
        'p_answer': answer is GeoPoint ? answer.toJson() : answer,
      },
    );
    return AnswerFeedback.fromJson(Map<String, dynamic>.from(result));
  }

  Future<void> updateProfile(String nickname, bool visible) async {
    final name = nickname.trim();
    if (name.length < 3 || name.length > 24) {
      throw ArgumentError('Prezývka má mať 3 až 24 znakov.');
    }
    if (signedIn) {
      await client!
          .from('profiles')
          .update({'username': name, 'leaderboard_visible': visible})
          .eq('id', userId!);
    } else {
      await prefs.setString('v2_nickname', name);
    }
    await refreshProfile();
  }

  Future<void> loadLeaderboard() async {
    if (!signedIn) {
      leaderboard = [];
      return;
    }
    final data = await client!.rpc('leaderboard');
    leaderboard = List<Map<String, dynamic>>.from(data);
    notifyListeners();
  }
}
