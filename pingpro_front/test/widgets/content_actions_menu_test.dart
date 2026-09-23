import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/content_actions_menu.dart';

void main() {
  Future<List<String>> choose(WidgetTester tester, String option) async {
    final calls = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ContentActionsMenu(onEdit: () => calls.add('edit'), onDelete: () => calls.add('delete')),
      ),
    ));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option));
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets('"Editar" llama a onEdit', (tester) async {
    expect(await choose(tester, 'Editar'), ['edit']);
  });

  testWidgets('"Eliminar" llama a onDelete', (tester) async {
    expect(await choose(tester, 'Eliminar'), ['delete']);
  });
}
