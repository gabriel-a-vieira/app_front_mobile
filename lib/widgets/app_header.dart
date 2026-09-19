import 'package:app_front_mobile/models/system_module.dart';
import 'package:app_front_mobile/pages/appointment_management_page.dart';
import 'package:app_front_mobile/pages/availability_management_page.dart';
import 'package:app_front_mobile/pages/client_management_page.dart';
import 'package:app_front_mobile/pages/company_management_page.dart';
import 'package:app_front_mobile/pages/login_page.dart';
import 'package:app_front_mobile/pages/my_appointments_page.dart';
import 'package:app_front_mobile/pages/permission_management_page.dart';
import 'package:app_front_mobile/pages/product_management_page.dart';
import 'package:app_front_mobile/pages/professional_management_page.dart';
import 'package:app_front_mobile/pages/profile_page.dart';
import 'package:app_front_mobile/pages/register_page.dart';
import 'package:app_front_mobile/pages/service_offering_management_page.dart';
import 'package:app_front_mobile/pages/user_management_page.dart';
import 'package:app_front_mobile/services/google_auth_service.dart';
import 'package:app_front_mobile/utils/auth_gate.dart';
import 'package:app_front_mobile/utils/auth_session.dart';
import 'package:app_front_mobile/utils/user_permissions.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../locale_provider.dart';
import '../theme_notifier.dart';

/// Which top-nav item (if any) reflects the page currently on screen, so
/// [AppHeader] can highlight it and skip re-navigating when already there.
enum AppHeaderRoute { home, myAppointments, none }

class _LanguageOption {
  final Locale locale;
  final String countryCode;
  final String shortLabel;
  final String fullLabel;

  const _LanguageOption({
    required this.locale,
    required this.countryCode,
    required this.shortLabel,
    required this.fullLabel,
  });
}

const List<_LanguageOption> _languageOptions = [
  _LanguageOption(
    locale: Locale('pt', 'BR'),
    countryCode: 'BR',
    shortLabel: 'BR',
    fullLabel: 'Portugues - Brasil',
  ),
  _LanguageOption(
    locale: Locale('en', 'US'),
    countryCode: 'US',
    shortLabel: 'USA',
    fullLabel: 'English - United States',
  ),
];

/// The header used on every screen: logo, top nav (Inicio/Meus agendamentos),
/// the Admin menu (gated per module by [UserPermissions]), theme toggle,
/// language selector and the login/profile/logout button.
///
/// Session state (logged-in name/role) is read from [AuthSession]'s cache so
/// switching pages doesn't re-fetch the profile every time; it still listens
/// to [AuthSession.sessionChanged] to stay correct across login/logout
/// triggered from anywhere in the app.
class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  final AppHeaderRoute currentRoute;

  const AppHeader({super.key, this.currentRoute = AppHeaderRoute.none});

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  String? _loggedUserFirstName = AuthSession.cachedFirstName;
  String? _loggedUserRole = AuthSession.cachedRole;

  bool get _isLoggedIn {
    return _loggedUserFirstName != null && _loggedUserFirstName!.isNotEmpty;
  }

  bool get _isMasterAdmin {
    return _loggedUserRole == 'MASTER_ADMIN';
  }

  bool get _isCompanyAdmin {
    return _loggedUserRole == 'COMPANY_ADMIN';
  }

  bool get _canSeeAdminMenu {
    return _isMasterAdmin || _isCompanyAdmin;
  }

  @override
  void initState() {
    super.initState();
    AuthSession.sessionChanged.addListener(_onSessionChanged);
    _refreshSession();
  }

  @override
  void dispose() {
    AuthSession.sessionChanged.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    _refreshSession();
  }

  Future<void> _refreshSession() async {
    await AuthSession.refreshProfile();

    if (!mounted) return;

    setState(() {
      _loggedUserFirstName = AuthSession.cachedFirstName;
      _loggedUserRole = AuthSession.cachedRole;
    });
  }

  void _goToHome() {
    if (widget.currentRoute == AppHeaderRoute.home) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openMyAppointmentsPage() async {
    if (widget.currentRoute == AppHeaderRoute.myAppointments) return;

    final logged = await AuthGate.requireLogin(
      context,
      reason: AppLocalizations.of(context).loginRequiredForAppointments,
    );

    if (!logged || !mounted) return;

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MyAppointmentsPage()));
  }

  Future<void> _openProfilePage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
  }

  Future<void> _logout() async {
    await AuthSession.invalidate();
    await GoogleAuthService.instance.signOut();
  }

  Future<void> _openCompanyManagementPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CompanyManagementPage()));
  }

  Future<void> _openPermissionManagementPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PermissionManagementPage()),
    );
  }

  Future<void> _openUserManagementPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserManagementPage(currentUserRole: _loggedUserRole ?? ''),
      ),
    );
  }

  Future<void> _openProfessionalManagementPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfessionalManagementPage()),
    );
  }

  Future<void> _openClientManagementPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ClientManagementPage(currentUserRole: _loggedUserRole ?? ''),
      ),
    );
  }

  Future<void> _openServiceOfferingManagementPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceOfferingManagementPage(
          currentUserRole: _loggedUserRole ?? '',
        ),
      ),
    );
  }

  Future<void> _openAvailabilityManagementPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AvailabilityManagementPage(currentUserRole: _loggedUserRole ?? ''),
      ),
    );
  }

  Future<void> _openAppointmentManagementPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AppointmentManagementPage(currentUserRole: _loggedUserRole ?? ''),
      ),
    );
  }

  Future<void> _openProductManagementPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProductManagementPage(currentUserRole: _loggedUserRole ?? ''),
      ),
    );
  }

  void _openLoginModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: LoginPage(
            onLoginSuccess: (result) {
              // AuthSession.sessionChanged (fired by LoginPage._submit via
              // AuthSession.login) drives _onSessionChanged, which
              // repopulates this header everywhere it's mounted.
              Navigator.of(dialogContext).pop();
            },
            onRegisterTap: () {
              Navigator.of(dialogContext).pop();
              _openRegisterModal(context);
            },
          ),
        );
      },
    );
  }

  void _openRegisterModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: RegisterPage(
            onLoginTap: () {
              Navigator.of(dialogContext).pop();

              _openLoginModal(context);
            },

            onRegisterSuccess: () {
              Navigator.of(dialogContext).pop();

              _openLoginModal(context);
            },

            onExternalAuthSuccess: (result) {
              Navigator.of(dialogContext).pop();
            },
          ),
        );
      },
    );
  }

  Widget _buildAdminMenu(BuildContext context) {
    if (!_canSeeAdminMenu) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'Admin',
      offset: const Offset(0, 36),
      onSelected: (value) {
        if (value == 'companies') {
          _openCompanyManagementPage();
          return;
        }

        if (value == 'permissions') {
          _openPermissionManagementPage();
          return;
        }

        if (value == 'users') {
          _openUserManagementPage();
          return;
        }

        if (value == 'professionals') {
          _openProfessionalManagementPage();
          return;
        }

        if (value == 'clients') {
          _openClientManagementPage();
          return;
        }

        if (value == 'services') {
          _openServiceOfferingManagementPage();
          return;
        }

        if (value == 'availability') {
          _openAvailabilityManagementPage();
          return;
        }

        if (value == 'appointment') {
          _openAppointmentManagementPage();
          return;
        }

        if (value == 'products') {
          _openProductManagementPage();
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidade ainda nao implementada'),
          ),
        );
      },
      itemBuilder: (context) {
        return [
          if (_isMasterAdmin) ...[
            const PopupMenuItem<String>(
              value: 'companies',
              child: Text('Empresas'),
            ),
            const PopupMenuDivider(),
          ],
          // Permissoes e por empresa: so o COMPANY_ADMIN da propria empresa
          // gerencia -- MASTER_ADMIN ja tem bypass total em tudo.
          if (_isCompanyAdmin)
            const PopupMenuItem<String>(
              value: 'permissions',
              child: Text('Permissoes'),
            ),
          if (UserPermissions.can(SystemModule.user, CrudAction.list))
            const PopupMenuItem<String>(
              value: 'users',
              child: Text('Usuarios'),
            ),
          if (UserPermissions.can(SystemModule.product, CrudAction.list))
            const PopupMenuItem<String>(
              value: 'products',
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('Produtos'),
                ],
              ),
            ),
          if (UserPermissions.can(SystemModule.professional, CrudAction.list))
            const PopupMenuItem<String>(
              value: 'professionals',
              child: Text('Profissionais'),
            ),
          if (UserPermissions.can(SystemModule.client, CrudAction.list))
            const PopupMenuItem<String>(
              value: 'clients',
              child: Text('Clientes'),
            ),
          if (UserPermissions.can(SystemModule.appointment, CrudAction.list))
            const PopupMenuItem<String>(
              value: 'appointment',
              child: Text('Agendamentos'),
            ),
          if (UserPermissions.can(SystemModule.availability, CrudAction.list))
            const PopupMenuItem<String>(
              value: 'availability',
              child: Text('Disponibilidade'),
            ),
          if (UserPermissions.can(SystemModule.serviceOffering, CrudAction.list))
            const PopupMenuItem<String>(
              value: 'services',
              child: Text('Servicos'),
            ),
        ];
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Text(
              'ADMIN',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 86,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'softix',
        style: TextStyle(
          color: isDark ? Colors.black : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String label,
    required bool selected,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colorScheme.primary : colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final menuBackgroundColor = isDark
        ? const Color(0xFF17191E)
        : colorScheme.surface;

    final menuBorderColor = isDark
        ? const Color(0xFF2C313A)
        : colorScheme.outline.withOpacity(0.35);

    final textColor = colorScheme.onSurface;
    final mutedColor = colorScheme.onSurface.withOpacity(0.65);
    final selectedColor = colorScheme.primary;

    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale;

    final selectedLanguage = _languageOptions.firstWhere(
      (option) =>
          option.locale.languageCode == currentLocale.languageCode &&
          option.locale.countryCode == currentLocale.countryCode,
      orElse: () => _languageOptions.first,
    );

    return PopupMenuButton<_LanguageOption>(
      tooltip: l10n.selectLanguage,
      color: menuBackgroundColor,
      elevation: 8,
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: menuBorderColor, width: 1),
      ),
      onSelected: (_LanguageOption option) {
        final localeProvider = Provider.of<LocaleProvider>(
          context,
          listen: false,
        );

        localeProvider.setLocale(option.locale);
      },
      itemBuilder: (context) {
        return _languageOptions.map((option) {
          final isSelected =
              option.locale.languageCode ==
                  selectedLanguage.locale.languageCode &&
              option.locale.countryCode == selectedLanguage.locale.countryCode;

          return PopupMenuItem<_LanguageOption>(
            value: option,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: selectedColor, width: 1.5)
                    : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CountryFlag.fromCountryCode(
                    option.countryCode,
                    theme: const ImageTheme(
                      width: 24,
                      height: 18,
                      shape: RoundedRectangle(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option.fullLabel,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_outline,
                      color: selectedColor,
                      size: 18,
                    ),
                ],
              ),
            ),
          );
        }).toList();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            CountryFlag.fromCountryCode(
              selectedLanguage.countryCode,
              theme: const ImageTheme(
                width: 24,
                height: 18,
                shape: RoundedRectangle(4),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              selectedLanguage.shortLabel,
              style: TextStyle(
                color:
                    theme.appBarTheme.foregroundColor ?? colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, color: mutedColor, size: 16),
          ],
        ),
      ),
    );
  }

  String _getLogoutLabel(BuildContext context) {
    return AppLocalizations.of(context).logout;
  }

  Widget _buildUserButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final label = _isLoggedIn ? _loggedUserFirstName! : l10n.signIn;

    final buttonContent = Padding(
      padding: const EdgeInsets.only(right: 12, left: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.person_outline,
              color: colorScheme.onSurface,
              size: 20,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.appBarTheme.foregroundColor ?? colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (!_isLoggedIn) {
      return InkWell(
        onTap: () {
          _openLoginModal(context);
        },
        borderRadius: BorderRadius.circular(999),
        child: buttonContent,
      );
    }

    return PopupMenuButton<String>(
      tooltip: label,
      offset: const Offset(0, 42),
      onSelected: (value) {
        if (value == 'profile') {
          _openProfilePage();
          return;
        }

        if (value == 'logout') {
          _logout();
          return;
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem<String>(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 18),
                SizedBox(width: 8),
                Text('Perfil'),
              ],
            ),
          ),

          const PopupMenuDivider(),

          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                const Icon(Icons.logout, size: 18),
                const SizedBox(width: 8),
                Text(_getLogoutLabel(context)),
              ],
            ),
          ),
        ];
      },
      child: buttonContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 62,
      titleSpacing: 28,
      title: Row(
        children: [
          _buildLogo(context),
          const SizedBox(width: 26),
          _buildNavItem(
            context,
            label: AppLocalizations.of(context).navHome,
            selected: widget.currentRoute == AppHeaderRoute.home,
            onTap: _goToHome,
          ),
          _buildNavItem(
            context,
            label: AppLocalizations.of(context).navMyAppointments,
            selected: widget.currentRoute == AppHeaderRoute.myAppointments,
            onTap: _openMyAppointmentsPage,
          ),
          if (_canSeeAdminMenu) _buildAdminMenu(context),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.brightness_6),
          onPressed: () {
            final themeNotifier = Provider.of<ThemeNotifier>(
              context,
              listen: false,
            );
            themeNotifier.toggleTheme();
          },
        ),
        _buildLanguageSelector(context),
        _buildUserButton(context),
      ],
    );
  }
}
