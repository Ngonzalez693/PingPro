import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/delete_account_dialog.dart';

void main() {
  bool? result;

  Future<void> openDialog(WidgetTester tester) async {
    result = null;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showDeleteAccountDialog(context),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('explica qué se borra y que no se puede deshacer', (tester) async {
    await openDialog(tester);

    expect(find.textContaining('ejercicios y entrenamientos'), findsOneWidget);
    expect(find.textContaining('catálogo'), findsOneWidget);
    expect(find.textContaining('no se puede deshacer'), findsOneWidget);
  });

  testWidgets('sin contraseña no intenta borrar y avisa dentro del diálogo', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('Eliminar'));
    await tester.pump();

    expect(find.text('Escribe tu contraseña'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('Cancelar cierra el diálogo y devuelve false', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(result, isFalse);
  });
}
