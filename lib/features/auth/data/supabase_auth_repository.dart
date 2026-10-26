import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_repository.dart';
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client);
  final SupabaseClient client;
  @override
  String? get userId => client.auth.currentUser?.id;
  @override
  Stream<String?> watchUserId() async* {
    yield userId;
    yield* client.auth.onAuthStateChange.map((AuthState state) => state.session?.user.id);
  }
  @override
  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }
  @override
  Future<bool> signUp(String email, String password) async {
    final AuthResponse response = await client.auth.signUp(email: email, password: password);
    return response.session != null;
  }
  @override
  Future<void> signOut() => client.auth.signOut();
}
