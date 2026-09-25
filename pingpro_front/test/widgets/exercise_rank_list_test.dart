import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/models/exercise_model.dart';
import 'package:pingpro_front/widgets/exercise_rank_list.dart';

ExerciseModel _model(String name) => ExerciseModel(
  id: name,
  name: name,
  category: 'Técnico',
  image: '',
  description: '',
  sequence: const [],
);

void main() {
  Future<void> pump(WidgetTester tester, List<(ExerciseModel, String)> rows, ValueChanged<ExerciseModel> onTap) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExerciseRankList(title: 'Más repetidos', rows: rows, emptyText: 'Nada todavía', onTap: onTap),
      ),
    ));
  }

  testWidgets('sin filas enseña el texto de vacío', (tester) async {
    await pump(tester, const [], (_) {});

    expect(find.text('Nada todavía'), findsOneWidget);
  });

  testWidgets('enseña nombre y etiqueta, y tocar abre ese ejercicio', (tester) async {
    final opened = <String>[];
    await pump(tester, [(_model('Topspin'), '×3')], (e) => opened.add(e.name));

    expect(find.text('×3'), findsOneWidget);
    await tester.tap(find.text('Topspin'));

    expect(opened, ['Topspin']);
  });
}
