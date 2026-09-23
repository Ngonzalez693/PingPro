import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/confirm_delete_dialog.dart';

void main() {
  Future<bool?> answer(WidgetTester tester, String button) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => result = await confirmDelete(context, message: '¿Eliminar «Saque»?'),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar «Saque»?'), findsOneWidget);
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('"Eliminar" confirma', (tester) async {
    expect(await answer(tester, 'Eliminar'), isTrue);
  });

  testWidgets('"Cancelar" no confirma', (tester) async {
    expect(await answer(tester, 'Cancelar'), isFalse);
  });
}
