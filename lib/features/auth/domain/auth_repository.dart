class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

abstract interface class AuthRepository {
  Stream<String?> watchUserId();
  String? get userId;
  bool get supportsGoogle;
  Future<void> signIn(String email, String password);
  Future<bool> signUp(String email, String password);
  Future<bool> signInWithGoogle();
  Future<void> resendConfirmation(String email);
  Future<void> signOut();
}
