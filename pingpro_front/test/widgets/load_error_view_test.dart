import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/load_error_view.dart';

Future<List<String>> _pump(WidgetTester tester, {bool compact = false}) async {
  final retries = <String>[];
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: LoadErrorView(message: 'Sin conexión.', onRetry: () => retries.add('retry'), compact: compact),
    ),
  ));
  return retries;
}

void main() {
  testWidgets('muestra el mensaje y "Reintentar" vuelve a cargar', (tester) async {
    final retries = await _pump(tester);

    expect(find.text('Sin conexión.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retries, ['retry']);
  });

  testWidgets('la versión compacta también deja reintentar', (tester) async {
    final retries = await _pump(tester, compact: true);

    expect(find.text('Sin conexión.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retries, ['retry']);
  });
}
