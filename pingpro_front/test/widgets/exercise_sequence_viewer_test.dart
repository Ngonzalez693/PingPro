import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/core/load_errors.dart';
import 'package:pingpro_front/core/mappers/exercise_to_glb_steps.dart';
import 'package:pingpro_front/widgets/exercise_sequence_viewer.dart';

const _steps = [GlbStep(url: 'https://cdn.test/a.glb', clip: 'Globo')];

/// Un .glb válido pero sin el hueso root.x: ningún paso se puede reproducir.
Uint8List _glbWithoutClips() {
  final json = utf8.encode('{"asset":{"version":"2.0"},"nodes":[]}');
  final padded = [...json, ...List.filled((4 - json.length % 4) % 4, 0x20)];
  final out = BytesBuilder();
  void u32(int v) => out.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  u32(0x46546C67);
  u32(2);
  u32(12 + 8 + padded.length);
  u32(padded.length);
  u32(0x4E4F534A);
  out.add(padded);
  return out.toBytes();
}

// Leer el archivo es E/S real, fuera del reloj falso de los tests: se alterna
// tiempo real y fotogramas hasta que el visor deja de cargar (con tope).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 50; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
  }
}

Future<void> _pump(WidgetTester tester, Future<File> Function(String url) obtainFile) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: ExerciseSequenceViewer(steps: _steps, obtainFile: obtainFile)),
  ));
  await _settle(tester);
}

void main() {
  testWidgets('si no se puede bajar el archivo enseña sin conexión y Reintentar', (tester) async {
    var calls = 0;
    await _pump(tester, (_) async {
      calls++;
      throw http.ClientException('Failed host lookup');
    });

    expect(find.text(noConnectionMessage), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await _settle(tester);
    expect(calls, 2);
  });

  testWidgets('si ningún clip está en el archivo enseña el error de animación', (tester) async {
    final dir = await tester.runAsync(() => Directory.systemTemp.createTemp('viewer_widget_test'));
    final file = File('${dir!.path}/a.glb');
    await tester.runAsync(() => file.writeAsBytes(_glbWithoutClips()));

    await _pump(tester, (_) async => file);

    expect(find.text('No se pudo cargar la animación'), findsOneWidget);
    await tester.runAsync(() => dir.delete(recursive: true));
  });
}
