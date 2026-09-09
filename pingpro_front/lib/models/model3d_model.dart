// Una animación 3D del catálogo: nombre → URL del archivo .glb.
//
// DUPLICADO: existe otra clase idéntica dentro de
// core/services/model3d_catalog.dart. La del catálogo es la que se usa en el
// flujo 3D; esta solo la consume Model3DService. Conviene dejar una sola.
class Model3dModel {
  final String id;
  final String name;
  final String url;
  final DateTime createdAt;
  final DateTime updatedAt;

  Model3dModel({
    required this.id,
    required this.name,
    required this.url,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Model3dModel.fromJson(Map<String, dynamic> j) => Model3dModel(
        id: j['id'] as String,
        name: j['name'] as String,
        url: j['url'] as String,
        createdAt: DateTime.parse(j['createdAt']),
        updatedAt: DateTime.parse(j['updatedAt']),
      );
}
