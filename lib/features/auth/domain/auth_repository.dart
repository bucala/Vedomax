class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

abstract interface class AuthRepository {
  Stream<String?> watchUserId();
  String? get userId;
  Future<void> signIn(String email, String password);
  Future<bool> signUp(String email, String password);
  Future<void> resendConfirmation(String email);
  Future<void> signOut();
}
