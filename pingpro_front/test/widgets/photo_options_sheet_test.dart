import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/photo_options_sheet.dart';

void main() {
  PhotoAction? chosen;
  var closed = false;

  Future<void> openSheet(WidgetTester tester, {required bool hasPhoto}) async {
    chosen = null;
    closed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              chosen = await showPhotoOptions(context, hasPhoto: hasPhoto);
              closed = true;
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('sin foto solo deja elegir de la galería', (tester) async {
    await openSheet(tester, hasPhoto: false);

    expect(find.text('Elegir de la galería'), findsOneWidget);
    expect(find.text('Quitar foto'), findsNothing);
  });

  testWidgets('con foto también deja quitarla', (tester) async {
    await openSheet(tester, hasPhoto: true);

    expect(find.text('Quitar foto'), findsOneWidget);
  });

  testWidgets('cada opción devuelve su acción', (tester) async {
    await openSheet(tester, hasPhoto: true);
    await tester.tap(find.text('Elegir de la galería'));
    await tester.pumpAndSettle();
    expect(chosen, PhotoAction.pick);

    await openSheet(tester, hasPhoto: true);
    await tester.tap(find.text('Quitar foto'));
    await tester.pumpAndSettle();
    expect(chosen, PhotoAction.remove);
  });

  testWidgets('cerrarla sin elegir no devuelve nada', (tester) async {
    await openSheet(tester, hasPhoto: true);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(chosen, isNull);
  });
}
