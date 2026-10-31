import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_locale.dart';

void main() {
  // Los textos que pone Flutter y no la app, como el menú de selección de un
  // campo, salían en inglés aunque todo lo demás esté en español.
  testWidgets('los textos propios de Flutter salen en español', (tester) async {
    late MaterialLocalizations labels;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: appSupportedLocales,
      home: Builder(builder: (context) {
        labels = MaterialLocalizations.of(context);
        return const SizedBox();
      }),
    ));

    expect(labels.cutButtonLabel, 'Cortar');
    expect(labels.copyButtonLabel, 'Copiar');
    expect(labels.pasteButtonLabel, 'Pegar');
  });
}
