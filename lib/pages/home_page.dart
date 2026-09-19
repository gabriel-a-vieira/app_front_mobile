import 'package:app_front_mobile/services/company_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_front_mobile/pages/company_detail_page.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/auth_gate.dart';
import 'package:app_front_mobile/utils/auth_session.dart';
import 'package:app_front_mobile/widgets/app_header.dart';
import 'package:app_front_mobile/widgets/app_scaffold.dart';

import '../l10n/app_localizations.dart';
import '../locale_provider.dart';
import 'package:app_front_mobile/config/api_config.dart';
import 'package:app_front_mobile/utils/api_error_handler.dart';
import 'package:app_front_mobile/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _companyService = CompanyService(
    baseUrl: '${ApiConfig.baseUrl}/company',
  );
  final _searchController = TextEditingController();
  final _tokenStorage = TokenStorage();

  String? _selectedCompanyType;
  bool _favoritesOnly = false;
  bool _isLoggedIn = false;

  List<CompanyTypeOption> _companyTypes = [];
  List<CompanySummary> _companies = [];

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  int _page = 0;
  final int _size = 8;
  bool _last = true;

  @override
  void initState() {
    super.initState();
    AuthSession.sessionChanged.addListener(_onSessionChanged);
    _syncLoginState(reloadCompaniesOnChange: false);
    _loadInitialData();
  }

  @override
  void dispose() {
    AuthSession.sessionChanged.removeListener(_onSessionChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Fires on any login or logout anywhere in the app - AppHeader's own
  // "Entrar" modal, a login prompted by AuthGate.requireLogin from a
  // booking/review/etc. flow, or ApiClient invalidating the token after a
  // 401. Keeps the favorites filter correct without every login entry point
  // having to know it needs to notify this page directly.
  void _onSessionChanged() {
    _syncLoginState(reloadCompaniesOnChange: true);
  }

  Future<void> _syncLoginState({required bool reloadCompaniesOnChange}) async {
    final authenticated = await AuthGate.isAuthenticated();

    if (!mounted) return;

    final changed = _isLoggedIn != authenticated;

    setState(() {
      _isLoggedIn = authenticated;

      if (!authenticated) {
        _favoritesOnly = false;
      }
    });

    if (changed && reloadCompaniesOnChange) {
      await _reloadCompanies();
    }
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
      final token = await _tokenStorage.getAccessToken();

      final companiesPage = await _companyService.findCompanies(
        page: 0,
        size: _size,
        type: _selectedCompanyType,
        search: _searchController.text,
        favoritesOnly: _favoritesOnly,
        token: token,
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
        _error = ApiErrorHandler.getMessage(e);
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
      final token = await _tokenStorage.getAccessToken();

      final companiesPage = await _companyService.findCompanies(
        page: 0,
        size: _size,
        type: _selectedCompanyType,
        search: _searchController.text,
        favoritesOnly: _favoritesOnly,
        token: token,
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
        _error = ApiErrorHandler.getMessage(e);
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
      final token = await _tokenStorage.getAccessToken();

      final companiesPage = await _companyService.findCompanies(
        page: _page + 1,
        size: _size,
        type: _selectedCompanyType,
        search: _searchController.text,
        favoritesOnly: _favoritesOnly,
        token: token,
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
        _error = ApiErrorHandler.getMessage(e);
        _loadingMore = false;
      });
    }
  }

  void _toggleFavoritesOnly() {
    setState(() {
      _favoritesOnly = !_favoritesOnly;
    });

    _reloadCompanies();
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

  Widget _buildSearchInput(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: _searchController,
      onSubmitted: (_) => _reloadCompanies(),
      style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).findABusinessHint,
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
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colorScheme.primary),
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
          label: Text(AppLocalizations.of(context).allCompanyTypes),
          onSelected: (_) {
            setState(() {
              _selectedCompanyType = null;
            });

            _reloadCompanies();
          },
        ),
        if (_isLoggedIn)
          ChoiceChip(
            selected: _favoritesOnly,
            avatar: Icon(
              _favoritesOnly ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: _favoritesOnly ? const Color(0xFFE34B4B) : null,
            ),
            label: Text(AppLocalizations.of(context).favoritesLabel),
            selectedColor: const Color(0xFFE34B4B).withOpacity(0.18),
            onSelected: (_) => _toggleFavoritesOnly(),
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
            AppLocalizations.of(context).errorLoadingBusinesses,
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
              Icon(Icons.location_on, color: colorScheme.error, size: 72),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).noBusinessesFound,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).tryChangingFilter,
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
                  child: _CompanyCard(
                    company: company,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CompanyDetailPage(company: company),
                        ),
                      );
                    },
                  ),
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
                      : Text(AppLocalizations.of(context).loadMore),
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

    return AppScaffold(
      currentRoute: AppHeaderRoute.home,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).welcomeMessage,
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
                  AppLocalizations.of(context).nearbyBusinesses,
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
  final VoidCallback onTap;

  const _CompanyCard({required this.company, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayName = company.tradeName.isNotEmpty
        ? company.tradeName
        : company.legalName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 54,
                  height: 54,
                  color: colorScheme.primary.withOpacity(0.12),
                  child: company.imageUrl.trim().isEmpty
                      ? Icon(
                          Icons.storefront,
                          color: colorScheme.primary,
                          size: 28,
                        )
                      : Image.network(
                          company.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.storefront,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                        ),
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
        ),
      ),
    );
  }
}
