/// Edición de perfil: nombre, contraseña, foto y cierre de sesión.
///
/// EXCEPCIÓN ARQUITECTÓNICA: es la única pantalla que escribe en Firestore y
/// Firebase Storage directamente, saltándose el backend. El resto de la app
/// pasa siempre por la API. Se hizo así porque cambiar contraseña y subir foto
/// requieren el SDK cliente de Firebase, pero deja la escritura de users/{uid}
/// dependiendo de las reglas de seguridad de Firestore en lugar de la API.
///
/// La escritura se hace con merge:true para no borrar los campos que no se
/// tocan (roles, createdAt) ni las subcolecciones de progreso.
///
/// PENDIENTE: cambiar la contraseña puede fallar con 'requires-recent-login' si
/// la sesión es vieja. Hoy solo se muestra un aviso; falta el flujo de
/// reautenticación.
// ignore_for_file: use_build_context_synchronously

import 'dart:io' show File;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  bool _editingPassword = false;
  bool _isEditing = false;

  final TextEditingController _nameEditCtrl = TextEditingController();
  final TextEditingController _passwordEditCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;     // pantalla cargando
  bool _saving = false;     // guardando cambios / subiendo imagen

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
    final uid = user.uid;
    final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final newName = _nameEditCtrl.text.trim();
    final newPass = _passwordEditCtrl.text.trim();

    try {
      // Actualizar displayName
      if (newName.isNotEmpty && newName != _userName) {
        await user.updateDisplayName(newName);
        _userName = newName;
      }

      // Actualizar password (si el usuario escribió algo)
      if (newPass.isNotEmpty) {
        if (newPass.length < 6) {
          throw FirebaseAuthException(
            code: 'weak-password',
            message: 'La contraseña debe tener al menos 6 caracteres',
          );
        }
        try {
          await user.updatePassword(newPass);
          _passwordEditCtrl.clear();
        } on FirebaseAuthException catch (e) {
          // Requiere reautenticación reciente
          if (e.code == 'requires-recent-login') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Por seguridad debes iniciar sesión de nuevo para cambiar la contraseña.',
                ),
              ),
            );
          } else {
            rethrow;
          }
        }
      }

      // Firestore (merge)
      final updates = <String, dynamic>{
        'displayName': _userName,
        if (_imageUrl != null) 'photoURL': _imageUrl,
        'email': _userEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await usersRef.set(updates, SetOptions(merge: true));

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

  Future<void> _pickAndUploadImage() async {
    if (_saving) return;
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseStorage.instance.ref().child('profiles/$uid.jpg');

      // Carga según plataforma: en web no existe dart:io File, así que la
      // imagen se sube como bytes en vez de como archivo.
      if (kIsWeb) {
        final bytes = await img.readAsBytes();
        await ref.putData(bytes);
      } else {
        final file = File(img.path);
        await ref.putFile(file);
      }

      final url = await ref.getDownloadURL();

      // Actualiza Firebase Auth
      await FirebaseAuth.instance.currentUser!.updatePhotoURL(url);

      // Firestore merge
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'photoURL': url, 'updatedAt': FieldValue.serverTimestamp()},
              SetOptions(merge: true));

      if (mounted) setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error subiendo imagen: $e')),
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

                  // Avatar + editar foto
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.widgetGrayBackground,
                          backgroundImage: _imageUrl != null
                              ? NetworkImage(_imageUrl!)
                              : const AssetImage('assets/images/avatar_placeholder.png')
                                  as ImageProvider,
                        ),
                        GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.edit, size: 16, color: AppColors.textBlack),
                          ),
                        ),
                      ],
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

                  const SizedBox(height: 12),

                  // Contraseña
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _editingPassword
                          ? SizedBox(
                              width: 220,
                              child: TextField(
                                controller: _passwordEditCtrl,
                                obscureText: true,
                                style: TextStyles.paragraph,
                                decoration: const InputDecoration(
                                  hintText: 'Nueva contraseña',
                                ),
                              ),
                            )
                          : Text('Contraseña: ••••••••', style: TextStyles.paragraph),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isEditing
                            ? () => setState(() => _editingPassword = !_editingPassword)
                            : null,
                        child: Icon(
                          Icons.edit,
                          size: 20,
                          color: _isEditing ? AppColors.primary : Colors.grey,
                        ),
                      ),
                    ],
                  ),

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
                            _editingPassword = false;
                          });
                        } else {
                          setState(() {
                            _isEditing = true;
                            _editingName = true;
                            _editingPassword = true;
                          });
                        }
                      },
                      child: Text(buttonLabel, style: TextStyles.buttons),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cerrar sesión
                  SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secundary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppColors.widgetGrayBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: const EdgeInsets.all(24),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '¿Quieres cerrar sesión?',
                                  textAlign: TextAlign.center,
                                  style: TextStyles.paragraphBlack,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text(
                                      'Sí, salir',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.widgetGrayBackground,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Volver',
                                        style: TextStyles.paragraphBlack),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (shouldLogout == true) {
                          try {
                            await _authService.logout();
                            if (!mounted) return;
                            Navigator.of(context)
                                .pushNamedAndRemoveUntil('/login', (_) => false);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: Text("Cerrar sesión", style: TextStyles.buttons),
                    ),
                  ),
                ],
              ),
            ),

            // Overlay de carga/guardado
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
