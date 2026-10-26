import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (Ref ref) => SupabaseAuthRepository(ref.watch(supabaseProvider)),
);
final authStateProvider = StreamProvider<String?>(
  (Ref ref) => ref.watch(authRepositoryProvider).watchUserId(),
);
