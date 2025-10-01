// ignore_for_file: use_build_context_synchronously

import 'dart:io';
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

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _userName = user.displayName ?? 'Usuario';
          _userEmail = user.email ?? '';
          _imageUrl = user.photoURL;
          _nameEditCtrl.text = _userName;
        });
        try {
          final profile = await _authService.fetchUserProfile();
          setState(() {
            _userName = profile['displayName'] ?? _userName;
            _userEmail = profile['email'] ?? _userEmail;
            _imageUrl = profile['photoURL'] ?? _imageUrl;
            _nameEditCtrl.text = _userName;
          });
        } catch (e) {
          if (kDebugMode) print('Error backend: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error al cargar perfil: $e');
      setState(() {
        _userName = 'Error al cargar';
        _userEmail = 'Error al cargar';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveChanges() async {
    final name = _nameEditCtrl.text.trim();
    final pass = _passwordEditCtrl.text.trim();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final updates = <String, dynamic>{};

    if (name.isNotEmpty && name != _userName) {
      await FirebaseAuth.instance.currentUser!.updateDisplayName(name);
      updates['displayName'] = name;
      _userName = name;
    }
    if (pass.isNotEmpty) {
      await FirebaseAuth.instance.currentUser!.updatePassword(pass);
      _passwordEditCtrl.clear();
    }

    // Actualizar Firestore solo si hay campos nuevos
    if (updates.isNotEmpty) {
      await usersRef.update(updates);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    final file = File(img.path);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final storage = FirebaseStorage.instanceFor(
      bucket: 'tu-bucket.appspot.com',
    );
    final ref = storage.ref('profiles/$uid.jpg');

    // Muestra indicador
    setState(() => _loading = true);

    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    // Actualiza estado y perfil de usuario
    setState(() {
      _imageUrl = url;
    });
    await FirebaseAuth.instance.currentUser!.updatePhotoURL(url);

    // Guarda en Firestore:
    final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await usersRef.update({'photoURL': url});

    setState(() => _loading = false);
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
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.widgetGrayBackground,
                        backgroundImage:
                            _imageUrl != null
                                ? NetworkImage(_imageUrl!)
                                : const AssetImage(
                                      'assets/images/avatar_placeholder.png',
                                    )
                                    as ImageProvider,
                      ),
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: AppColors.textBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Nombre
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _editingName
                          ? SizedBox(
                            width: 180,
                            child: TextField(
                              controller: _nameEditCtrl,
                              style: TextStyles.title,
                              decoration: const InputDecoration(
                                border: UnderlineInputBorder(),
                              ),
                            ),
                          )
                          : Text(_userName, style: TextStyles.title),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap:
                            _isEditing
                                ? () =>
                                    setState(() => _editingName = !_editingName)
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
                            width: 180,
                            child: TextField(
                              controller: _passwordEditCtrl,
                              obscureText: true,
                              style: TextStyles.paragraph,
                              decoration: const InputDecoration(
                                hintText: 'Nueva contraseña',
                              ),
                            ),
                          )
                          : Text(
                            'Contraseña: ••••••••',
                            style: TextStyles.paragraph,
                          ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap:
                            _isEditing
                                ? () => setState(
                                  () => _editingPassword = !_editingPassword,
                                )
                                : null,
                        child: Icon(
                          Icons.edit,
                          size: 20,
                          color: _isEditing ? AppColors.primary : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 74),
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
            const SizedBox(height: 20),
            // Cerrar sesión botón...
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
                    builder:
                        (_) => AlertDialog(
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
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
                                    backgroundColor:
                                        AppColors.widgetGrayBackground,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text(
                                    'Volver',
                                    style: TextStyles.paragraphBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  );
                  if (shouldLogout == true) {
                    try {
                      await _authService.logout();
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (_) => false);
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: Text("Cerrar sesión", style: TextStyles.buttons),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
