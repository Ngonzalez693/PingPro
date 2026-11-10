import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/avatar_crop.dart';
import 'package:pingpro_front/screens/avatar_crop_screen.dart';

// Un PNG de 20 × 10 hecho en el momento, para no depender de un archivo.
Future<Uint8List> _samplePng() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 20, 10), Paint()..color = const Color(0xFF3366CC));
  final image = await recorder.endRecording().toImage(20, 10);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

void main() {
  late Uint8List png;
  Uint8List? result;
  var popped = false;

  Future<void> openCrop(WidgetTester tester) async {
    png = (await tester.runAsync(_samplePng))!;
    result = null;
    popped = false;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await Navigator.push<Uint8List>(
              context,
              MaterialPageRoute(builder: (_) => AvatarCropScreen(imageBytes: png)),
            );
            popped = true;
          },
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    // Primero entra la ruta; después la pantalla lee el tamaño de la foto,
    // que es asíncrono de verdad (runAsync), antes de enseñarla.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
  }

  testWidgets('enseña la indicación para mover y ajustar', (tester) async {
    await openCrop(tester);

    expect(find.text('Mueve y ajusta'), findsOneWidget);
  });

  testWidgets('Cancelar vuelve sin foto', (tester) async {
    await openCrop(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(result, isNull);
  });

  testWidgets('Usar foto devuelve un PNG de 512 × 512', (tester) async {
    await openCrop(tester);

    await tester.tap(find.text('Usar foto'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(result, isNotNull);
    expect(result!.sublist(0, 8), [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    final size = await tester.runAsync(() async {
      final frame = await (await ui.instantiateImageCodec(result!)).getNextFrame();
      return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    });
    expect(size, const Size(avatarPixels * 1.0, avatarPixels * 1.0));
  });

  // Con zoom, la foto no puede pintarse fuera de la zona de recorte (sobre la
  // indicación o la barra de estado), donde no la cubre la máscara oscura.
  testWidgets('la foto queda recortada a la zona de recorte', (tester) async {
    await openCrop(tester);

    expect(find.ancestor(of: find.byType(InteractiveViewer), matching: find.byType(ClipRect)), findsWidgets);
  });
}
