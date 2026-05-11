import 'package:app_front_mobile/pages/login_page.dart';
import 'package:app_front_mobile/pages/register_page.dart';
import 'package:app_front_mobile/services/company_service.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../theme_notifier.dart';
import '../locale_provider.dart';

class LanguageOption {
  final Locale locale;
  final String countryCode;
  final String shortLabel;
  final String fullLabel;

  const LanguageOption({
    required this.locale,
    required this.countryCode,
    required this.shortLabel,
    required this.fullLabel,
  });
}

const List<LanguageOption> languageOptions = [
  LanguageOption(
    locale: Locale('pt', 'BR'),
    countryCode: 'BR',
    shortLabel: 'BR',
    fullLabel: 'Portugues - Brasil',
  ),
  LanguageOption(
    locale: Locale('en', 'US'),
    countryCode: 'US',
    shortLabel: 'USA',
    fullLabel: 'English - United States',
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _companyService = CompanyService(baseUrl: 'http://localhost:8081/company');
  final _searchController = TextEditingController();

  String? _loggedUserFirstName;
  String? _selectedCompanyType;

  List<CompanyTypeOption> _companyTypes = [];
  List<CompanySummary> _companies = [];

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  int _page = 0;
  final int _size = 8;
  bool _last = true;

  bool get _isLoggedIn {
    return _loggedUserFirstName != null && _loggedUserFirstName!.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _last = true;
    });

    try {
      final types = await _companyService.findCompanyTypes();

      final companiesPage = await _companyService.findCompanies(
        page: 0,
        size: _size,
        type: _selectedCompanyType,
        search: _searchController.text,
      );

      if (!mounted) return;

      setState(() {
        _companyTypes = types;
        _companies = companiesPage.content;
        _page = companiesPage.number;
        _last = companiesPage.last;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _reloadCompanies() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _last = true;
    });

    try {
      final companiesPage = await _companyService.findCompanies(
        page: 0,
        size: _size,
        type: _selectedCompanyType,
        search: _searchController.text,
      );

      if (!mounted) return;

      setState(() {
        _companies = companiesPage.content;
        _page = companiesPage.number;
        _last = companiesPage.last;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreCompanies() async {
    if (_loadingMore || _last) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      final companiesPage = await _companyService.findCompanies(
        page: _page + 1,
        size: _size,
        type: _selectedCompanyType,
        search: _searchController.text,
      );

      if (!mounted) return;

      setState(() {
        _companies.addAll(companiesPage.content);
        _page = companiesPage.number;
        _last = companiesPage.last;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loadingMore = false;
      });
    }
  }

  String _text(BuildContext context, String pt, String en) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;

    if (locale.languageCode == 'en') {
      return en;
    }

    return pt;
  }

  String _formatDate(BuildContext context) {
    final now = DateTime.now();
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;

    if (locale.languageCode == 'en') {
      final weekDays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${weekDays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
    }

    final weekDays = [
      'Segunda-feira',
      'Terca-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sabado',
      'Domingo',
    ];

    final months = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];

    return '${weekDays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _getLogoutLabel(BuildContext context) {
    return _text(context, 'Sair', 'Logout');
  }

  void _logout() {
    setState(() {
      _loggedUserFirstName = null;
    });
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
              setState(() {
                _loggedUserFirstName = result.firstName;
              });

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
          ),
        );
      },
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
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? colorScheme.primary : colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w700,
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

    final selectedLanguage = languageOptions.firstWhere(
      (option) =>
          option.locale.languageCode == currentLocale.languageCode &&
          option.locale.countryCode == currentLocale.countryCode,
      orElse: () => languageOptions.first,
    );

    return PopupMenuButton<LanguageOption>(
      tooltip: l10n.selectLanguage,
      color: menuBackgroundColor,
      elevation: 8,
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: menuBorderColor,
          width: 1,
        ),
      ),
      onSelected: (LanguageOption option) {
        final localeProvider = Provider.of<LocaleProvider>(
          context,
          listen: false,
        );

        localeProvider.setLocale(option.locale);
      },
      itemBuilder: (context) {
        return languageOptions.map((option) {
          final isSelected =
              option.locale.languageCode ==
                      selectedLanguage.locale.languageCode &&
                  option.locale.countryCode ==
                      selectedLanguage.locale.countryCode;

          return PopupMenuItem<LanguageOption>(
            value: option,
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(
                        color: selectedColor,
                        width: 1.5,
                      )
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
                color: theme.appBarTheme.foregroundColor ??
                    colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              color: mutedColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
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
        if (value == 'logout') {
          _logout();
        }
      },
      itemBuilder: (context) {
        return [
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

  Widget _buildSearchInput(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: _searchController,
      onSubmitted: (_) => _reloadCompanies(),
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: _text(
          context,
          'Encontre um estabelecimento',
          'Find a business',
        ),
        prefixIcon: Icon(
          Icons.search,
          color: colorScheme.onSurface.withOpacity(0.65),
        ),
        suffixIcon: IconButton(
          onPressed: _reloadCompanies,
          icon: const Icon(Icons.arrow_forward),
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF15171D)
            : colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.25),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyTypeFilters(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          selected: _selectedCompanyType == null,
          label: Text(_text(context, 'Todos', 'All')),
          onSelected: (_) {
            setState(() {
              _selectedCompanyType = null;
            });

            _reloadCompanies();
          },
        ),
        ..._companyTypes.map((type) {
          final selected = _selectedCompanyType == type.code;

          return ChoiceChip(
            selected: selected,
            label: Text(type.label),
            selectedColor: colorScheme.primary.withOpacity(0.22),
            onSelected: (_) {
              setState(() {
                _selectedCompanyType = selected ? null : type.code;
              });

              _reloadCompanies();
            },
          );
        }),
      ],
    );
  }

  Widget _buildCompaniesContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Text(
            _text(
              context,
              'Erro ao buscar estabelecimentos.',
              'Error loading businesses.',
            ),
            style: TextStyle(
              color: colorScheme.error,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (_companies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Column(
            children: [
              Icon(
                Icons.location_on,
                color: colorScheme.error,
                size: 72,
              ),
              const SizedBox(height: 16),
              Text(
                _text(
                  context,
                  'Nenhum estabelecimento encontrado',
                  'No businesses found',
                ),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _text(
                  context,
                  'Tente alterar o filtro ou buscar outro nome.',
                  'Try changing the filter or searching another name.',
                ),
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.65),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        final cardWidth = maxWidth >= 1000
            ? (maxWidth - 32) / 3
            : maxWidth >= 700
                ? (maxWidth - 16) / 2
                : maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _companies.map((company) {
                return SizedBox(
                  width: cardWidth,
                  child: _CompanyCard(company: company),
                );
              }).toList(),
            ),
            if (!_last) ...[
              const SizedBox(height: 24),
              Center(
                child: OutlinedButton(
                  onPressed: _loadingMore ? null : _loadMoreCompanies,
                  child: _loadingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_text(context, 'Carregar mais', 'Load more')),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 62,
        titleSpacing: 28,
        title: Row(
          children: [
            _buildLogo(context),
            const SizedBox(width: 26),
            _buildNavItem(
              context,
              label: _text(context, 'Inicio', 'Home'),
              selected: true,
            ),
            _buildNavItem(
              context,
              label: _text(context, 'Buscar', 'Search'),
              selected: false,
            ),
            _buildNavItem(
              context,
              label: _text(context, 'Meus Agendamentos', 'My Appointments'),
              selected: false,
            ),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(context, 'Seja bem vindo(a)', 'Welcome'),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(context),
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSearchInput(context),
                const SizedBox(height: 42),
                Text(
                  _text(context, 'Empresas proximas', 'Nearby businesses'),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCompanyTypeFilters(context),
                const SizedBox(height: 24),
                _buildCompaniesContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final CompanySummary company;

  const _CompanyCard({
    required this.company,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayName = company.tradeName.isNotEmpty
        ? company.tradeName
        : company.legalName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF11141B)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.storefront,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  company.typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.65),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurface.withOpacity(0.55),
          ),
        ],
      ),
    );
  }
}