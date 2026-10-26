import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/profile.dart';
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this.client);
  final SupabaseClient client;
  @override
  Future<Profile> load(String userId) async {
    final Map<String, dynamic> row = await client.from('profiles').select('username,experience_points,streak_days').eq('id', userId).single();
    return Profile(username: row['username'] as String, xp: row['experience_points'] as int, streak: row['streak_days'] as int);
  }
  @override
  Future<void> updateUsername(String userId, String username) async {
    await client.from('profiles').update(<String, Object>{'username': username}).eq('id', userId);
  }
}
