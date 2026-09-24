// Eventos de estadísticas tal como los devuelve GET /api/stats/me/events:
// cada finalización y cada cosa creada, sueltas. La app los agrupa en días,
// semanas o meses (core/stats_series.dart).
//
// Las fechas llegan en UTC y se pasan aquí a hora local: los cubos comparan
// año, mes y día, y una finalización a las 22:00 en Colombia ya es del día
// siguiente en UTC.

class ExerciseCompletionEvent {
  final String exerciseId;
  final DateTime completedAt;
  final int? session;
  final String category;
  // Códigos distintos de golpe y rotación de sus pasos. Llegan en el evento
  // porque el ejercicio puede estar borrado y no estar en ExercisesState.
  final List<int> hits;
  final List<int> rotations;
  final bool deleted;

  const ExerciseCompletionEvent({
    required this.exerciseId,
    required this.completedAt,
    required this.session,
    required this.category,
    required this.hits,
    required this.rotations,
    required this.deleted,
  });
}

class TrainingCompletionEvent {
  final String trainingId;
  final DateTime completedAt;
  final int? session;
  final int? duration;

  const TrainingCompletionEvent({
    required this.trainingId,
    required this.completedAt,
    required this.session,
    required this.duration,
  });
}

enum CreatedKind { exercise, training }

class CreatedEvent {
  final CreatedKind kind;
  final String id;
  final DateTime createdAt;

  const CreatedEvent({required this.kind, required this.id, required this.createdAt});
}

class StatsEvents {
  final List<ExerciseCompletionEvent> exerciseCompletions;
  final List<TrainingCompletionEvent> trainingCompletions;
  final List<CreatedEvent> created;

  const StatsEvents({
    this.exerciseCompletions = const [],
    this.trainingCompletions = const [],
    this.created = const [],
  });
}

/// Lee `{ success, data: { exerciseCompletions, trainingCompletions, created } }`.
///
/// Es la frontera con el backend: una entrada con un campo obligatorio que
/// falta o no se entiende se descarta en vez de romper toda la pantalla. Sin
/// `data` no hay nada que enseñar, y eso sí es un error.
StatsEvents parseStatsEvents(Object? body) {
  final data = body is Map ? body['data'] : null;
  if (data is! Map) {
    throw const FormatException('Respuesta de estadísticas sin data');
  }
  return StatsEvents(
    exerciseCompletions: _parseList(data['exerciseCompletions'], _exerciseCompletion),
    trainingCompletions: _parseList(data['trainingCompletions'], _trainingCompletion),
    created: _parseList(data['created'], _created),
  );
}

List<T> _parseList<T>(Object? raw, T? Function(Map<dynamic, dynamic> item) parse) {
  final result = <T>[];
  if (raw is! List) return result;
  for (final item in raw) {
    if (item is! Map) continue;
    final parsed = parse(item);
    if (parsed != null) result.add(parsed);
  }
  return result;
}

String? _id(Object? raw) => raw is String && raw.isNotEmpty ? raw : null;

DateTime? _localDate(Object? raw) => raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

int? _session(Object? raw) => raw is int && raw >= 1 && raw <= 3 ? raw : null;

List<int> _codes(Object? raw) => raw is List ? raw.whereType<int>().toList() : const [];

ExerciseCompletionEvent? _exerciseCompletion(Map<dynamic, dynamic> item) {
  final id = _id(item['exerciseId']);
  final completedAt = _localDate(item['completedAt']);
  final category = item['category'];
  if (id == null || completedAt == null || category is! String) return null;
  return ExerciseCompletionEvent(
    exerciseId: id,
    completedAt: completedAt,
    session: _session(item['session']),
    category: category,
    hits: _codes(item['hits']),
    rotations: _codes(item['rotations']),
    deleted: item['deleted'] == true,
  );
}

TrainingCompletionEvent? _trainingCompletion(Map<dynamic, dynamic> item) {
  final id = _id(item['trainingId']);
  final completedAt = _localDate(item['completedAt']);
  if (id == null || completedAt == null) return null;
  final duration = item['duration'];
  return TrainingCompletionEvent(
    trainingId: id,
    completedAt: completedAt,
    session: _session(item['session']),
    duration: duration is int ? duration : null,
  );
}

CreatedEvent? _created(Map<dynamic, dynamic> item) {
  final kind = switch (item['kind']) {
    'exercise' => CreatedKind.exercise,
    'training' => CreatedKind.training,
    _ => null,
  };
  final id = _id(item['id']);
  final createdAt = _localDate(item['createdAt']);
  if (kind == null || id == null || createdAt == null) return null;
  return CreatedEvent(kind: kind, id: id, createdAt: createdAt);
}
