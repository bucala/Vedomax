class Question {
  const Question({required this.id, required this.text, required this.mechanic, required this.content});
  final String id;
  final String text;
  final String mechanic;
  final Map<String, dynamic> content;
}
class Lesson {
  const Lesson({required this.id, required this.title, required this.seconds, required this.questions, this.animation = 'assets/animations/success.json'});
  final int id;
  final String title;
  final int seconds;
  final List<Question> questions;
  final String animation;
}
class LessonResult {
  const LessonResult(this.score, this.xp);
  final int score;
  final int xp;
}
abstract interface class LearningRepository {
  Future<List<Lesson>> lessons();
  Future<DateTime> begin(int lessonId);
  Future<LessonResult> submit(int lessonId, Map<String, Object> answers);
}
