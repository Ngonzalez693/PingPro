import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

final String _baseUrl = dotenv.env['API_BASE_URL']!;

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

class Model3dCatalog {
  Model3dCatalog._();
  static final Model3dCatalog instance = Model3dCatalog._();

  bool _loaded = false;
  String? _error;
  final Map<String, Model3dModel> _byName = {}; // name -> model

  bool get loaded => _loaded;
  String? get error => _error;

  Future<void> loadIfNeeded() async {
    if (_loaded) return;
    try {
      final u = FirebaseAuth.instance.currentUser;
      final token = await u?.getIdToken();
      final r = await http.get(
        Uri.parse('$_baseUrl/api/model3d'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (r.statusCode != 200) {
        throw Exception('Model3D list failed: ${r.statusCode} ${r.body}');
      }
      final list = (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
      _byName
        ..clear()
        ..addEntries(list.map((e) {
          final m = Model3dModel.fromJson(e);
          return MapEntry(m.name.trim().toLowerCase(), m);
        }));
      _loaded = true;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  /// Devuelve URL por nombre (case-insensitive)
  String? urlByName(String modelName) {
    final key = modelName.trim().toLowerCase();
    return _byName[key]?.url;
  }
}
