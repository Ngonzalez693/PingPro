// Un ejercicio que el usuario está creando y todavía no existe en el backend.
//
// No se reutiliza ExerciseModel para esto por dos motivos:
//   - ExerciseModel.toJson lleva id, isFavorite y completedAt, y el esquema del
//     backend rechaza cualquier campo que no conozca con un 400.
//   - Un borrador no tiene id ni estado de usuario: modelarlo aparte deja claro
//     qué se puede mandar al crear.
//
// El dueño no va aquí: lo pone el backend a partir del token. Lo que sí lleva
// es `scope`, a dónde va: decide a qué ruta se envía, pero nunca viaja en el
// cuerpo de la petición.
import 'package:pingpro_front/models/content_scope.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';

class ExerciseDraft {
  final String name;
  final String category;
  final String image;
  final String description;
  final List<SequenceStep> sequence;
  final ContentScope scope;

  const ExerciseDraft({
    required this.name,
    required this.category,
    required this.image,
    required this.sequence,
    this.description = '',
    this.scope = ContentScope.own,
  });

  /// Cuerpo de POST /api/exercises/me: exactamente los campos que acepta el
  /// esquema del backend. Sin descripción, el campo no se manda.
  Map<String, dynamic> toCreateJson() => {
        'name': name.trim(),
        'category': category,
        'image': image,
        if (description.trim().isNotEmpty) 'description': description.trim(),
        'sequence': [for (final step in sequence) step.toJson()],
      };

  /// Ejercicio provisional para la vista previa 3D, que trabaja con
  /// ExerciseModel. El id va vacío: no existe hasta que el backend lo cree.
  ExerciseModel toPreviewModel() => ExerciseModel(
        id: '',
        name: name.trim(),
        category: category,
        image: image,
        description: description.trim(),
        sequence: sequence,
      );
}
