import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/widgets/training_card.dart';

void main() {
  // El carrusel y la cuadrícula le dan más alto que el suyo: si la tarjeta
  // ocupara todo el hueco, el contorno de claro dejaría una franja vacía
  // debajo del nombre.
  testWidgets('el contorno rodea solo la imagen y el nombre', (tester) async {
    final training = TrainingModel(
      id: 't1',
      name: 'Abrir el juego',
      category: 'Técnico',
      image: 'assets/images/training_1.jpg',
      description: '',
      exerciseIds: const [],
      duration: 0,
    );
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(PingProColors.light),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 120, height: 220, child: TrainingCard(training: training, onTap: () {})),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final outlined = find.byWidgetPredicate((w) => w is Container && w.foregroundDecoration != null);
    expect(tester.getSize(outlined).height, 140);
  });
}
