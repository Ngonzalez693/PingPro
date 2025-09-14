import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/models/training_model.dart';

class TrainingsService {
  final _baseUrl = dotenv.env['API_BASE_URL']!;

  Future<List<TrainingModel>> fetchAll() async {
    final uri = Uri.parse('$_baseUrl/api/trainings');
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('Error al cargar trainings (${res.statusCode})');
    }
    final Map<String, dynamic> json = jsonDecode(res.body) as Map<String, dynamic>;
    final List<dynamic> list = json['data'] as List<dynamic>;
    return list.map((item) => TrainingModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}
