import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/lesson.dart';
class SupabaseLearningRepository implements LearningRepository {
  SupabaseLearningRepository(this.client);
  final SupabaseClient client;
  @override
  Future<List<Lesson>> lessons() async {
    final List<Map<String, dynamic>> rows = await client.from('lessons').select('*,questions(*)').order('id');
    return rows.map((Map<String, dynamic> row) {
      final List<Map<String, dynamic>> questions = (row['questions'] as List<dynamic>).cast<Map<String, dynamic>>()..sort((Map<String, dynamic> a, Map<String, dynamic> b) => (a['order_index'] as int).compareTo(b['order_index'] as int));
      return Lesson(id: row['id'] as int, title: row['title_sk'] as String, seconds: row['time_limit_seconds'] as int, animation: row['lottie_asset_path'] as String,
        questions: questions.map((Map<String, dynamic> q) => Question(id: q['id'] as String, text: q['question_text_sk'] as String, mechanic: q['mechanic_type'] as String, content: q['content_json'] as Map<String, dynamic>)).toList());
    }).toList();
  }
  @override
  Future<DateTime> begin(int lessonId) async => DateTime.parse(await client.rpc('begin_lesson', params: <String, Object>{'p_lesson_id': lessonId}) as String);
  @override
  Future<LessonResult> submit(int lessonId, Map<String, Object> answers) async {
    final Map<String, dynamic> result = Map<String, dynamic>.from(await client.rpc('submit_lesson', params: <String, Object>{'p_lesson_id': lessonId, 'p_answers': answers}) as Map);
    return LessonResult(result['score'] as int, result['xp_awarded'] as int);
  }
}
class DemoLearningRepository implements LearningRepository {
  @override
  Future<List<Lesson>> lessons() async => demoLessons;
  @override
  Future<DateTime> begin(int lessonId) async => DateTime.now().add(Duration(seconds: demoLessons.firstWhere((Lesson l) => l.id == lessonId).seconds));
  @override
  Future<LessonResult> submit(int lessonId, Map<String, Object> answers) async {
    final bool correct;
    switch (lessonId) {
      case 1: correct = answers['math'] is num && ((answers['math'] as num) - 5).abs() <= 0.01;
      case 2:
        final Set<int> selected = (answers['detective'] as List<int>).toSet();
        correct = selected.length == 2 && selected.containsAll(<int>{1, 5});
      case 3:
        final Map<String, double> point = answers['geo'] as Map<String, double>;
        correct = ((point['x']! - 0.307) * (point['x']! - 0.307) + (point['y']! - 0.424) * (point['y']! - 0.424)) <= 0.0036;
      default: correct = false;
    }
    return LessonResult(correct ? 100 : 0, 0); // Demo never awards persistent XP.
  }
}
const List<Lesson> demoLessons = <Lesson>[
  Lesson(id: 1, title: 'Matematika • Zachráň prieskumníka', seconds: 120, questions: <Question>[
    Question(id: 'math', text: 'Rebrík vedie k prieskumníkovi. Stena má výšku 4 m a päta rebríka je 3 m od steny. Aký dlhý musí byť rebrík?', mechanic: 'puzzle_calc', content: <String, dynamic>{'a': 3, 'b': 4}),
  ]),
  Lesson(id: 2, title: 'Slovenčina • Vetriť chybu', seconds: 30, questions: <Question>[
    Question(id: 'detective', text: 'Odhaľ dve pravopisné chyby v príspevku.', mechanic: 'detective', content: <String, dynamic>{'words': <String>['Moji', 'kamarátiy', 'dnes', 'navštívili', 'hrad.', 'Bolily', 'nadšení!'], 'error_indices': <int>[1, 5]}),
  ]),
  Lesson(id: 3, title: 'Geografia • Slepá mapa', seconds: 60, questions: <Question>[
    Question(id: 'geo', text: 'Kde sa nachádza Bojnický zámok?', mechanic: 'geo_click', content: <String, dynamic>{'map': 'assets/maps/slovakia.png'}),
  ]),
];
