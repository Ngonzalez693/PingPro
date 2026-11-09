// Perfil del usuario: foto, nombre y correo, y la edición del nombre.
// La contraseña y el cierre de sesión están en Configuración.
//
// En reposo se ve la tarjeta con los datos; tocar el nombre la cambia por el
// formulario. El nombre se guarda en el backend (PUT /api/users/{uid}, vía
// AuthService) y además en Firebase Auth.
//
// Cambiar la foto está desactivado hasta tener Supabase Storage: el bucket de
// Firebase Storage nunca existió (pide el plan Blaze). El avatar muestra la
// foto si el perfil ya tiene una.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/motion.dart';
import 'package:pingpro_front/core/services/auth_service.dart';
import 'package:pingpro_front/widgets/profile_details_card.dart';
import 'package:pingpro_front/widgets/profile_name_form.dart';

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

  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

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

        // Intento traer perfil extendido de tu backend (si falla, seguimos con Firebase)
        try {
          final profile = await _authService.fetchUserProfile();
          _userName = profile['displayName'] ?? _userName;
          _userEmail = profile['email'] ?? _userEmail;
          _imageUrl = profile['photoURL'] ?? _imageUrl;
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

  // Si falla se queda en el formulario, para no perder lo escrito.
  Future<void> _saveName(String newName) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      // Primero el backend (users/{uid}) y después Firebase Auth, para no dejar
      // Auth con un nombre que el perfil no llegó a guardar.
      await _authService.updateProfile(displayName: newName);
      await FirebaseAuth.instance.currentUser!.updateDisplayName(newName);
      if (!mounted) return;
      setState(() {
        _userName = newName;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
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
      return Scaffold(
        backgroundColor: context.colors.page,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.page,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildIdentity(context),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: motionDuration(context, const Duration(milliseconds: 200)),
                child: _editing
                    ? ProfileNameForm(
                        key: const ValueKey('form'),
                        initialName: _userName,
                        email: _userEmail,
                        saving: _saving,
                        onSave: _saveName,
                        onCancel: () => setState(() => _editing = false),
                      )
                    : ProfileDetailsCard(
                        key: const ValueKey('card'),
                        name: _userName,
                        email: _userEmail,
                        onEditName: () => setState(() => _editing = true),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.onPage),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        Text('Perfil', style: context.text.title),
      ],
    );
  }

  Widget _buildIdentity(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: surfaceOutline(context.colors),
          ),
          child: CircleAvatar(
            radius: 42,
            backgroundColor: context.colors.card,
            backgroundImage: _imageUrl != null
                ? NetworkImage(_imageUrl!)
                : const AssetImage('assets/images/avatar_placeholder.png')
                    as ImageProvider,
          ),
        ),
        const SizedBox(height: 12),
        Text(_userName, style: context.text.subTitle, textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(_userEmail, style: context.text.caption, textAlign: TextAlign.center),
      ],
    );
  }
}
