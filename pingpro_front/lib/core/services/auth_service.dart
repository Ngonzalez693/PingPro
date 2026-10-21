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
import 'package:pingpro_front/core/load_errors.dart';
import 'package:pingpro_front/core/services/api_client.dart';
import 'package:pingpro_front/core/services/api_errors.dart';

/// Si el perfil de GET /api/users/me tiene el rol admin.
///
/// Ante cualquier duda dice que no: un perfil vacío (fetchUserProfile devuelve
/// {} si la petición falla), sin `roles` o con un formato raro no es admin. Solo
/// decide si se enseña un botón; el permiso real lo comprueba el backend.
bool hasAdminRole(Map<String, dynamic> profile) {
  final roles = profile['roles'];
  return roles is List && roles.contains('admin');
}

/// Mensaje para el usuario según el código de FirebaseAuthException que lanza
/// [AuthService.sendPasswordReset].
String passwordResetErrorMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'Email no válido';
    case 'too-many-requests':
      return _tooManyAttemptsMessage;
    case 'network-request-failed':
      return noConnectionMessage;
    default:
      return 'No se pudo enviar el correo, inténtalo de nuevo';
  }
}

/// Mensajes de los errores de re-autenticación, comunes a cambiar la
/// contraseña y a eliminar la cuenta; null si [code] no es uno de ellos.
/// Firebase devuelve 'invalid-credential' en vez de 'wrong-password' cuando la
/// protección de enumeración está activa.
String? _reauthErrorMessage(String code) {
  switch (code) {
    case 'wrong-password':
    case 'invalid-credential':
      return 'La contraseña actual no es correcta';
    case 'too-many-requests':
      return _tooManyAttemptsMessage;
    case 'network-request-failed':
      return noConnectionMessage;
    default:
      return null;
  }
}

/// Mensaje para el usuario según el código de FirebaseAuthException que lanza
/// [AuthService.changePassword].
String passwordChangeErrorMessage(String code) {
  if (code == 'weak-password') return 'La nueva contraseña es demasiado débil';
  return _reauthErrorMessage(code) ?? 'No se pudo cambiar la contraseña, inténtalo de nuevo';
}

/// Lo mismo para [AuthService.deleteAccount].
String accountDeletionErrorMessage(String code) =>
    _reauthErrorMessage(code) ?? 'No se pudo eliminar la cuenta, inténtalo de nuevo';

const _tooManyAttemptsMessage = 'Demasiados intentos, prueba más tarde';

/// Mensaje para el usuario si falla [AuthService.login]. Firebase, con la
/// protección de enumeración activa, devuelve 'invalid-credential' sin decir
/// si falla el email o la contraseña; los demás códigos dicen lo mismo.
String loginErrorMessage(Object error) {
  if (isConnectionError(error)) return noConnectionMessage;
  if (error is! FirebaseAuthException) return 'No se pudo iniciar sesión, inténtalo de nuevo';
  switch (error.code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Email o contraseña incorrectos';
    case 'too-many-requests':
      return _tooManyAttemptsMessage;
    default:
      return 'No se pudo iniciar sesión, inténtalo de nuevo';
  }
}

/// Mensaje para el usuario si falla [AuthService.signupViaBackend]. El backend
/// devuelve el texto de firebase-admin, en inglés, así que no se enseña: si el
/// email ya existía el registro intenta iniciar sesión con él, y que la
/// contraseña no encaje es lo único que vale la pena explicar.
String registerErrorMessage(Object error) {
  if (isConnectionError(error)) return noConnectionMessage;
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
        return 'Ese email ya tiene una cuenta. Inicia sesión o recupera tu contraseña.';
      case 'too-many-requests':
        return _tooManyAttemptsMessage;
    }
  }
  return 'No se pudo crear la cuenta, inténtalo de nuevo';
}

/// Validación local antes de registrar; null si es válida. Sin ella el aviso
/// llegaría del backend, en inglés.
String? validateSignupPassword(String password) =>
    password.length < 6 ? 'La contraseña debe tener al menos 6 caracteres' : null;

/// Validación local antes de llamar a Firebase; null si es válida. El mínimo
/// de 6 es el que impone Firebase Auth.
String? validateNewPassword(String newPassword, String repeat) {
  if (newPassword.length < 6) {
    return 'La nueva contraseña debe tener al menos 6 caracteres';
  }
  if (newPassword != repeat) return 'Las contraseñas no coinciden';
  return null;
}

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

    final resp = await apiClient.post(
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

    // Si ya existía, probamos iniciar sesión. El mensaje es de firebase-admin
    // y no se enseña al usuario (registerErrorMessage).
    final msg = backendErrorMessage(resp.body, 'Error al registrar usuario en backend');
    if (msg.toLowerCase().contains('already in use')) {
      return _auth.signInWithEmailAndPassword(email: email, password: password);
    }
    throw Exception(msg);
  }

  /// Pide a Firebase el correo con el enlace para elegir una contraseña nueva.
  ///
  /// Si el email no tiene cuenta termina igual que si la tuviera: decirlo
  /// permitiría averiguar qué emails están registrados.
  Future<void> sendPasswordReset(String email) async {
    await _auth.setLanguageCode('es');
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return;
      rethrow;
    }
  }

  // Re-autenticar antes de una operación sensible evita el
  // 'requires-recent-login' que Firebase lanza si la sesión es vieja, y
  // confirma que quien la hace conoce la contraseña.
  Future<User> _reauthenticate(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) throw StateError('No hay sesión iniciada');
    final credential = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);
    return user;
  }

  /// Re-autentica con la contraseña actual y cambia a la nueva.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = await _reauthenticate(currentPassword);
    await user.updatePassword(newPassword);
  }

  /// Elimina la cuenta: re-autentica, pide al backend que borre el perfil, los
  /// datos y la cuenta de Auth (DELETE /api/users/me) y cierra la sesión.
  ///
  /// Lo borra el backend y no user.delete(): así datos y cuenta se van juntos
  /// y en el orden seguro (ver UserService.deleteAccount en el backend). Al
  /// cerrar sesión, AuthWrapper vacía los stores porque cambia el uid.
  Future<void> deleteAccount(String password) async {
    final user = await _reauthenticate(password);
    final token = await withRequestTimeout(user.getIdToken());
    final resp = await apiClient.delete(
      _u('/api/users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) {
      throw Exception('DELETE /api/users/me → ${resp.statusCode}: ${resp.body}');
    }
    await logout();
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Perfil extendido desde el backend (GET /api/users/me).
  ///
  /// Devuelve el documento users/{uid} de Firestore, que tiene campos que
  /// Firebase Auth no guarda (roles, createdAt). Si la petición falla devuelve
  /// un mapa vacío a propósito: quien lo llama cae en los datos de
  /// FirebaseAuth.currentUser en lugar de romper la pantalla.
  Future<Map<String, dynamic>> fetchUserProfile() async {
    final u = _auth.currentUser;
    if (u == null) return {};
    final token = await withRequestTimeout(u.getIdToken());

    final resp = await apiClient.get(
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

  /// Guarda el nombre del perfil en el backend (PUT /api/users/{uid}).
  ///
  /// El backend solo acepta displayName y photoURL: email y roles los rechaza
  /// a propósito. Si falla, lanza una excepción con el mensaje del backend.
  Future<void> updateProfile({required String displayName}) async {
    final u = _auth.currentUser;
    if (u == null) throw StateError('No hay sesión iniciada');
    final token = await withRequestTimeout(u.getIdToken());

    final resp = await apiClient.put(
      _u('/api/users/${u.uid}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'displayName': displayName}),
    );

    if (resp.statusCode == 200) return;
    throw Exception(backendErrorMessage(resp.body, 'No se pudo guardar el perfil'));
  }
}
