// Un ejercicio que el usuario está creando o editando.
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

  /// Id del ejercicio que se edita, o null si se está creando.
  final String? editingId;

  const ExerciseDraft({
    required this.name,
    required this.category,
    required this.image,
    required this.sequence,
    this.description = '',
    this.scope = ContentScope.own,
    this.editingId,
  });

  bool get isEdit => editingId != null;

  /// Cuerpo de POST (crear) y de PUT (editar): el esquema del backend es el
  /// mismo. Al crear, sin descripción el campo no se manda. Al editar sí se
  /// manda aunque esté vacía: el PUT del backend hace COALESCE con el valor
  /// anterior cuando el campo falta, así que omitirla dejaría la descripción
  /// vieja en vez de borrarla.
  Map<String, dynamic> toCreateJson() => {
        'name': name.trim(),
        'category': category,
        'image': image,
        if (isEdit || description.trim().isNotEmpty) 'description': description.trim(),
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
