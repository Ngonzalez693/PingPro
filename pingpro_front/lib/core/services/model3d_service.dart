// Cliente HTTP del catálogo de modelos 3D.
//
// SIN USO en el flujo actual: quien pide /api/model3d es Model3dCatalog, que
// además cachea e indexa por nombre. Este servicio queda como acceso genérico
// (incluye getById, que el catálogo no necesita).
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/models/model3d_model.dart';

class Model3DService {
  final _base = dotenv.env['API_BASE_URL']!;
  Uri _u(String p) => Uri.parse('$_base$p');

  Future<Map<String, String>> _headers() async {
    final u = FirebaseAuth.instance.currentUser;
    final t = await u?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
    }

  Future<List<Model3dModel>> list() async {
    final r = await http.get(_u('/api/model3d'), headers: await _headers());
    if (r.statusCode != 200) throw Exception('Error listando Model3D: ${r.body}');
    final data = jsonDecode(r.body) as List;
    return data.map((e) => Model3dModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Model3dModel> getById(String id) async {
    final r = await http.get(_u('/api/model3d/$id'), headers: await _headers());
    if (r.statusCode != 200) throw Exception('Error obteniendo Model3D: ${r.body}');
    final j = jsonDecode(r.body);
    return Model3dModel.fromJson(Map<String, dynamic>.from(j));
  }
}
