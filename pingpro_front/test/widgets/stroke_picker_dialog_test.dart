import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/stroke_codes.dart';
import 'package:pingpro_front/widgets/stroke_picker_dialog.dart';

void main() {
  Future<void> openPicker(WidgetTester tester, {required int ownZone}) async {
    // Tamaño de un móvil corriente: con la pantalla de test por defecto, el
    // menú de 12 golpes no cabe y los últimos no se construyen.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StrokePickerDialog(ownZone: ownZone))));
  }

  Future<void> openMenu(WidgetTester tester, String field) async {
    await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, field));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String field, String option) async {
    await openMenu(tester, field);
    // .last: con el menú abierto, la opción es la entrada del menú.
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  bool canAdd(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Añadir')).onPressed != null;

  testWidgets('desde el fondo ofrece Globo y Smash', (tester) async {
    await openPicker(tester, ownZone: ZoneCode.long);

    await openMenu(tester, 'Golpe');

    expect(find.text('Globo'), findsWidgets);
    expect(find.text('Smash'), findsWidgets);
  });

  testWidgets('desde la fila corta no ofrece Globo ni Smash, pero sí Hook', (tester) async {
    await openPicker(tester, ownZone: ZoneCode.short);

    await openMenu(tester, 'Golpe');

    expect(find.text('Globo'), findsNothing);
    expect(find.text('Smash'), findsNothing);
    expect(find.text('Hook'), findsWidgets);
  });

  testWidgets('Hook deja elegida su única rotación', (tester) async {
    await openPicker(tester, ownZone: ZoneCode.short);

    await choose(tester, 'Golpe', 'Hook');

    expect(canAdd(tester), isTrue);
    expect(find.text('Back Spin'), findsOneWidget);
  });

  testWidgets('Smash solo ofrece Topspin y Drive', (tester) async {
    await openPicker(tester, ownZone: ZoneCode.long);
    await choose(tester, 'Golpe', 'Smash');

    await openMenu(tester, 'Rotación');

    expect(find.text('Topspin'), findsWidgets);
    expect(find.text('Drive'), findsWidgets);
    expect(find.text('Back Spin'), findsNothing);
  });

  testWidgets('cambiar a un golpe que no admite la rotación elegida la borra', (tester) async {
    await openPicker(tester, ownZone: ZoneCode.long);
    await choose(tester, 'Golpe', 'Forehand');
    await choose(tester, 'Rotación', 'Back Spin');
    expect(canAdd(tester), isTrue);

    await choose(tester, 'Golpe', 'Smash');

    expect(canAdd(tester), isFalse);
  });

  testWidgets('elegir primero una rotación que el golpe admite la conserva', (tester) async {
    await openPicker(tester, ownZone: ZoneCode.long);
    await choose(tester, 'Rotación', 'Topspin');

    await choose(tester, 'Golpe', 'Smash');

    expect(canAdd(tester), isTrue);
    expect(find.text('Topspin'), findsOneWidget);
  });
}
