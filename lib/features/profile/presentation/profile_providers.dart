import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/supabase_profile_repository.dart';
import '../domain/profile.dart';
final profileRepositoryProvider = Provider<ProfileRepository>((Ref ref) => SupabaseProfileRepository(ref.watch(supabaseProvider)));
final profileProvider = FutureProvider<Profile?>((Ref ref) async {
  final String? id = ref.watch(authStateProvider).valueOrNull;
  return id == null ? null : ref.watch(profileRepositoryProvider).load(id);
});
