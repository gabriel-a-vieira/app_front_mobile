import 'package:app_front_mobile/pages/service_offering_form_page.dart';
import 'package:app_front_mobile/services/company_lookup_service.dart';
import 'package:app_front_mobile/services/service_offering_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/widgets/company_lookup_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ServiceOfferingManagementPage extends StatefulWidget {
  final String currentUserRole;

  const ServiceOfferingManagementPage({
    super.key,
    required this.currentUserRole,
  });

  bool get isMasterAdmin {
    return currentUserRole.toUpperCase() == 'MASTER_ADMIN';
  }

  @override
  State<ServiceOfferingManagementPage> createState() =>
      _ServiceOfferingManagementPageState();
}

class _ServiceOfferingManagementPageState
    extends State<ServiceOfferingManagementPage> {
  final _serviceOfferingService = ServiceOfferingService(
    baseUrl: 'http://localhost:8081/service-offering',
  );

  final _companyLookupService = CompanyLookupService(
    baseUrl: 'http://localhost:8081/company/companies/home-page',
  );

  final _tokenStorage = TokenStorage();

  final _searchController = TextEditingController();

  final Set<String> _selectedIds = {};

  List<ServiceOfferingSummary> _services = [];

  ServiceOfferingSearchFilters _filters = const ServiceOfferingSearchFilters();

  CompanyLookupOption? _filterCompany;

  bool _loading = true;
  bool _loadingMore = false;

  String? _error;

  int _page = 0;

  final int _size = 10;

  bool _last = true;

  @override
  void initState() {
    super.initState();

    _loadServices();
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

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;

      _error = null;

      _page = 0;

      _last = true;

      _selectedIds.clear();
    });

    try {
      final token = await _getToken();

      final result = await _serviceOfferingService.findAll(
        token: token,

        page: 0,

        size: _size,

        filters: _filters.copyWith(search: _searchController.text.trim()),
      );

      if (!mounted) return;

      setState(() {
        _services = result.content;

        _page = result.number;

        _last = result.last;

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

  Future<void> _loadMoreServices() async {
    if (_loadingMore || _last) {
      return;
    }

    setState(() {
      _loadingMore = true;
    });

    try {
      final token = await _getToken();

      final result = await _serviceOfferingService.findAll(
        token: token,

        page: _page + 1,

        size: _size,

        filters: _filters.copyWith(search: _searchController.text.trim()),
      );

      if (!mounted) return;

      setState(() {
        _services.addAll(result.content);

        _page = result.number;

        _last = result.last;

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

  Future<void> _openCreatePage() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ServiceOfferingFormPage(currentUserRole: widget.currentUserRole),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await _loadServices();
    }
  }

  Future<void> _openEditPage() async {
    if (_selectedIds.isEmpty) {
      _showMessage('Selecione um servico para editar');

      return;
    }

    if (_selectedIds.length > 1) {
      _showMessage('Selecione apenas um servico para editar');

      return;
    }

    final serviceId = _selectedIds.first;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ServiceOfferingFormPage(
          serviceId: serviceId,

          currentUserRole: widget.currentUserRole,
        ),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _loadServices();
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) {
      _showMessage('Selecione um ou mais servicos');

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;

        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF171A22) : null,

          title: const Text('Excluir servicos'),

          content: Text(
            _selectedIds.length == 1
                ? 'Deseja realmente excluir o servico selecionado?'
                : 'Deseja realmente excluir os servicos selecionados?',
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

              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final token = await _getToken();

      await _serviceOfferingService.deleteServices(
        token: token,
        ids: _selectedIds.toList(),
      );

      if (!mounted) return;

      _showMessage(
        _selectedIds.length == 1
            ? 'Servico excluido com sucesso'
            : 'Servicos excluidos com sucesso',
      );

      await _loadServices();
    } catch (e) {
      if (!mounted) return;

      _showMessage('Erro ao excluir servico: $e');
    }
  }

  Future<void> _openFilters() async {
    final minDurationCtrl = TextEditingController(
      text: _filters.minDuration?.toString() ?? '',
    );

    final maxDurationCtrl = TextEditingController(
      text: _filters.maxDuration?.toString() ?? '',
    );

    final minPriceCtrl = TextEditingController(
      text: _filters.minPrice?.toStringAsFixed(2) ?? '',
    );

    final maxPriceCtrl = TextEditingController(
      text: _filters.maxPrice?.toStringAsFixed(2) ?? '',
    );

    final companyCtrl = TextEditingController(
      text: _filterCompany?.displayName ?? '',
    );

    String selectedStatus = _filters.status;

    CompanyLookupOption? selectedCompany = _filterCompany;

    final result = await showDialog<_ServiceOfferingFilterResult>(
      context: context,

      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF171A22) : null,

              title: const Text('Pesquisa avancada'),

              content: SizedBox(
                width: 560,

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      if (widget.isMasterAdmin) ...[
                        TextField(
                          controller: companyCtrl,

                          readOnly: true,

                          decoration: InputDecoration(
                            labelText: 'Empresa',

                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,

                              children: [
                                if (selectedCompany != null)
                                  IconButton(
                                    onPressed: () {
                                      setModalState(() {
                                        selectedCompany = null;

                                        companyCtrl.clear();
                                      });
                                    },

                                    icon: const Icon(Icons.close),
                                  ),

                                IconButton(
                                  onPressed: () async {
                                    final token = await _getToken();

                                    if (!context.mounted) {
                                      return;
                                    }

                                    final company =
                                        await CompanyLookupModal.show(
                                          context: context,

                                          token: token,

                                          service: _companyLookupService,
                                        );

                                    if (company == null) {
                                      return;
                                    }

                                    setModalState(() {
                                      selectedCompany = company;

                                      companyCtrl.text = company.displayName;
                                    });
                                  },

                                  icon: const Icon(Icons.search),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],

                      DropdownButtonFormField<String>(
                        value: selectedStatus,

                        decoration: const InputDecoration(labelText: 'Status'),

                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('Todos')),

                          DropdownMenuItem(
                            value: 'ACTIVE',

                            child: Text('Ativos'),
                          ),

                          DropdownMenuItem(
                            value: 'INACTIVE',

                            child: Text('Inativos'),
                          ),
                        ],

                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setModalState(() {
                            selectedStatus = value;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: minDurationCtrl,

                        keyboardType: TextInputType.number,

                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],

                        decoration: const InputDecoration(
                          labelText: 'Duracao minima',
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: maxDurationCtrl,

                        keyboardType: TextInputType.number,

                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],

                        decoration: const InputDecoration(
                          labelText: 'Duracao maxima',
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: minPriceCtrl,

                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),

                        decoration: const InputDecoration(
                          labelText: 'Preco minimo',
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: maxPriceCtrl,

                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),

                        decoration: const InputDecoration(
                          labelText: 'Preco maximo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      const _ServiceOfferingFilterResult(
                        filters: ServiceOfferingSearchFilters(),
                      ),
                    );
                  },

                  child: const Text('Limpar'),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },

                  child: const Text('Cancelar'),
                ),

                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      _ServiceOfferingFilterResult(
                        filters: ServiceOfferingSearchFilters(
                          search: _searchController.text.trim(),

                          status: selectedStatus,

                          companyId: selectedCompany?.id ?? '',

                          minDuration: _parseInt(minDurationCtrl.text),

                          maxDuration: _parseInt(maxDurationCtrl.text),

                          minPrice: _parseDouble(minPriceCtrl.text),

                          maxPrice: _parseDouble(maxPriceCtrl.text),
                        ),

                        company: selectedCompany,
                      ),
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

    minDurationCtrl.dispose();
    maxDurationCtrl.dispose();
    minPriceCtrl.dispose();
    maxPriceCtrl.dispose();
    companyCtrl.dispose();

    if (result == null) {
      return;
    }

    setState(() {
      _filters = result.filters;

      _filterCompany = result.company;
    });

    await _loadServices();
  }

  int? _parseInt(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return int.tryParse(trimmed);
  }

  double? _parseDouble(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  String _formatPrice(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;

    final remainder = minutes % 60;

    if (remainder == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remainder}min';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        onPressed: _openFilters,

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
                'Servicos',

                style: TextStyle(
                  color: colorScheme.onSurface,

                  fontSize: 24,

                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Gerencie os servicos oferecidos pelas empresas',

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
              label: 'Excluir',
              icon: Icons.delete_outline,
              danger: true,
              onPressed: _deleteSelected,
            ),

            _buildFilterButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildSearch() {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: _searchController,

      onSubmitted: (_) => _loadServices(),

      decoration: InputDecoration(
        hintText: 'Buscar por nome ou descricao',

        prefixIcon: Icon(
          Icons.search,

          color: colorScheme.onSurface.withOpacity(0.65),
        ),

        suffixIcon: IconButton(
          onPressed: _loadServices,

          icon: const Icon(Icons.arrow_forward),
        ),

        filled: true,

        fillColor: isDark
            ? const Color(0xFF1C212B)
            : colorScheme.surfaceContainerHighest,

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),

          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.25)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),

          borderSide: BorderSide(color: colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_services.isEmpty) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(vertical: 64),

        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF11141B) : colorScheme.surface,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(color: colorScheme.outline.withOpacity(0.22)),
        ),

        child: Column(
          children: [
            Icon(
              Icons.design_services_outlined,

              size: 52,

              color: colorScheme.onSurface.withOpacity(0.45),
            ),

            const SizedBox(height: 14),

            const Text(
              'Nenhum servico encontrado',

              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11141B) : colorScheme.surface,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: colorScheme.outline.withOpacity(0.22)),
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),

        child: Column(
          children: [_buildGridHeader(), ..._services.map(_buildGridRow)],
        ),
      ),
    );
  }

  Widget _buildGridHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allSelected =
        _services.isNotEmpty &&
        _services.every((service) => _selectedIds.contains(service.id));

    return Container(
      height: 54,

      padding: const EdgeInsets.symmetric(horizontal: 14),

      color: isDark
          ? const Color(0xFF171A22)
          : colorScheme.surfaceContainerHighest,

      child: Row(
        children: [
          SizedBox(
            width: 42,

            child: Checkbox(
              value: allSelected,

              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds
                      ..clear()
                      ..addAll(_services.map((service) => service.id));
                  } else {
                    _selectedIds.clear();
                  }
                });
              },
            ),
          ),

          _headerCell('Nome', flex: 3),

          _headerCell('Duracao', flex: 2),

          _headerCell('Preco', flex: 2),

          _headerCell('Status', flex: 2),

          if (widget.isMasterAdmin) _headerCell('Empresa', flex: 3),
        ],
      ),
    );
  }

  Widget _buildGridRow(ServiceOfferingSummary service) {
    final colorScheme = Theme.of(context).colorScheme;

    final selected = _selectedIds.contains(service.id);

    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedIds.remove(service.id);
          } else {
            _selectedIds.add(service.id);
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
                      _selectedIds.add(service.id);
                    } else {
                      _selectedIds.remove(service.id);
                    }
                  });
                },
              ),
            ),

            _bodyCell(service.name, flex: 3),

            _bodyCell(_formatDuration(service.durationMinutes), flex: 2),

            _bodyCell(_formatPrice(service.price), flex: 2),

            Expanded(
              flex: 2,

              child: Align(
                alignment: Alignment.centerLeft,

                child: _StatusBadge(status: service.status),
              ),
            ),

            if (widget.isMasterAdmin) _bodyCell(service.companyId, flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,

      child: Text(
        text,

        overflow: TextOverflow.ellipsis,

        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _bodyCell(String value, {required int flex}) {
    return Expanded(
      flex: flex,

      child: Text(
        value.isEmpty ? '-' : value,

        overflow: TextOverflow.ellipsis,

        maxLines: 1,

        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildContent() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 42),

            const SizedBox(height: 12),

            Text(
              'Erro ao buscar servicos',

              style: TextStyle(
                color: colorScheme.error,

                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: _loadServices,

              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildGrid(),

        if (!_last) ...[
          const SizedBox(height: 20),

          OutlinedButton(
            onPressed: _loadingMore ? null : _loadMoreServices,

            child: _loadingMore
                ? const SizedBox(
                    width: 18,
                    height: 18,

                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Carregar mais'),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administracao de servicos')),

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

class _ServiceOfferingFilterResult {
  final ServiceOfferingSearchFilters filters;

  final CompanyLookupOption? company;

  const _ServiceOfferingFilterResult({required this.filters, this.company});
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status.toUpperCase() == 'ACTIVE';

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF1E8F59).withOpacity(0.16)
            : colorScheme.error.withOpacity(0.14),

        borderRadius: BorderRadius.circular(999),
      ),

      child: Text(
        active ? 'Ativo' : 'Inativo',

        style: TextStyle(
          color: active ? const Color(0xFF2EC27E) : colorScheme.error,

          fontSize: 12,

          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
