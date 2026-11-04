import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/pingpro_colors.dart';
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
  // Los SVG traen el color dibujado (lima el activo, blanco el resto): en la
  // barra crema no se verían, así que se pintan con los del tema.
  testWidgets('los iconos toman el color del tema', (tester) async {
    final palette = PingProColors.dark.copyWith(brand: const Color(0xFF5C6300), onPage: const Color(0xFF1B1D00));
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(palette),
      home: Scaffold(bottomNavigationBar: CustomBottomNavigation(currentIndex: 0, onTap: (_) {})),
    ));
    await tester.pumpAndSettle();

    final icons = tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();
    expect(icons.first.colorFilter, const ColorFilter.mode(Color(0xFF5C6300), BlendMode.srcIn));
    expect(icons[1].colorFilter, const ColorFilter.mode(Color(0xFF1B1D00), BlendMode.srcIn));
  });

  testWidgets('en claro la barra tiene una línea fina arriba', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(PingProColors.light),
      home: Scaffold(bottomNavigationBar: CustomBottomNavigation(currentIndex: 0, onTap: (_) {})),
    ));

    final bar = tester.widget<Container>(
      find.descendant(of: find.byType(CustomBottomNavigation), matching: find.byType(Container)).first,
    );
    // Por encima y no como borde: un borde, aunque sea transparente, empuja el
    // contenido un píxel hacia abajo y cambiaría la barra en oscuro.
    final border = (bar.foregroundDecoration! as BoxDecoration).border! as Border;
    expect(border.top.color, PingProColors.light.hairline);
  });
  // Pintar el SVG con un filtro le cuesta suavizado en los bordes: en oscuro,
  // donde ya trae su color, se dibuja tal cual para que no cambie nada.
  testWidgets('en oscuro los iconos se dibujan sin filtro', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(PingProColors.dark),
      home: Scaffold(bottomNavigationBar: CustomBottomNavigation(currentIndex: 0, onTap: (_) {})),
    ));

    for (final icon in tester.widgetList<SvgPicture>(find.byType(SvgPicture))) {
      expect(icon.colorFilter, isNull);
    }
  });
}
