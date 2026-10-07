// Configuración: la abre la tuerca del perfil.
//
// Cada etapa del plan agrega su sección cuando funciona (Notificaciones y
// Apariencia llegan después): nunca se muestra una opción
// que todavía no hace nada. Ver docs del diseño de Configuración.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/services/auth_service.dart';
import 'package:pingpro_front/core/support_mail.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/change_password_dialog.dart';
import 'package:pingpro_front/widgets/delete_account_dialog.dart';
import 'package:pingpro_front/widgets/logout_dialog.dart';
import 'package:pingpro_front/widgets/settings_section_header.dart';
import 'package:pingpro_front/widgets/settings_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class PingproSettingsScreen extends StatefulWidget {
  const PingproSettingsScreen({super.key});

  @override
  State<PingproSettingsScreen> createState() => _PingproSettingsScreenState();
}

class _PingproSettingsScreenState extends State<PingproSettingsScreen> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  // Si falla solo se registra: la versión es informativa y la fila se queda en '…'.
  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    } catch (e) {
      debugPrint('PackageInfo error: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onChangePassword() async {
    final changed = await showChangePasswordDialog(context);
    if (changed && mounted) _showMessage('Contraseña actualizada');
  }

  Future<void> _onLogout() async {
    if (!await showLogoutDialog(context)) return;
    try {
      await AuthService().logout();
      if (!mounted) return;
      // Login encima de la raíz, no en lugar de ella: la raíz es AuthWrapper y
      // es quien vacía los stores al cambiar el uid.
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => route.isFirst);
    } catch (e) {
      if (mounted) _showMessage('Error: $e');
    }
  }

  Future<void> _onDeleteAccount() async {
    // Se toma antes: al volver a la raíz esta pantalla sale de la pila y su
    // context ya no sirve para mostrar el aviso en la bienvenida.
    final messenger = ScaffoldMessenger.of(context);
    if (!await showDeleteAccountDialog(context)) return;
    if (!mounted) return;
    // La raíz es AuthWrapper: con la sesión ya cerrada muestra la bienvenida y
    // vacía los stores al cambiar el uid.
    Navigator.of(context).popUntil((route) => route.isFirst);
    messenger.showSnackBar(const SnackBar(content: Text('Tu cuenta fue eliminada')));
  }

  Future<void> _open(Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) _showMessage('No se pudo abrir el enlace');
    } catch (e) {
      debugPrint('launchUrl error: $e');
      if (mounted) _showMessage('No se pudo abrir el enlace');
    }
  }

  // Tema oscuro solo para esta ruta: con el tema de la app el texto de
  // LicensePage sale negro sobre el fondo negro del scaffold.
  void _openLicenses() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Theme(
        data: ThemeData.dark(),
        child: LicensePage(
          applicationName: 'PingPro',
          applicationVersion: _version,
          applicationIcon: Image.asset('assets/images/LogoInv_PingPro.png', height: 64),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _buildHeader(),
            ..._buildAccountSection(),
            ..._buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(child: Text('Configuración', style: TextStyles.title)),
        ],
      ),
    );
  }

  List<Widget> _buildAccountSection() {
    return [
      const SettingsSectionHeader(title: 'Cuenta'),
      SettingsTile(
        icon: Icons.email_outlined,
        title: 'Correo',
        subtitle: FirebaseAuth.instance.currentUser?.email ?? '',
      ),
      SettingsTile(icon: Icons.lock_outline, title: 'Cambiar contraseña', onTap: _onChangePassword),
      SettingsTile(icon: Icons.logout, title: 'Cerrar sesión', onTap: _onLogout),
      // Separada y en rojo: es la única acción de Configuración que no se deshace.
      const Divider(color: AppColors.textGray, indent: 16, endIndent: 16),
      SettingsTile(
        icon: Icons.delete_forever_outlined,
        title: 'Eliminar cuenta',
        destructive: true,
        onTap: _onDeleteAccount,
      ),
    ];
  }

  List<Widget> _buildAboutSection() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final mailUri = supportMailUri(
      email: dotenv.env['SUPPORT_EMAIL'],
      version: _version ?? 'desconocida',
    );
    return [
      const SettingsSectionHeader(title: 'Acerca de'),
      SettingsTile(icon: Icons.info_outline, title: 'Versión', subtitle: _version ?? '…'),
      SettingsTile(
        icon: Icons.privacy_tip_outlined,
        title: 'Política de privacidad',
        onTap: () => _open(Uri.parse('$baseUrl/privacy')),
      ),
      if (mailUri != null)
        SettingsTile(
          icon: Icons.bug_report_outlined,
          title: 'Reportar un problema',
          onTap: () => _open(mailUri),
        ),
      SettingsTile(
        icon: Icons.description_outlined,
        title: 'Licencias de código abierto',
        onTap: _openLicenses,
      ),
    ];
  }
}
