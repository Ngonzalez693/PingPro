// Cuánto se mueve por el suelo el jugador en cada clip, leído del propio
// archivo de animaciones (.glb).
//
// El hueso raíz del esqueleto (root.x) lleva el desplazamiento por el suelo:
// x de lado a lado, z hacia delante y atrás. De su pista de traslación se
// guardan el punto de inicio, el de fin y los extremos. Con eso se encadenan
// los clips (cada uno empieza donde terminó el anterior) y se encuadra la
// cámara, sin un solo número escrito a mano por clip: un clip nuevo o mejorado
// funciona tal cual.
import 'dart:convert';
import 'dart:typed_data';

const _glbMagic = 0x46546C67; // 'glTF'
const _jsonChunk = 0x4E4F534A;
const _binChunk = 0x004E4942;
const _float = 5126;

class FloorTrack {
  final double startX, startZ, endX, endZ, minX, maxX, minZ, maxZ;

  const FloorTrack({
    required this.startX,
    required this.startZ,
    required this.endX,
    required this.endZ,
    required this.minX,
    required this.maxX,
    required this.minZ,
    required this.maxZ,
  });
}

/// Pista del suelo de cada animación, por nombre. Las que no mueven [rootBone]
/// no aparecen. Lanza [FormatException] si no es un .glb legible.
Map<String, FloorTrack> readFloorTracks(Uint8List glb, {String rootBone = 'root.x'}) {
  final (json, bin) = _chunks(glb);
  final nodes = (json['nodes'] as List?) ?? const [];
  final root = nodes.indexWhere((n) => n is Map && n['name'] == rootBone);
  if (root == -1) return {};

  final tracks = <String, FloorTrack>{};
  for (final animation in (json['animations'] as List?) ?? const []) {
    final anim = animation as Map<String, Object?>;
    final samplers = anim['samplers'] as List;
    for (final channel in anim['channels'] as List) {
      final target = (channel as Map)['target'] as Map;
      if (target['node'] != root || target['path'] != 'translation') continue;
      final sampler = samplers[channel['sampler'] as int] as Map;
      var points = _vec3s(json, bin, sampler['output'] as int);
      // CUBICSPLINE guarda tangente de entrada, valor y tangente de salida.
      if (sampler['interpolation'] == 'CUBICSPLINE') {
        points = [for (var i = 1; i < points.length; i += 3) points[i]];
      }
      if (points.isEmpty) continue;
      tracks[anim['name'] as String? ?? ''] = _track(points);
      break;
    }
  }
  return tracks;
}

FloorTrack _track(List<(double, double)> points) {
  final xs = [for (final p in points) p.$1];
  final zs = [for (final p in points) p.$2];
  double min(List<double> v) => v.reduce((a, b) => a < b ? a : b);
  double max(List<double> v) => v.reduce((a, b) => a > b ? a : b);
  return FloorTrack(
    startX: xs.first,
    startZ: zs.first,
    endX: xs.last,
    endZ: zs.last,
    minX: min(xs),
    maxX: max(xs),
    minZ: min(zs),
    maxZ: max(zs),
  );
}

(Map<String, Object?>, ByteData) _chunks(Uint8List glb) {
  final data = ByteData.sublistView(glb);
  if (glb.length < 20 || data.getUint32(0, Endian.little) != _glbMagic) {
    throw const FormatException('No es un archivo .glb');
  }
  Map<String, Object?>? json;
  var bin = ByteData(0);
  var offset = 12;
  while (offset + 8 <= glb.length) {
    final length = data.getUint32(offset, Endian.little);
    final type = data.getUint32(offset + 4, Endian.little);
    final start = offset + 8;
    if (start + length > glb.length) throw const FormatException('Bloque del .glb cortado');
    if (type == _jsonChunk) {
      json = jsonDecode(utf8.decode(glb.sublist(start, start + length))) as Map<String, Object?>;
    } else if (type == _binChunk) {
      bin = ByteData.sublistView(glb, start, start + length);
    }
    offset = start + length;
  }
  if (json == null) throw const FormatException('El .glb no trae bloque JSON');
  return (json, bin);
}

/// Los (x, z) de un accesor VEC3 de floats.
List<(double, double)> _vec3s(Map<String, Object?> json, ByteData bin, int index) {
  final accessor = (json['accessors'] as List)[index] as Map;
  if (accessor['componentType'] != _float || accessor['type'] != 'VEC3') {
    throw const FormatException('La traslación del hueso raíz no es VEC3 de floats');
  }
  final view = (json['bufferViews'] as List)[accessor['bufferView'] as int] as Map;
  final base = ((view['byteOffset'] as int?) ?? 0) + ((accessor['byteOffset'] as int?) ?? 0);
  final stride = (view['byteStride'] as int?) ?? 12;
  final count = accessor['count'] as int;
  return [
    for (var i = 0; i < count; i++)
      (bin.getFloat32(base + i * stride, Endian.little), bin.getFloat32(base + i * stride + 8, Endian.little)),
  ];
}
