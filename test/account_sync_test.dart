import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vedomax/services/app_store.dart';

const fixtureId = '30000000-0000-4000-8000-000000000001';

void main() {
  test(
    'account reads server profile and server rewards; guest XP stays separate',
    () async {
      SharedPreferences.setMockInitialValues({
        'v2_progress_guest': jsonEncode({'80010': 100}),
      });
      var username = 'ServerovyHrac';
      var xp = 500;
      var visible = false;
      var gradingCalls = 0;
      final token =
          '${base64Url.encode(utf8.encode('{"alg":"HS256"}')).replaceAll('=', '')}.${base64Url.encode(utf8.encode(jsonEncode({'sub': fixtureId, 'role': 'authenticated', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600}))).replaceAll('=', '')}.fixture';
      final client = SupabaseClient(
        'https://fixture.invalid',
        'fixture-publishable-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          Object? result;
          final path = request.url.path;
          if (path == '/auth/v1/token') {
            result = {
              'access_token': token,
              'refresh_token': 'fixture-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': fixtureId,
                'aud': 'authenticated',
                'role': 'authenticated',
                'email': 'fixture@example.test',
                'app_metadata': {'provider': 'email'},
                'user_metadata': {},
                'created_at': '2026-10-26T00:00:00Z',
              },
            };
          } else if (path == '/rest/v1/profiles') {
            expect(request.url.queryParameters['id'], 'eq.$fixtureId');
            if (request.method == 'PATCH') {
              final data = jsonDecode(request.body);
              username = data['username'];
              visible = data['leaderboard_visible'];
              return http.Response('', 204, request: request);
            }
            result = {
              'id': fixtureId,
              'username': username,
              'experience_points': xp,
              'streak_days': 3,
              'leaderboard_visible': visible,
            };
          } else if (path == '/rest/v1/user_progression') {
            expect(request.url.queryParameters['user_id'], 'eq.$fixtureId');
            result = [
              {'lesson_id': 80010, 'high_score': 75},
            ];
          } else if (path == '/rest/v1/rpc/complete_daily_lesson') {
            gradingCalls++;
            xp += 25;
            result = {'score': 100, 'xp_awarded': 25};
          } else if (path == '/rest/v1/rpc/leaderboard') {
            result = [
              {'username': username, 'experience_points': xp},
            ];
          } else if (path == '/auth/v1/logout') {
            return http.Response('', 204, request: request);
          } else {
            throw StateError(
              'Unexpected fixture request: ${request.method} $path',
            );
          }
          return http.Response(
            jsonEncode(result),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'fixture@example.test',
        password: 'fixture-only',
      );
      final prefs = await SharedPreferences.getInstance();
      final store = AppStore(prefs, client: client);
      await store.initialize();
      expect(store.signedIn, isTrue);
      expect(store.profile.xp, 500);
      expect(store.best(80010), 75);
      final lesson = store.lessons.first;
      final results = lesson.questions.map((q) => q.grade(q.answer!)).toList();
      expect(await store.completeLesson(lesson, results), 25);
      expect(gradingCalls, 1);
      expect(store.profile.xp, 525);
      await store.updateProfile('NovaPrezyvka', true);
      expect(store.profile.username, 'NovaPrezyvka');
      expect(store.profile.visible, isTrue);
      await store.loadLeaderboard();
      expect(store.leaderboard.length, 1);
      expect(store.leaderboard.first['experience_points'], 525);
      await client.auth.signOut();
      await store.refreshProfile();
      expect(store.signedIn, isFalse);
      expect(store.profile.xp, 100);
      expect(store.profile.username, 'Prieskumník');
    },
  );
}
