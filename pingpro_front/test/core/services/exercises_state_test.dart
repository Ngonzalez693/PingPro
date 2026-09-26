import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/models/exercise_model.dart';

ExerciseModel _exercise(String id) => ExerciseModel(
  id: id,
  name: id,
  category: 'test',
  image: '',
  description: '',
  sequence: const [],
  completedAt: DateTime(2026, 9, 10),
);

void main() {
  // safeNotify() (mixin SafeNotify) consulta SchedulerBinding.instance, que necesita el binding
  // listo. En la app lo deja listo main() con WidgetsFlutterBinding.
  TestWidgetsFlutterBinding.ensureInitialized();

  // El store construye su cliente HTTP en el constructor, y ese lee
  // API_BASE_URL de dotenv. Ninguna prueba de aquí llega a hacer peticiones.
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:3000');
  });

  tearDown(() => ExercisesState.instance.reset());

  group('ExercisesState.reset', () {
    test('vacía los ejercicios del usuario anterior', () {
      final state = ExercisesState.instance;
      state.upsert(_exercise('e1'));
      state.upsert(_exercise('e2'));
      expect(state.all, hasLength(2));

      state.reset();

      expect(state.all, isEmpty);
      expect(state.getById('e1'), isNull);
    });

    test('deja loadedOnce en false para que el siguiente load() sí pida datos', () {
      final state = ExercisesState.instance;
      state.upsert(_exercise('e1'));

      state.reset();

      // La guarda de load() es `if (_loadedOnce && !force) return;`: mientras
      // siga en true, el usuario nuevo se quedaría con la cache del anterior.
      expect(state.loadedOnce, isFalse);
    });

    test('no deja completados que alimenten las estadísticas', () {
      final state = ExercisesState.instance;
      state.upsert(_exercise('e1'));
      expect(state.completed, hasLength(1));

      state.reset();

      expect(state.completed, isEmpty);
    });

    test('notifica a quien esté escuchando', () {
      final state = ExercisesState.instance;
      var notified = 0;
      void listener() => notified++;
      state.addListener(listener);
      addTearDown(() => state.removeListener(listener));

      state.upsert(_exercise('e1'));
      final afterUpsert = notified;
      state.reset();

      expect(notified, greaterThan(afterUpsert));
    });
  });
}
