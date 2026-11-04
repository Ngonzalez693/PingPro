import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/app_preferences.dart';
import 'package:pingpro_front/widgets/choice_pill.dart';
import 'package:pingpro_front/widgets/theme_mode_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppPreferences> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = AppPreferences.forTesting();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: ThemeModeSelector(preferences: preferences)),
  ));
  return preferences;
}

bool _selected(WidgetTester tester, String label) =>
    tester.widget<ChoicePill>(find.widgetWithText(ChoicePill, label)).selected;

void main() {
  testWidgets('muestra las tres opciones con Oscuro elegido', (tester) async {
    await _pump(tester);

    expect(find.text('Tema'), findsOneWidget);
    expect(_selected(tester, 'Oscuro'), isTrue);
    expect(_selected(tester, 'Claro'), isFalse);
    expect(_selected(tester, 'Sistema'), isFalse);
  });

  testWidgets('tocar Claro guarda el tema claro', (tester) async {
    final preferences = await _pump(tester);

    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();

    expect(preferences.themeMode, ThemeMode.light);
    expect(_selected(tester, 'Claro'), isTrue);
  });
}
