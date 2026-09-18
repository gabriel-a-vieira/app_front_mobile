import 'package:app_front_mobile/pages/company_form_page.dart';
import 'package:app_front_mobile/services/company_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/theme/app_colors.dart';
import 'package:app_front_mobile/utils/api_error_handler.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/widgets/common/async_list_section.dart';
import 'package:flutter/material.dart';
import 'package:app_front_mobile/config/api_config.dart';

class CompanyManagementPage extends StatefulWidget {
  const CompanyManagementPage({super.key});

  @override
  State<CompanyManagementPage> createState() => _CompanyManagementPageState();
}

class _CompanyManagementPageState extends State<CompanyManagementPage> {
  final _service = CompanyService(baseUrl: '${ApiConfig.baseUrl}/company');

  final _tokenStorage = TokenStorage();
  final _searchController = TextEditingController();

  final Set<String> _selectedIds = {};

  List<CompanyAdminSummary> _companies = [];
  List<CompanyTypeOption> _types = [];

  _CompanyFilters _filters = const _CompanyFilters();

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  int _page = 0;
  final int _size = 10;
  bool _last = true;

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

  Future<String> _getToken() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _getToken();

      final types = await _service.findCompanyTypes();

      final result = await _service.findAdminCompanies(
        token: token,
        page: 0,
        size: _size,
        search: _searchController.text.trim(),
        type: _filters.type,
        status: _filters.status,
      );

      if (!mounted) return;

      setState(() {
        _types = types;
        _companies = result.content;
        _page = result.number;
        _last = result.last;
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

  Future<void> _loadCompanies() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _last = true;
      _selectedIds.clear();
    });

    try {
      final token = await _getToken();

      final result = await _service.findAdminCompanies(
        token: token,
        page: 0,
        size: _size,
        search: _searchController.text.trim(),
        type: _filters.type,
        status: _filters.status,
      );

      if (!mounted) return;

      setState(() {
        _companies = result.content;
        _page = result.number;
        _last = result.last;
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
      final token = await _getToken();

      final result = await _service.findAdminCompanies(
        token: token,
        page: _page + 1,
        size: _size,
        search: _searchController.text.trim(),
        type: _filters.type,
        status: _filters.status,
      );

      if (!mounted) return;

      setState(() {
        _companies.addAll(result.content);
        _page = result.number;
        _last = result.last;
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

  Future<void> _openCreatePage() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CompanyFormPage()));

    if (!mounted) return;

    if (created == true) {
      await _loadCompanies();
    }
  }

  Future<void> _openEditPage() async {
    if (_selectedIds.isEmpty) {
      AppMessage.info(context, 'Selecione uma empresa para editar');
      return;
    }

    if (_selectedIds.length > 1) {
      AppMessage.info(context, 'Selecione apenas uma empresa para editar');
      return;
    }

    final companyId = _selectedIds.first;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CompanyFormPage(companyId: companyId)),
    );

    if (!mounted) return;

    if (updated == true) {
      await _loadCompanies();
    }
  }

  Future<void> _deactivateSelected() async {
    if (_selectedIds.isEmpty) {
      AppMessage.info(context, 'Selecione uma ou mais empresas para inativar');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurfaceElevated : null,
          title: const Text('Inativar empresas'),
          content: Text(
            _selectedIds.length == 1
                ? 'Deseja realmente inativar a empresa selecionada?'
                : 'Deseja realmente inativar as empresas selecionadas?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Inativar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final token = await _getToken();

      await _service.deactivateCompanies(
        token: token,
        ids: _selectedIds.toList(),
      );

      if (!mounted) return;

      AppMessage.success(context, 'Empresa(s) inativada(s) com sucesso');
      await _loadCompanies();
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(context, e, fallback: 'Erro ao inativar empresa.');
    }
  }

  Future<void> _openAdvancedSearchModal() async {
    String selectedType = _filters.type;
    String selectedStatus = _filters.status;

    final result = await showDialog<_CompanyFilters>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurfaceElevated : null,
              title: const Text('Pesquisa avancada'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Todos')),
                          ..._types.map(
                            (type) => DropdownMenuItem(
                              value: type.code,
                              child: Text(type.label),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            selectedType = value ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Todos')),
                          DropdownMenuItem(value: 'ACTIVE', child: Text('Ativa')),
                          DropdownMenuItem(
                            value: 'INACTIVE',
                            child: Text('Inativa'),
                          ),
                          DropdownMenuItem(
                            value: 'SUSPENDED',
                            child: Text('Suspensa'),
                          ),
                          DropdownMenuItem(
                            value: 'BLOCKED',
                            child: Text('Bloqueada'),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            selectedStatus = value ?? '';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(const _CompanyFilters());
                  },
                  child: const Text('Limpar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      _CompanyFilters(type: selectedType, status: selectedStatus),
                    );
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      _filters = result;
    });

    await _loadCompanies();
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'ACTIVE':
        return 'Ativa';
      case 'INACTIVE':
        return 'Inativa';
      case 'SUSPENDED':
        return 'Suspensa';
      case 'BLOCKED':
        return 'Bloqueada';
      default:
        return value;
    }
  }

  InputDecoration _inputDecoration({required String hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark
          ? AppColors.darkInputFill
          : colorScheme.surfaceContainerHighest,
      prefixIcon: Icon(
        Icons.search,
        color: colorScheme.onSurface.withOpacity(0.65),
      ),
      suffixIcon: IconButton(
        onPressed: _loadCompanies,
        icon: const Icon(Icons.arrow_forward),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool danger = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 42,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: FilledButton.styleFrom(
          backgroundColor: danger ? colorScheme.error : colorScheme.primary,
          foregroundColor: danger ? colorScheme.onError : colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    final colorScheme = Theme.of(context).colorScheme;
    final hasFilters = _filters.hasAdvancedFilters;

    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: _openAdvancedSearchModal,
        icon: Icon(hasFilters ? Icons.filter_alt : Icons.tune, size: 18),
        label: Text(
          hasFilters ? 'Filtros aplicados' : 'Filtros',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: hasFilters ? colorScheme.primary : null,
          side: BorderSide(
            color: hasFilters
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.4),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Empresas',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gerencie as empresas cadastradas na plataforma',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.65),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildActionButton(
              label: 'Inserir',
              icon: Icons.add,
              onPressed: _openCreatePage,
            ),
            _buildActionButton(
              label: 'Editar',
              icon: Icons.edit_outlined,
              onPressed: _openEditPage,
            ),
            _buildActionButton(
              label: 'Inativar',
              icon: Icons.block_outlined,
              danger: true,
              onPressed: _deactivateSelected,
            ),
            _buildFilterButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onSubmitted: (_) => _loadCompanies(),
      decoration: _inputDecoration(hint: 'Buscar por nome ou CNPJ'),
    );
  }

  Widget _buildContent() {
    return AsyncListSection(
      loading: _loading,
      hasError: _error != null,
      errorLabel: 'Erro ao buscar empresas',
      onRetry: _loadCompanies,
      content: _buildCompaniesGrid(),
      hasMore: !_last,
      loadingMore: _loadingMore,
      onLoadMore: _loadMoreCompanies,
    );
  }

  Widget _buildCompaniesGrid() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.22)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            _buildGridHeader(),
            if (_companies.isEmpty)
              _buildEmptyGridState()
            else
              ..._companies.map(_buildGridRow),
          ],
        ),
      ),
    );
  }

  Widget _buildGridHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allSelected =
        _companies.isNotEmpty && _selectedIds.length == _companies.length;
    final partiallySelected =
        _selectedIds.isNotEmpty && _selectedIds.length < _companies.length;

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.18)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Checkbox(
              tristate: true,
              value: partiallySelected ? null : allSelected,
              onChanged: _companies.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds
                            ..clear()
                            ..addAll(_companies.map((item) => item.id));
                        } else {
                          _selectedIds.clear();
                        }
                      });
                    },
            ),
          ),
          _buildHeaderCell('Nome', flex: 3),
          _buildHeaderCell('CNPJ', flex: 2),
          _buildHeaderCell('Tipo', flex: 2),
          _buildHeaderCell('Cidade/UF', flex: 2),
          _buildHeaderCell('Status', flex: 2),
        ],
      ),
    );
  }

  Widget _buildGridRow(CompanyAdminSummary company) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _selectedIds.contains(company.id);

    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedIds.remove(company.id);
          } else {
            _selectedIds.add(company.id);
          }
        });
      },
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary.withOpacity(0.08) : null,
          border: Border(
            bottom: BorderSide(color: colorScheme.outline.withOpacity(0.12)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Checkbox(
                value: selected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedIds.add(company.id);
                    } else {
                      _selectedIds.remove(company.id);
                    }
                  });
                },
              ),
            ),
            _buildBodyCell(
              company.tradeName.isNotEmpty ? company.tradeName : company.legalName,
              flex: 3,
            ),
            _buildBodyCell(company.cnpj, flex: 2),
            _buildBodyCell(company.typeLabel, flex: 2),
            _buildBodyCell(
              [
                company.city,
                company.state,
              ].where((item) => item.isNotEmpty).join('/'),
              flex: 2,
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(
                  active: company.status.toUpperCase() == 'ACTIVE',
                  label: _statusLabel(company.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      flex: flex,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.8),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildBodyCell(String value, {required int flex}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      flex: flex,
      child: Text(
        value.isEmpty ? '-' : value,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyGridState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(
            Icons.storefront_outlined,
            color: colorScheme.onSurface.withOpacity(0.45),
            size: 52,
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhuma empresa encontrada',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cadastre uma nova empresa ou ajuste os filtros',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administracao de empresas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 22),
                _buildSearch(),
                const SizedBox(height: 22),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyFilters {
  final String type;
  final String status;

  const _CompanyFilters({this.type = '', this.status = ''});

  bool get hasAdvancedFilters => type.isNotEmpty || status.isNotEmpty;
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  final String label;

  const _StatusBadge({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF1E8F59).withOpacity(0.16)
            : Theme.of(context).colorScheme.error.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active
              ? const Color(0xFF2EC27E)
              : Theme.of(context).colorScheme.error,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
