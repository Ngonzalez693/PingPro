import 'package:pingpro_front/models/sequence_step_model.dart';

/// Un ejercicio tal como lo consume la app.
///
/// Mezcla dos orígenes: los campos del catálogo (`name`, `category`, `sequence`)
/// vienen de GET /api/exercises y son iguales para todos; `isFavorite` y
/// `completedAt` son del usuario y llegan de GET /api/exercises/me/states.
/// ExercisesService.fetchAllMergedWithUserState() los junta.
///
/// Por eso esos dos campos son mutables mientras el resto es `final`:
/// ExercisesState los modifica en memoria para la UI optimista.
class ExerciseModel {
  final String id;

  /// Dueño de un ejercicio privado; null en los del catálogo. El backend solo
  /// devuelve los privados de quien pregunta, así que con valor siempre es un
  /// ejercicio del usuario actual.
  final String? ownerId;

  final String name;
  final String category;
  final String image;
  bool isFavorite;
  final String description;
  final List<SequenceStep> sequence;
  DateTime? completedAt;

  ExerciseModel({
    required this.id,
    this.ownerId,
    required this.name,
    required this.category,
    required this.image,
    this.isFavorite = false,
    required this.description,
    required this.sequence,
    this.completedAt,
  });

  /// Si es un ejercicio creado por el usuario actual.
  bool get isOwn => ownerId != null;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String?,
      name: json['name'] as String,
      category: json['category'] as String,
      image: json['image'] as String,
      // 'userState' es un envoltorio que el endpoint actual no devuelve: en la
      // práctica esto siempre queda en false y lo sobrescribe el merge de
      // ExercisesService. Se mantiene por si el backend llega a anidarlo.
      isFavorite: (json['userState']?['isFavorite'] ?? false) as bool,
      description: json['description'] as String? ?? '',
      sequence:
          (json['sequence'] as List<dynamic>?)
              ?.map(
                (step) => SequenceStep.fromJson(step as Map<String, dynamic>),
              )
              .toList() ??
          [],
      completedAt:
          json['userState']?['completedAt'] != null
              ? DateTime.tryParse(json['userState']['completedAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'image': image,
    'isFavorite': isFavorite,
    'description': description,
    'sequence': sequence.map((step) => step.toJson()).toList(),
    'completedAt': completedAt?.toIso8601String(),
  };
}
