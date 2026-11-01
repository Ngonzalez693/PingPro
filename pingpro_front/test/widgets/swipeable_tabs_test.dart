import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/swipeable_tabs.dart';

/// Una pestaña que se mueve de lado por dentro, como las tarjetas de Inicio.
Widget _sideList(ScrollController controller) => ListView.builder(
      key: const Key('list'),
      controller: controller,
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemExtent: 500,
      itemBuilder: (_, i) => Center(child: Text('item $i')),
    );

/// Mantiene el índice como HomeNavigation, y deja cambiarlo por fuera con los
/// botones (lo que hace la barra inferior).
class _Host extends StatefulWidget {
  final List<Widget> tabs;

  const _Host(this.tabs);

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int index = 0;

  void select(int value) => setState(() => index = value);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SwipeableTabs(index: index, onIndexChanged: select, children: widget.tabs),
      ),
    );
  }
}

const _plain = [Center(child: Text('uno')), Center(child: Text('dos')), Center(child: Text('tres'))];

void main() {
  _HostState host(WidgetTester tester) => tester.state<_HostState>(find.byType(_Host));

  Future<void> swipeLeft(WidgetTester tester) async {
    await tester.fling(find.byType(SwipeableTabs), const Offset(-500, 0), 1500);
    await tester.pumpAndSettle();
  }

  testWidgets('deslizar cambia de pestaña y avisa', (tester) async {
    await tester.pumpWidget(const _Host(_plain));

    await swipeLeft(tester);

    expect(find.text('dos'), findsOneWidget);
    expect(host(tester).index, 1);
  });

  testWidgets('cambiar el índice por fuera muestra esa pestaña', (tester) async {
    await tester.pumpWidget(const _Host(_plain));

    host(tester).select(2);
    await tester.pumpAndSettle();

    expect(find.text('tres'), findsOneWidget);
  });

  testWidgets('una pestaña conserva su estado al irse y volver', (tester) async {
    await tester.pumpWidget(const _Host([TextField(), _plainPage]));
    await tester.enterText(find.byType(TextField), 'escrito');

    await swipeLeft(tester);
    host(tester).select(0);
    await tester.pumpAndSettle();

    expect(find.text('escrito'), findsOneWidget);
  });

  testWidgets('deslizar cierra el teclado del campo de la pestaña anterior', (tester) async {
    // Pequeño: un campo con el foco se queda los arrastres que empiezan encima,
    // para mover el cursor.
    await tester.pumpWidget(const _Host([Align(alignment: Alignment.topCenter, child: TextField()), _plainPage]));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await swipeLeft(tester);

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('lo de dentro se mueve primero y en su borde cambia la pestaña', (tester) async {
    final list = ScrollController();
    addTearDown(list.dispose);
    await tester.pumpWidget(_Host([_sideList(list), _plainPage]));

    await tester.drag(find.byKey(const Key('list')), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(list.offset, greaterThan(0));
    expect(host(tester).index, 0);

    list.jumpTo(list.position.maxScrollExtent);
    await tester.pump();
    await tester.timedDrag(find.byKey(const Key('list')), const Offset(-600, 0), const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(host(tester).index, 1);
  });

  testWidgets('volver el dedo en el borde no salta a la pestaña del otro lado', (tester) async {
    final list = ScrollController();
    addTearDown(list.dispose);
    await tester.pumpWidget(_Host([_plainPage, _sideList(list), _plainPage]));
    host(tester).select(1);
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('list'))));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-600, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(host(tester).index, 1);
  });

  testWidgets('un lanzamiento dentro de la lista no cambia de pestaña al llegar al borde', (tester) async {
    final list = ScrollController();
    addTearDown(list.dispose);
    await tester.pumpWidget(_Host([_sideList(list), _plainPage]));

    await tester.fling(find.byKey(const Key('list')), const Offset(-200, 0), 8000);
    await tester.pumpAndSettle();

    expect(host(tester).index, 0);
  });
}

const _plainPage = Center(child: Text('otra'));
