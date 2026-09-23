import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/core/training_options.dart';
import 'package:pingpro_front/models/content_scope.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/widgets/create_training_form.dart';

// El formulario hasta antes de guardar: guardar llama al backend y se
// comprueba en el móvil. Los ejercicios se siembran en el store directamente.
ExerciseModel _exercise(String id, String name, {String? ownerId}) => ExerciseModel(
      id: id,
      ownerId: ownerId,
      name: name,
      category: 'Técnico',
      image: 'assets/images/exercise_1.jpg',
      description: '',
      sequence: const [],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:3000'));

  setUp(() {
    ExercisesState.instance
      ..upsert(_exercise('c1', 'Topspin cruzado'))
      ..upsert(_exercise('c2', 'Saque corto'))
      ..upsert(_exercise('m1', 'Mi rutina de revés', ownerId: 'u1'));
  });
  tearDown(() => ExercisesState.instance.reset());

  Future<void> openForm(WidgetTester tester, {TrainingModel? initial}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CreateTrainingForm(initial: initial))));
  }

  Future<void> addExercise(WidgetTester tester, String name) async {
    await tester.tap(find.text('Agregar ejercicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, {String name = 'Calentamiento', String minutes = '5'}) async {
    await tester.enterText(find.widgetWithText(TextField, 'Nombre del entrenamiento'), name);
    await tester.enterText(find.widgetWithText(TextField, 'Minutos por ejercicio'), minutes);
    await tester.pump();
  }

  // El ListView del formulario construye solo lo visible, y a altura de móvil
  // el botón queda por debajo: hay que desplazarse hasta él, como el usuario.
  Future<ElevatedButton> createButton(WidgetTester tester) async {
    final button = find.widgetWithText(ElevatedButton, 'Crear');
    await tester.scrollUntilVisible(button, 200, scrollable: find.byType(Scrollable).first);
    return tester.widget<ElevatedButton>(button);
  }

  testWidgets('recién abierto no se puede crear', (tester) async {
    await openForm(tester);

    expect((await createButton(tester)).onPressed, isNull);
  });

  testWidgets('hace falta al menos un ejercicio', (tester) async {
    await openForm(tester);
    await fill(tester);

    expect((await createButton(tester)).onPressed, isNull);

    await addExercise(tester, 'Saque corto');

    expect((await createButton(tester)).onPressed, isNotNull);
  });

  testWidgets('cero minutos por ejercicio no vale', (tester) async {
    await openForm(tester);
    await fill(tester, minutes: '0');
    await addExercise(tester, 'Saque corto');

    expect((await createButton(tester)).onPressed, isNull);
  });

  testWidgets('la duración total es minutos por ejercicio por ejercicios', (tester) async {
    await openForm(tester);
    await fill(tester, minutes: '5');
    await addExercise(tester, 'Saque corto');
    await addExercise(tester, 'Topspin cruzado');

    expect(find.text('Duración total: 10 min'), findsOneWidget);
  });

  testWidgets('el selector separa los ejercicios propios, marcados como Propio', (tester) async {
    await openForm(tester);

    await tester.tap(find.text('Agregar ejercicio'));
    await tester.pumpAndSettle();

    expect(find.text('Tus ejercicios'), findsOneWidget);
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Propio'), findsOneWidget);
  });

  testWidgets('en el catálogo, el selector solo ofrece ejercicios del catálogo', (tester) async {
    // Un entrenamiento del catálogo no puede usar ejercicios privados: para el
    // resto de usuarios no existirían, y el backend lo rechaza.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CreateTrainingForm(scope: ContentScope.catalog))),
    );

    await tester.tap(find.text('Agregar ejercicio'));
    await tester.pumpAndSettle();

    expect(find.text('Mi rutina de revés'), findsNothing);
    expect(find.text('Tus ejercicios'), findsNothing);
    expect(find.text('Topspin cruzado'), findsOneWidget);
  });

  testWidgets('un ejercicio propio y uno del catálogo se pueden mezclar', (tester) async {
    await openForm(tester);
    await addExercise(tester, 'Mi rutina de revés');
    await addExercise(tester, 'Topspin cruzado');

    expect(find.text('1. Mi rutina de revés'), findsOneWidget);
    expect(find.text('2. Topspin cruzado'), findsOneWidget);
  });

  testWidgets('el mismo ejercicio puede aparecer dos veces', (tester) async {
    await openForm(tester);
    await addExercise(tester, 'Saque corto');
    await addExercise(tester, 'Saque corto');

    expect(find.text('1. Saque corto'), findsOneWidget);
    expect(find.text('2. Saque corto'), findsOneWidget);
  });

  testWidgets('quitar un ejercicio rehace la numeración', (tester) async {
    await openForm(tester);
    await addExercise(tester, 'Saque corto');
    await addExercise(tester, 'Topspin cruzado');

    await tester.tap(find.byTooltip('Quitar ejercicio 1'));
    await tester.pumpAndSettle();

    expect(find.text('1. Topspin cruzado'), findsOneWidget);
    expect(find.textContaining('2.'), findsNothing);
  });

  testWidgets('al volver del selector no se abre el teclado', (tester) async {
    await openForm(tester);
    // Escribir deja el foco (y el teclado) en el campo de minutos.
    await fill(tester);
    expect(tester.testTextInput.isVisible, isTrue);

    await addExercise(tester, 'Saque corto');

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('se puede reordenar arrastrando', (tester) async {
    await openForm(tester);
    await addExercise(tester, 'Saque corto');
    await addExercise(tester, 'Topspin cruzado');

    final handle = find.byIcon(Icons.drag_handle).first;
    await tester.timedDrag(handle, const Offset(0, 120), const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('1. Topspin cruzado'), findsOneWidget);
    expect(find.text('2. Saque corto'), findsOneWidget);
  });

  // Tres ejercicios guardados, uno de los cuales ya no existe en el store.
  TrainingModel existing() => TrainingModel(
        id: 't1',
        ownerId: 'u1',
        name: 'Calentamiento',
        category: trainingCategories[1],
        image: trainingImages[1],
        description: 'Para empezar',
        exerciseIds: const ['c1', 'borrado', 'c2'],
        duration: 15,
      );

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

  testWidgets('para editar sale relleno y con minutos por ejercicio', (tester) async {
    await openForm(tester, initial: existing());

    expect(find.text('Calentamiento'), findsOneWidget);
    expect(find.text('Para empezar'), findsOneWidget);
    expect(find.text(trainingCategories[1]), findsOneWidget);
    expect(find.text('5'), findsOneWidget); // 15 min entre los 3 ejercicios guardados
  });

  testWidgets('al editar lista sus ejercicios en orden, sin los que ya no existen', (tester) async {
    await openForm(tester, initial: existing());

    await scrollTo(tester, find.text('2. Saque corto'));

    expect(find.text('1. Topspin cruzado'), findsOneWidget);
    expect(find.text('2. Saque corto'), findsOneWidget);
    expect(find.textContaining('borrado'), findsNothing);
  });

  testWidgets('al editar el botón dice "Guardar"', (tester) async {
    await openForm(tester, initial: existing());

    await scrollTo(tester, find.widgetWithText(ElevatedButton, 'Guardar'));

    expect(find.widgetWithText(ElevatedButton, 'Guardar'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Crear'), findsNothing);
  });

  testWidgets('al editar, con menos de un minuto por ejercicio no baja de 1', (tester) async {
    // 1 min entre 3 ejercicios redondearía a 0: dejaría el campo sin sentido
    // y "Guardar" deshabilitado sin ninguna pista.
    final training = TrainingModel(
      id: 't2',
      ownerId: 'u1',
      name: 'Micro',
      category: trainingCategories[1],
      image: trainingImages[1],
      description: '',
      exerciseIds: const ['c1', 'borrado', 'c2'],
      duration: 1,
    );

    await openForm(tester, initial: training);

    expect(find.text('1'), findsOneWidget);
  });
}
