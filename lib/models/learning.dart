import 'dart:math' as math;

enum QuestionKind { choice, number, map }

class GeoPoint {
  const GeoPoint(this.lat, this.lon);
  final double lat;
  final double lon;
  Map<String, double> toJson() => {'lat': lat, 'lon': lon};
  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
    (json['lat'] as num).toDouble(),
    (json['lon'] as num).toDouble(),
  );
}

double distanceKm(GeoPoint a, GeoPoint b) {
  const radians = math.pi / 180;
  final dLat = (b.lat - a.lat) * radians;
  final dLon = (b.lon - a.lon) * radians;
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(a.lat * radians) *
          math.cos(b.lat * radians) *
          math.pow(math.sin(dLon / 2), 2);
  return 6371.0088 * 2 * math.asin(math.sqrt(h.clamp(0, 1)));
}

int mapPoints(double distance, double fullCreditKm, double zeroCreditKm) =>
    (100 * (1 - (distance - fullCreditKm) / (zeroCreditKm - fullCreditKm)))
        .clamp(0, 100)
        .round();

double? parseAnswer(String text) {
  final clean = text.trim().replaceAll(',', '.');
  if (!RegExp(r'^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$').hasMatch(clean)) return null;
  final value = double.tryParse(clean);
  return value != null && value.isFinite ? value : null;
}

class Question {
  const Question({
    required this.id,
    required this.prompt,
    required this.kind,
    required this.solution,
    required this.explanation,
    required this.topic,
    required this.source,
    required this.section,
    this.options = const [],
    this.answer,
    this.target,
    this.region = 'sk',
    this.unit = '',
    this.fullCreditKm = 10,
    this.zeroCreditKm = 250,
  });
  final String id,
      prompt,
      solution,
      explanation,
      topic,
      source,
      section,
      region,
      unit;
  final QuestionKind kind;
  final List<String> options;
  final num? answer;
  final GeoPoint? target;
  final double fullCreditKm, zeroCreditKm;
  factory Question.fromJson(Map<String, dynamic> j) => Question(
    id: j['id'],
    prompt: j['prompt'],
    kind: QuestionKind.values.byName(j['kind']),
    solution: j['solution'],
    explanation: j['explanation'],
    topic: j['topic'],
    source: j['source'],
    section: j['section'],
    options: List<String>.from(j['options'] ?? []),
    answer: j['answer'],
    target: j['target'] == null ? null : GeoPoint.fromJson(j['target']),
    region: j['region'] ?? 'sk',
    unit: j['unit'] ?? '',
    fullCreditKm: (j['fullCreditKm'] as num? ?? 10).toDouble(),
    zeroCreditKm: (j['zeroCreditKm'] as num? ?? 250).toDouble(),
  );

  AnswerFeedback grade(Object value) {
    double? distance;
    int points;
    if (kind == QuestionKind.map) {
      distance = distanceKm(value as GeoPoint, target!);
      points = mapPoints(distance, fullCreditKm, zeroCreditKm);
    } else if (kind == QuestionKind.number) {
      points = value is num && value.isFinite && (value - answer!).abs() <= 0.01
          ? 100
          : 0;
    } else {
      points = value == answer ? 100 : 0;
    }
    return AnswerFeedback(
      points: points,
      solution: solution,
      explanation: explanation,
      target: target,
      distance: distance,
      correctIndex: kind == QuestionKind.choice ? answer?.toInt() : null,
    );
  }
}

class AnswerFeedback {
  const AnswerFeedback({
    required this.points,
    required this.solution,
    required this.explanation,
    this.target,
    this.distance,
    this.correctIndex,
  });
  final int points;
  final String solution, explanation;
  final GeoPoint? target;
  final double? distance;
  final int? correctIndex;
  factory AnswerFeedback.fromJson(Map<String, dynamic> j) => AnswerFeedback(
    points: (j['points'] as num).round(),
    solution: j['solution'],
    explanation: j['explanation'],
    target: j['target'] == null ? null : GeoPoint.fromJson(j['target']),
    distance: (j['distance'] as num?)?.toDouble(),
    correctIndex: (j['correctIndex'] as num?)?.toInt(),
  );
}

class DailyLesson {
  const DailyLesson({
    required this.id,
    required this.grade,
    required this.day,
    required this.subject,
    required this.title,
    required this.questions,
  });
  final int id, grade, day;
  final String subject, title;
  final List<Question> questions;
  factory DailyLesson.fromJson(Map<String, dynamic> j) => DailyLesson(
    id: j['id'],
    grade: j['grade'],
    day: j['day'],
    subject: j['subject'],
    title: j['title'],
    questions: (j['questions'] as List)
        .map((q) => Question.fromJson(q))
        .toList(),
  );
}

class PlayerProfile {
  const PlayerProfile({
    required this.username,
    this.xp = 0,
    this.streak = 0,
    this.visible = false,
  });
  final String username;
  final int xp, streak;
  final bool visible;
}
