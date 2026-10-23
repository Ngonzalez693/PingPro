import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/core/load_errors.dart';
import 'package:pingpro_front/core/mappers/exercise_to_glb_steps.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/widgets/exercise_animation_view.dart';

final _exercise = ExerciseModel(
  id: 'e1',
  name: 'Falkenberg',
  category: 'Footwork',
  image: '',
  description: '',
  sequence: const [],
);

Future<void> _pump(WidgetTester tester, Future<List<GlbStep>> Function(ExerciseModel) buildSteps) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: ExerciseAnimationView(exercise: _exercise, buildSteps: buildSteps)),
  ));
  await tester.pump();
}

void main() {
  testWidgets('sin red enseña sin conexión y Reintentar, no "no hay animaciones"', (tester) async {
    var calls = 0;
    await _pump(tester, (_) async {
      calls++;
      throw http.ClientException('Failed host lookup');
    });

    expect(find.text(noConnectionMessage), findsOneWidget);
    expect(find.textContaining('No hay animaciones'), findsNothing);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(calls, 2);
  });

  testWidgets('si no hay archivo de animaciones lo dice', (tester) async {
    await _pump(tester, (_) async => const []);

    expect(find.text('No hay animaciones 3D disponibles para este ejercicio'), findsOneWidget);
  });
}
