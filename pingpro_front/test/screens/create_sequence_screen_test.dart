import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/models/sequence_step_model.dart';
import 'package:pingpro_front/screens/pingpro_create_sequence_screen.dart';
import 'package:pingpro_front/widgets/pingpong_table.dart';

// Flujo crítico del editor: arrastrar, elegir el golpe y devolver la secuencia.
// La pantalla se abre con push para poder leer lo que devuelve con pop, que es
// como la usará el formulario de creación.

// Un golpe que el editor produce tal cual y otro antiguo con valores Libre
// (profundidad, zona y dirección) que el editor no puede producir.
final _drawable = SequenceStep(hit: 1, rotation: 2, zone: 3, direction: 6, side: 1, ownZone: 3);
final _legacy = SequenceStep(hit: 2, rotation: 1, zone: 4, direction: 8, side: 5);

List<Map<String, dynamic>> _json(List<SequenceStep>? steps) => [for (final s in steps!) s.toJson()];

void main() {
  List<SequenceStep>? result;

  Future<void> openEditor(WidgetTester tester, {List<SequenceStep> initialSteps = const []}) async {
    // Tamaño de un móvil corriente (360 × 780 lógicos).
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    result = null;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await Navigator.push<List<SequenceStep>>(
              context,
              MaterialPageRoute(builder: (_) => PingproCreateSequenceScreen(initialSteps: initialSteps)),
            );
          },
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  // Punto de la mesa en píxeles de pantalla, a partir de coordenadas de mesa.
  Offset onTable(WidgetTester tester, double x, double y) {
    final table = tester.getRect(find.byType(PingPongTable));
    return Offset(table.left + table.width * x, table.top + table.height * y);
  }

  Future<void> drawStroke(WidgetTester tester, {required int origin, required Offset to}) async {
    final from = tester.getCenter(find.byKey(ValueKey('origin-$origin')));
    await tester.dragFrom(from, to - from);
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String field, String option) async {
    await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, field));
    await tester.pumpAndSettle();
    // .last: con el menú abierto, la opción es la entrada del menú.
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  Future<void> pickStroke(WidgetTester tester, String hit, String rotation) async {
    await choose(tester, 'Golpe', hit);
    await choose(tester, 'Rotación', rotation);
    await tester.tap(find.text('Añadir'));
    await tester.pumpAndSettle();
  }

  testWidgets('un arrastre al campo rival crea el golpe con sus códigos', (tester) async {
    await openEditor(tester);

    // Desde el "+" de más a la derecha (esquina derecha) a la esquina derecha
    // del rival, junto a su fondo.
    await drawStroke(tester, origin: 4, to: onTable(tester, 0.95, 0.05));
    expect(find.text('Elegir golpe'), findsOneWidget);
    await pickStroke(tester, 'Forehand', 'Topspin');

    expect(find.text('1. Forehand Topspin desde Largo, Largo a Esquina Derecha'), findsOneWidget);

    await tester.tap(find.text('Subir y ver'));
    await tester.pumpAndSettle();

    expect(result, hasLength(1));
    final step = result!.single;
    expect(step.side, 1);
    expect(step.direction, 2);
    expect(step.zone, 3);
    expect(step.hit, 1);
    expect(step.rotation, 2);
    expect(step.ownZone, 3);
  });

  testWidgets('soltar fuera de la banda a media altura marca una lateral', (tester) async {
    await openEditor(tester);

    await drawStroke(tester, origin: 2, to: onTable(tester, -0.1, 0.245));
    await pickStroke(tester, 'Backhand', 'Drive');

    expect(find.text('1. Backhand Drive desde Largo, Intermedio a Lateral Izquierda'), findsOneWidget);
  });

  testWidgets('la flecha se engancha al destino más cercano aunque no se acierte', (tester) async {
    await openEditor(tester);

    // Cerca, pero no encima, del punto medio de la fila media.
    await drawStroke(tester, origin: 2, to: onTable(tester, 0.44, 0.29));
    await pickStroke(tester, 'Backhand', 'Drive');

    expect(find.text('1. Backhand Drive desde Largo, Intermedio a Medio'), findsOneWidget);
  });

  testWidgets('se puede golpear desde la fila corta', (tester) async {
    await openEditor(tester);

    // Origen 7: fila corta, columna del centro.
    await drawStroke(tester, origin: 7, to: onTable(tester, 0.5, 0.42));
    await pickStroke(tester, 'Backhand', 'Back Spin');
    await tester.tap(find.text('Subir y ver'));
    await tester.pumpAndSettle();

    expect(result!.single.side, 3);
    expect(result!.single.zone, 1);
    expect(result!.single.ownZone, 1);
  });

  testWidgets('desde una banda el golpe queda a profundidad intermedia', (tester) async {
    await openEditor(tester);

    // Origen 11: banda derecha.
    await drawStroke(tester, origin: 11, to: onTable(tester, 0.9, 0.06));
    await pickStroke(tester, 'Forehand', 'Topspin');
    await tester.tap(find.text('Subir y ver'));
    await tester.pumpAndSettle();

    expect(result!.single.ownZone, 2);
  });

  testWidgets('soltar en tu propio campo no abre el diálogo ni crea golpe', (tester) async {
    await openEditor(tester);

    await drawStroke(tester, origin: 1, to: onTable(tester, 0.3, 0.7));

    expect(find.text('Elegir golpe'), findsNothing);
    expect(find.textContaining('1.'), findsNothing);
  });

  testWidgets('cancelar el diálogo descarta el golpe', (tester) async {
    await openEditor(tester);

    await drawStroke(tester, origin: 3, to: onTable(tester, 0.5, 0.2));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1.'), findsNothing);
  });

  testWidgets('arrastrar desde fuera de un "+" no hace nada', (tester) async {
    await openEditor(tester);

    final from = onTable(tester, 0.5, 0.75); // campo propio, lejos de los "+"
    await tester.dragFrom(from, onTable(tester, 0.5, 0.2) - from);
    await tester.pumpAndSettle();

    expect(find.text('Elegir golpe'), findsNothing);
  });

  testWidgets('se puede quitar un golpe y la numeración se rehace', (tester) async {
    await openEditor(tester);

    await drawStroke(tester, origin: 4, to: onTable(tester, 0.95, 0.05));
    await pickStroke(tester, 'Forehand', 'Topspin');
    await drawStroke(tester, origin: 2, to: onTable(tester, 0.5, 0.45));
    await pickStroke(tester, 'Backhand', 'Back Spin');

    await tester.tap(find.byTooltip('Quitar golpe 1'));
    await tester.pumpAndSettle();

    expect(find.text('1. Backhand Back Spin desde Largo, Corto a Medio'), findsOneWidget);
    expect(find.textContaining('2.'), findsNothing);
  });

  group('con onReview', () {
    Future<void> openWithReview(WidgetTester tester, Future<bool> Function(List<SequenceStep>) onReview) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      result = null;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<List<SequenceStep>>(
                context,
                MaterialPageRoute(builder: (_) => PingproCreateSequenceScreen(onReview: onReview)),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('si la revisión no se completa, el editor sigue con lo dibujado', (tester) async {
      List<SequenceStep>? reviewed;
      await openWithReview(tester, (steps) async {
        reviewed = steps;
        return false; // p. ej. "Volver a editar" en la vista previa
      });
      await drawStroke(tester, origin: 4, to: onTable(tester, 0.95, 0.05));
      await pickStroke(tester, 'Forehand', 'Topspin');

      await tester.tap(find.text('Subir y ver'));
      await tester.pumpAndSettle();

      expect(reviewed, hasLength(1));
      expect(find.text('1. Forehand Topspin desde Largo, Largo a Esquina Derecha'), findsOneWidget);
      expect(result, isNull);
    });

    testWidgets('si la revisión se completa, el editor se cierra devolviendo la secuencia', (tester) async {
      await openWithReview(tester, (_) async => true);
      await drawStroke(tester, origin: 4, to: onTable(tester, 0.95, 0.05));
      await pickStroke(tester, 'Forehand', 'Topspin');

      await tester.tap(find.text('Subir y ver'));
      await tester.pumpAndSettle();

      expect(find.text('Secuencia'), findsNothing);
      expect(result, hasLength(1));
    });
  });

  testWidgets('sin golpes no se puede subir', (tester) async {
    await openEditor(tester);

    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Subir y ver'));

    expect(button.onPressed, isNull);
  });

  testWidgets('abre con los golpes que recibe y los devuelve sin tocar', (tester) async {
    await openEditor(tester, initialSteps: [_drawable, _legacy]);

    expect(find.text('1. Forehand Topspin desde Largo, Largo a Esquina Izquierda'), findsOneWidget);
    expect(find.text('2. Backhand Back Spin Libre a Libre'), findsOneWidget);

    await tester.tap(find.text('Subir y ver'));
    await tester.pumpAndSettle();

    expect(_json(result), _json([_drawable, _legacy]));
  });

  testWidgets('un golpe nuevo se añade después de los que recibe', (tester) async {
    await openEditor(tester, initialSteps: [_legacy]);

    await drawStroke(tester, origin: 7, to: onTable(tester, 0.5, 0.42));
    await pickStroke(tester, 'Backhand', 'Back Spin');
    await tester.tap(find.text('Subir y ver'));
    await tester.pumpAndSettle();

    expect(result, hasLength(2));
    expect(result!.first.toJson(), _legacy.toJson());
    expect(result!.last.ownZone, 1);
  });

  testWidgets('el golpe que se arrastra se ve en negro sobre el color secundario', (tester) async {
    await openEditor(tester, initialSteps: [_drawable, _legacy]);
    Color? colorOf(String text) => tester
        .widgetList<RichText>(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == text))
        .last
        .text
        .style
        ?.color;
    const first = '1. Forehand Topspin desde Largo, Largo a Esquina Izquierda';

    expect(colorOf(first), AppColors.textWhite);

    final gesture = await tester.startGesture(tester.getCenter(find.byIcon(Icons.drag_handle).first));
    await gesture.moveBy(const Offset(0, 10));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();

    expect(
      tester.widgetList<Material>(find.byType(Material)).any((m) => m.color == AppColors.secundary),
      isTrue,
    );
    expect(colorOf(first), AppColors.textBlack);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('arrastrar un golpe por su asa cambia el orden de la secuencia', (tester) async {
    await openEditor(tester, initialSteps: [_drawable, _legacy]);

    await tester.drag(find.byIcon(Icons.drag_handle).first, const Offset(0, 120));
    await tester.pumpAndSettle();

    expect(find.text('1. Backhand Back Spin Libre a Libre'), findsOneWidget);

    await tester.tap(find.text('Subir y ver'));
    await tester.pumpAndSettle();

    expect(_json(result), _json([_legacy, _drawable]));
  });
}
