import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/widgets/custom_bottom_navigation.dart';

const _labels = ['Inicio', 'Ejercicios', 'Crear', 'Entrenamientos', 'Perfil'];

Future<List<int>> _pump(WidgetTester tester, {int currentIndex = 0}) async {
  final taps = <int>[];
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      bottomNavigationBar: CustomBottomNavigation(currentIndex: currentIndex, onTap: taps.add),
    ),
  ));
  await tester.pumpAndSettle();
  return taps;
}

Color? _colorOf(WidgetTester tester, String label) =>
    DefaultTextStyle.of(tester.element(find.text(label))).style.color;

void main() {
  testWidgets('cada pestaña muestra su nombre', (tester) async {
    await _pump(tester);

    for (final label in _labels) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('pulsar el nombre abre esa pestaña', (tester) async {
    final taps = await _pump(tester);

    await tester.tap(find.text('Perfil'));
    expect(taps, [4]);
  });

  testWidgets('el nombre de la pestaña activa va en el color principal', (tester) async {
    await _pump(tester, currentIndex: 2);

    expect(_colorOf(tester, 'Crear'), AppColors.primary);
    expect(_colorOf(tester, 'Inicio'), isNot(AppColors.primary));
  });
}
