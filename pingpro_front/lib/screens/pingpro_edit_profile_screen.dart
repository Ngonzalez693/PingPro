// Edición de perfil: nombre (y foto cuando haya Storage).
// La contraseña y el cierre de sesión están en Configuración.
//
// El nombre se guarda en el backend (PUT /api/users/{uid}, vía AuthService) y
// además en Firebase Auth.
//
// Cambiar la foto está desactivado hasta tener Supabase Storage: el bucket de
// Firebase Storage nunca existió (pide el plan Blaze). El avatar muestra la
// foto si el perfil ya tiene una.
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/core/services/auth_service.dart';

class PingproEditProfileScreen extends StatefulWidget {
  const PingproEditProfileScreen({super.key});
  @override
  State<PingproEditProfileScreen> createState() =>
      _PingproEditProfileScreenState();
}

class _PingproEditProfileScreenState extends State<PingproEditProfileScreen> {
  final _authService = AuthService();

  String _userName = 'Cargando...';
  String _userEmail = 'Cargando...';
  String? _imageUrl;

  bool _editingName = false;
  bool _isEditing = false;

  final TextEditingController _nameEditCtrl = TextEditingController();

  bool _loading = true;     // pantalla cargando
  bool _saving = false;     // guardando cambios

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userName = user.displayName ?? 'Usuario';
        _userEmail = user.email ?? '';
        _imageUrl = user.photoURL;
        _nameEditCtrl.text = _userName;

        // Intento traer perfil extendido de tu backend (si falla, seguimos con Firebase)
        try {
          final profile = await _authService.fetchUserProfile();
          _userName = profile['displayName'] ?? _userName;
          _userEmail = profile['email'] ?? _userEmail;
          _imageUrl = profile['photoURL'] ?? _imageUrl;
          _nameEditCtrl.text = _userName;
        } catch (e) {
          if (kDebugMode) debugPrint('Error backend profile: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error al cargar perfil: $e');
      _userName = 'Error al cargar';
      _userEmail = 'Error al cargar';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_saving) return;
    setState(() => _saving = true);

    final user = FirebaseAuth.instance.currentUser!;
    final newName = _nameEditCtrl.text.trim();

    try {
      // Nombre: primero el backend (users/{uid}) y después Firebase Auth, para
      // no dejar Auth con un nombre que el perfil no llegó a guardar.
      if (newName.isNotEmpty && newName != _userName) {
        await _authService.updateProfile(displayName: newName);
        await user.updateDisplayName(newName);
        _userName = newName;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final buttonLabel = _isEditing ? 'Guardar' : 'Editar información';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Avatar (cambiar la foto vuelve con Supabase Storage)
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.widgetGrayBackground,
                      backgroundImage: _imageUrl != null
                          ? NetworkImage(_imageUrl!)
                          : const AssetImage('assets/images/avatar_placeholder.png')
                              as ImageProvider,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Nombre
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _editingName
                          ? SizedBox(
                              width: 220,
                              child: TextField(
                                controller: _nameEditCtrl,
                                style: TextStyles.title,
                                decoration: const InputDecoration(
                                  hintText: 'Nombre',
                                  border: UnderlineInputBorder(),
                                ),
                              ),
                            )
                          : Text(_userName, style: TextStyles.title),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isEditing
                            ? () => setState(() => _editingName = !_editingName)
                            : null,
                        child: Icon(
                          Icons.edit,
                          size: 20,
                          color: _isEditing ? AppColors.primary : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Text('Correo: $_userEmail', style: TextStyles.paragraph),

                  const SizedBox(height: 48),

                  // Botón editar/guardar
                  SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        if (_isEditing) {
                          await _saveChanges();
                          if (!mounted) return;
                          setState(() {
                            _isEditing = false;
                            _editingName = false;
                          });
                        } else {
                          setState(() {
                            _isEditing = true;
                            _editingName = true;
                          });
                        }
                      },
                      child: Text(buttonLabel, style: TextStyles.buttons),
                    ),
                  ),
                ],
              ),
            ),

            // Overlay de guardado
            if (_saving)
              Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
