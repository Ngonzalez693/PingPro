// Autenticación. El flujo está partido entre Firebase y el backend a propósito:
//
//   Registro → POST /api/auth/signup. El backend crea la cuenta en Firebase
//              Auth Y el documento users/{uid} en una sola operación, así no
//              queda nunca una credencial sin perfil. Después la app inicia
//              sesión localmente con esas mismas credenciales.
//   Login    → 100% Firebase en el cliente, sin pasar por el backend.
//   Sesión   → el ID token de Firebase se manda como Bearer en cada petición
//              autenticada; el backend lo valida con verifyIdToken.
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final _auth = FirebaseAuth.instance;
  final String _baseUrl = dotenv.env['API_BASE_URL']!;

  Uri _u(String p) => Uri.parse('$_baseUrl$p');

  Future<Map<String, String>> _jsonHeaders() async =>
      {'Content-Type': 'application/json'};

  /// LOGIN normal con Firebase + tu backend si necesitas perfil
  Future<UserCredential> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred;
  }

  /// SIGNUP backend-driven:
  /// 1) Llama a /api/auth/signup (backend crea Auth + users doc)
  /// 2) Si ok, inicia sesión en Firebase con email/pass
  ///
  /// Si el backend devuelve "email in use", intentamos login directamente.
  Future<UserCredential> signupViaBackend({
    required String displayName,
    required String email,
    required String password,
  }) async {
    // Cerrar sesión previa para evitar usar token de otro usuario
    // (si alguien se registra sin haber cerrado la sesión anterior, el token
    // que quedara en memoria sería del usuario equivocado).
    try { await _auth.signOut(); } catch (_) {}

    final resp = await http.post(
      _u('/api/auth/signup'),
      headers: await _jsonHeaders(),
      body: jsonEncode({
        'displayName': displayName,
        'email': email,
        'password': password,
      }),
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      // Usuario creado por backend → ahora login en Firebase
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred;
    }

    // Parsear error del backend
    String msg = 'Error al registrar usuario en backend';
    try {
      final data = jsonDecode(resp.body);
      msg = data['message']?.toString() ?? msg;

      // Si ya existía, probamos iniciar sesión
      if (msg.toLowerCase().contains('already in use')) {
        final cred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return cred;
      }
    } catch (_) {}

    throw Exception('$msg: ${resp.body}');
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Perfil opcional desde backend (si lo tienes)
  ///
  /// NO FUNCIONA hoy: en el backend la ruta GET /me está declarada después de
  /// GET /:id, así que Express resuelve /api/users/me como getById("me") y esto
  /// devuelve {} en silencio. Ver el comentario en userRoutes.ts.
  /// Por eso la pantalla de perfil termina mostrando los datos de Firebase Auth.
  Future<Map<String, dynamic>> fetchUserProfile() async {
    final u = _auth.currentUser;
    if (u == null) return {};
    final token = await u.getIdToken();

    final resp = await http.get(
      _u('/api/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode != 200) {
      if (kDebugMode) {
        print('fetchUserProfile error: ${resp.body}');
      }
      return {};
    }
    final data = jsonDecode(resp.body);
    return (data is Map && data['data'] is Map) ? Map<String, dynamic>.from(data['data']) : Map<String, dynamic>.from(data);
  }
}
