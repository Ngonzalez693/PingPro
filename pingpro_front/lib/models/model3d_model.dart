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
