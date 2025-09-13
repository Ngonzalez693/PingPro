import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/models/exercise_model.dart';

class ExercisesService {
  final _baseUrl = dotenv.env['API_BASE_URL']!;

  Future<List<ExerciseModel>> fetchAll() async {
    final uri = Uri.parse('$_baseUrl/api/exercises');
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Error al cargar ejercicios (${response.statusCode})');
    }

    // parsear el JSON completo como Map
    final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
    // extraer lista desde la clave "data"
    final List<dynamic> list = json['data'] as List<dynamic>;

    return list
        .map((item) => ExerciseModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
