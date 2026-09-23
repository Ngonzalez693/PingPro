// Si el usuario de la sesión es admin, para toda la app.
//
// Antes solo lo sabía la pantalla de perfil. Ahora también lo necesitan los
// detalles de ejercicio y entrenamiento, que enseñan el menú de editar y
// eliminar en el contenido del catálogo. Se pide una vez por sesión;
// AuthWrapper llama a reset() al cambiar de usuario.
//
// Solo decide qué se enseña: el permiso real lo comprueba el backend.
import 'package:flutter/foundation.dart';
import 'package:pingpro_front/core/services/auth_service.dart';

class SessionRoles {
  SessionRoles(this._fetchProfile);

  static final SessionRoles instance = SessionRoles(() => AuthService().fetchUserProfile());

  final Future<Map<String, dynamic>> Function() _fetchProfile;
  Future<bool>? _isAdmin;

  /// Si el usuario actual es admin. Cualquier fallo (petición rota, perfil vacío,
  /// error del fetcher) cuenta como no admin y no se guarda, para reintentarlo
  /// la próxima vez.
  Future<bool> isAdmin() => _isAdmin ??= _load();

  void reset() => _isAdmin = null;

  Future<bool> _load() async {
    try {
      // Envolver en Future() para que los throws síncronos del fetcher no
      // cacheen antes de que ??= guarde el Future.
      final profile = await Future(_fetchProfile);
      // fetchUserProfile devuelve {} cuando la petición falla.
      if (profile.isEmpty) _isAdmin = null;
      return hasAdminRole(profile);
    } catch (e) {
      if (kDebugMode) debugPrint('No se pudo leer el rol del usuario: $e');
      _isAdmin = null;
      return false;
    }
  }
}

/// Si se puede editar y eliminar un elemento: lo propio siempre, el catálogo
/// solo si eres admin.
bool canManage({required bool isOwn, required bool isAdmin}) => isOwn || isAdmin;
