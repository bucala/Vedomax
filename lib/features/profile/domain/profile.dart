class Profile {
  const Profile({required this.username, required this.xp, required this.streak});
  final String username;
  final int xp;
  final int streak;
}
abstract interface class ProfileRepository {
  Future<Profile> load(String userId);
  Future<void> updateUsername(String userId, String username);
}
