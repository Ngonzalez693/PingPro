// Cliente HTTP de estadísticas: GET /api/stats/me/events.
//
// Devuelve eventos sueltos y no agregados; agruparlos es cosa de
// core/stats_series.dart, en la hora local del teléfono.
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pingpro_front/core/services/api_errors.dart';
import 'package:pingpro_front/models/stats_events_model.dart';

class StatsService {
  final String _baseUrl = dotenv.env['API_BASE_URL']!;

  Future<StatsEvents> fetchEvents(DateTime from) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final uri = Uri.parse('$_baseUrl/api/stats/me/events').replace(
      queryParameters: {'from': from.toUtc().toIso8601String()},
    );
    final r = await http
        .get(uri, headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        })
        .timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) {
      throw Exception(backendErrorMessage(r.body, 'No se pudieron cargar las estadísticas'));
    }
    return parseStatsEvents(jsonDecode(r.body));
  }
}
