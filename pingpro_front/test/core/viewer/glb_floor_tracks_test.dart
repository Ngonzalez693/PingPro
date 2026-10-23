import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/viewer/glb_floor_tracks.dart';

/// Un canal de animación para el .glb sintético.
typedef _Channel = ({int node, String path, List<double> times, List<double> values, String interpolation});

_Channel _translation(int node, List<double> times, List<List<double>> xyz, {String interpolation = 'LINEAR'}) =>
    (node: node, path: 'translation', times: times, values: [for (final p in xyz) ...p], interpolation: interpolation);

/// Arma un .glb mínimo: nodos con nombre y animaciones con accesores float32.
Uint8List _glb(List<String> nodeNames, Map<String, List<_Channel>> animations) {
  final bin = BytesBuilder();
  final accessors = <Map<String, Object>>[];
  final views = <Map<String, Object>>[];
  int addFloats(List<double> values, String type) {
    final offset = bin.length;
    final data = Float32List.fromList(values);
    bin.add(data.buffer.asUint8List());
    views.add({'buffer': 0, 'byteOffset': offset, 'byteLength': data.lengthInBytes});
    final components = {'SCALAR': 1, 'VEC3': 3, 'VEC4': 4}[type]!;
    accessors.add({'bufferView': views.length - 1, 'componentType': 5126, 'count': values.length ~/ components, 'type': type});
    return accessors.length - 1;
  }

  final anims = <Map<String, Object>>[];
  animations.forEach((name, channels) {
    final samplers = <Map<String, Object>>[];
    final targets = <Map<String, Object>>[];
    for (final c in channels) {
      final input = addFloats(c.times, 'SCALAR');
      final output = addFloats(c.values, c.path == 'rotation' ? 'VEC4' : 'VEC3');
      samplers.add({'input': input, 'output': output, 'interpolation': c.interpolation});
      targets.add({'sampler': samplers.length - 1, 'target': {'node': c.node, 'path': c.path}});
    }
    anims.add({'name': name, 'channels': targets, 'samplers': samplers});
  });

  final json = utf8.encode(jsonEncode({
    'asset': {'version': '2.0'},
    'nodes': [for (final n in nodeNames) {'name': n}],
    'animations': anims,
    'accessors': accessors,
    'bufferViews': views,
    'buffers': [{'byteLength': bin.length}],
  }));
  Uint8List padded(List<int> bytes, int fill) =>
      Uint8List.fromList([...bytes, ...List.filled((4 - bytes.length % 4) % 4, fill)]);
  final jsonChunk = padded(json, 0x20);
  final binChunk = padded(bin.toBytes(), 0);
  final out = BytesBuilder();
  void u32(int v) => out.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  u32(0x46546C67);
  u32(2);
  u32(12 + 8 + jsonChunk.length + 8 + binChunk.length);
  u32(jsonChunk.length);
  u32(0x4E4F534A);
  out.add(jsonChunk);
  u32(binChunk.length);
  u32(0x004E4942);
  out.add(binChunk);
  return out.toBytes();
}

void main() {
  test('lee inicio, fin y extremos del root.x de cada clip', () {
    final glb = _glb(['root', 'root.x'], {
      'A': [_translation(1, [0, 1, 2], [[0, 5, 0], [2, 5, -1], [1, 5, 3]])],
    });

    final a = readFloorTracks(glb)['A']!;

    expect([a.startX, a.endX, a.minX, a.maxX], [0, 1, 0, 2]);
    expect([a.startZ, a.endZ, a.minZ, a.maxZ], [0, 3, -1, 3]);
  });

  test('un clip sin traslación del root no aparece', () {
    final glb = _glb(['root.x'], {
      'B': [(node: 0, path: 'rotation', times: [0, 1], values: [0, 0, 0, 1, 0, 0, 0, 1], interpolation: 'LINEAR')],
    });

    expect(readFloorTracks(glb), isEmpty);
  });

  test('CUBICSPLINE usa el valor central', () {
    final glb = _glb(['root.x'], {
      'C': [
        _translation(0, [0, 1], [
          [9, 9, 9], [1, 0, 2], [9, 9, 9],
          [9, 9, 9], [3, 0, 4], [9, 9, 9],
        ], interpolation: 'CUBICSPLINE'),
      ],
    });

    final c = readFloorTracks(glb)['C']!;

    expect([c.startX, c.startZ, c.endX, c.endZ], [1, 2, 3, 4]);
    expect([c.maxX, c.maxZ], [3, 4]);
  });

  test('otra raíz por parámetro', () {
    final glb = _glb(['hips'], {
      'D': [_translation(0, [0, 1], [[1, 0, 1], [2, 0, 2]])],
    });

    expect(readFloorTracks(glb), isEmpty);
    expect(readFloorTracks(glb, rootBone: 'hips')['D']!.endX, 2);
  });

  // Un .glb bien formado por fuera pero con datos inesperados también es un
  // archivo ilegible para el visor, no un fallo de la app.
  test('un glb sin bloque binario da FormatException', () {
    final full = _glb(['root.x'], {
      'A': [_translation(0, [0, 1], [[0, 0, 0], [1, 0, 1]])],
    });
    final jsonLength = ByteData.sublistView(full).getUint32(12, Endian.little);
    final withoutBin = Uint8List.fromList(full.sublist(0, 20 + jsonLength));
    ByteData.sublistView(withoutBin).setUint32(8, withoutBin.length, Endian.little);

    expect(() => readFloorTracks(withoutBin), throwsFormatException);
  });

  test('una animación sin samplers da FormatException', () {
    final full = _glb(['root.x'], {
      'A': [_translation(0, [0, 1], [[0, 0, 0], [1, 0, 1]])],
    });
    final data = ByteData.sublistView(full);
    final jsonLength = data.getUint32(12, Endian.little);
    final json = utf8.decode(full.sublist(20, 20 + jsonLength)).replaceFirst('"samplers"', '"sampl3rs"');
    final patched = Uint8List.fromList([...full.sublist(0, 20), ...utf8.encode(json), ...full.sublist(20 + jsonLength)]);

    expect(() => readFloorTracks(patched), throwsFormatException);
  });

  test('un archivo que no es glb da FormatException', () {
    expect(() => readFloorTracks(Uint8List.fromList(utf8.encode('no soy un glb, para nada'))), throwsFormatException);
  });

  final realGlb = Platform.environment['PINGPRO_GLB'];
  test(
    'lee el archivo real',
    () {
      final tracks = readFloorTracks(File(realGlb!).readAsBytesSync());

      expect(tracks, hasLength(29));
      expect(tracks['Globo']!.startZ, closeTo(-3.25, 0.01));
    },
    skip: realGlb == null ? 'Define PINGPRO_GLB con la ruta de PingProAnimations.glb' : false,
  );
}
