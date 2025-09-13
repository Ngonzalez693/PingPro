import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final _firebaseAuth = FirebaseAuth.instance;
  final _baseUrl = 'PUERTO_BACKEND';

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // 1) Crear usuario Firebase Auth
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);

    // 2) Obtener Id Token para autenticación en backend
    final idToken = await cred.user!.getIdToken();

    // 3) Registrar en backend (crea usuario en Firestore)
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/auth/signup'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'displayName': displayName,
      }),
    );

    if (resp.statusCode != 201) {
      throw Exception('Error al registrar usuario en backend: ${resp.body}');
    }
  }

  Future<void> login({required String email, required String password}) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final idToken = await cred.user!.getIdToken();

    final resp = await http.post(
      Uri.parse('$_baseUrl/api/auth/verify'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Token inválido');
    }
  }

  Future<String?> getIdToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No autenticado');
    return await user.getIdToken();
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  Future<Map<String, dynamic>> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final resp = await http.get(
      Uri.parse('$_baseUrl/api/users/me'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body)['data'] as Map<String, dynamic>;
    } else {
      throw Exception('No se pudo cargar el perfil');
    }
  }
}
