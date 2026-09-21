import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/models/exercise_model.dart';
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

  Future<void> openForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CreateTrainingForm())));
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
}
