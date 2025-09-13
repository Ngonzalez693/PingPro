import 'package:flutter/material.dart';
import 'package:pingpro_front/core/services/auth_service.dart';

class PingproProfileScreen extends StatefulWidget {
  const PingproProfileScreen({super.key});

  @override
  State createState() => _PingproProfileScreenState();
}

class _PingproProfileScreenState extends State<PingproProfileScreen> {
  Map<String, dynamic>? userData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await AuthService().fetchUserProfile();
      setState(() {
        userData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Tu diseño: Foto, nombre, correo, etc...
          CircleAvatar(radius: 40, backgroundImage: NetworkImage(userData?['photoURL'] ?? "")),
          Text(userData?['displayName'] ?? "Usuario", style: const TextStyle(color: Colors.white)),
          Text(userData?['email'] ?? "", style: const TextStyle(color: Colors.white70)),
          // ... Los demás campos que quieras mostrar
        ],
      ),
    );
  }
}
