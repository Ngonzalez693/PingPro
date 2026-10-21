// Cliente HTTP de estadísticas: GET /api/stats/me/events.
//
// Devuelve eventos sueltos y no agregados; agruparlos es cosa de
// core/stats_series.dart, en la hora local del teléfono.
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pingpro_front/core/services/api_client.dart';
import 'package:pingpro_front/core/services/api_errors.dart';
import 'package:pingpro_front/models/stats_events_model.dart';

class StatsService {
  final String _baseUrl = dotenv.env['API_BASE_URL']!;

  Future<StatsEvents> fetchEvents(DateTime from) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = user == null ? null : await withRequestTimeout(user.getIdToken());
    final uri = Uri.parse('$_baseUrl/api/stats/me/events').replace(
      queryParameters: {'from': from.toUtc().toIso8601String()},
    );
    final r = await apiClient
        .get(uri, headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        });
    if (r.statusCode != 200) {
      throw Exception(backendErrorMessage(r.body, 'No se pudieron cargar las estadísticas'));
    }
    return parseStatsEvents(jsonDecode(r.body));
  }
}
