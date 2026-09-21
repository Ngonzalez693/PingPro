// Un entrenamiento que el usuario está creando y todavía no existe en el
// backend. Mismo motivo que ExerciseDraft: el esquema del backend rechaza los
// campos que no conoce, así que el cuerpo de creación se construye aparte.
//
// El dueño no va aquí: lo pone el backend a partir del token. `scope` decide a
// qué ruta se envía, como en ExerciseDraft, y no viaja en el cuerpo.
import 'package:pingpro_front/models/content_scope.dart';

class TrainingDraft {
  final String name;
  final String category;
  final String image;
  final String description;

  /// Ejercicios en el orden en que se hacen. Puede repetir un mismo id.
  final List<String> exerciseIds;

  /// Minutos que se dedican a cada ejercicio.
  final int minutesPerExercise;

  final ContentScope scope;

  const TrainingDraft({
    required this.name,
    required this.category,
    required this.image,
    required this.exerciseIds,
    required this.minutesPerExercise,
    this.description = '',
    this.scope = ContentScope.own,
  });

  /// Duración total en minutos, que es lo que guarda el backend. La pantalla de
  /// detalle la divide entre los ejercicios y vuelve a salir el tiempo de cada
  /// uno.
  int get totalMinutes => minutesPerExercise * exerciseIds.length;

  /// Cuerpo de POST /api/trainings/me: exactamente los campos que acepta el
  /// esquema del backend. Sin descripción, el campo no se manda.
  Map<String, dynamic> toCreateJson() => {
        'name': name.trim(),
        'category': category,
        'image': image,
        if (description.trim().isNotEmpty) 'description': description.trim(),
        'exerciseIds': exerciseIds,
        'duration': totalMinutes,
      };
}
