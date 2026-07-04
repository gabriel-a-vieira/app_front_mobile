import 'package:app_front_mobile/pages/client_form_page.dart';
import 'package:app_front_mobile/services/client_service.dart';
import 'package:app_front_mobile/services/company_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/input_formatters.dart';
import 'package:app_front_mobile/widgets/company_zoom_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClientManagementPage extends StatefulWidget {
  final String currentUserRole;

  const ClientManagementPage({
    super.key,
    required this.currentUserRole,
  });

  bool get isMasterAdmin {
    return currentUserRole.toUpperCase() == 'MASTER_ADMIN';
  }

  @override
  State<ClientManagementPage> createState() => _ClientManagementPageState();
}

class _ClientManagementPageState extends State<ClientManagementPage> {
  final _clientService = ClientService(
    baseUrl: 'http://localhost:8081/client',
  );

  final _companyService = CompanyService(
    baseUrl: 'http://localhost:8081/company',
  );

  final _tokenStorage = TokenStorage();
  final _searchController = TextEditingController();

  final Set<String> _selectedIds = {};

  List<ClientSummary> _clients = [];
  List<String> _paymentMethods = [];

  ClientSearchFilters _filters = const ClientSearchFilters();
  CompanySummary? _filterCompany;

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

      final paymentMethods = await _clientService.findPaymentMethods(
        token: token,
      );

      final result = await _clientService.findAll(
        token: token,
        page: 0,
        size: _size,
        filters: _filters.copyWith(
          search: _searchController.text.trim(),
        ),
      );

      if (!mounted) return;

      setState(() {
        _paymentMethods = paymentMethods;
        _clients = result.content;
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

  Future<void> _loadClients() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _last = true;
      _selectedIds.clear();
    });

    try {
      final token = await _getToken();

      final result = await _clientService.findAll(
        token: token,
        page: 0,
        size: _size,
        filters: _filters.copyWith(
          search: _searchController.text.trim(),
        ),
      );

      if (!mounted) return;

      setState(() {
        _clients = result.content;
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

  Future<void> _loadMoreClients() async {
    if (_loadingMore || _last) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      final token = await _getToken();

      final result = await _clientService.findAll(
        token: token,
        page: _page + 1,
        size: _size,
        filters: _filters.copyWith(
          search: _searchController.text.trim(),
        ),
      );

      if (!mounted) return;

      setState(() {
        _clients.addAll(result.content);
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
        builder: (_) => ClientFormPage(
          currentUserRole: widget.currentUserRole,
        ),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await _loadClients();
    }
  }

  Future<void> _openEditPage() async {
    if (_selectedIds.isEmpty) {
      _showMessage('Selecione um cliente para editar');
      return;
    }

    if (_selectedIds.length > 1) {
      _showMessage('Selecione apenas um cliente para editar');
      return;
    }

    final clientId = _selectedIds.first;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClientFormPage(
          clientId: clientId,
          currentUserRole: widget.currentUserRole,
        ),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _loadClients();
    }
  }

  Future<void> _deleteSelectedClients() async {
    if (_selectedIds.isEmpty) {
      _showMessage('Selecione um ou mais clientes para excluir');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF171A22) : null,
          title: const Text('Excluir clientes'),
          content: Text(
            _selectedIds.length == 1
                ? 'Deseja realmente excluir o cliente selecionado?'
                : 'Deseja realmente excluir os clientes selecionados?',
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

    if (confirmed != true) return;

    try {
      final token = await _getToken();

      await _clientService.deleteClients(
        token: token,
        ids: _selectedIds.toList(),
      );

      if (!mounted) return;

      _showMessage('Cliente excluido com sucesso');
      await _loadClients();
    } catch (e) {
      if (!mounted) return;

      _showMessage('Erro ao excluir cliente: $e');
    }
  }

  Future<void> _openAdvancedSearchModal() async {
    final nameController = TextEditingController(text: _filters.name);
    final cpfController = TextEditingController(text: _filters.cpfCnpj);
    final phoneController = TextEditingController(text: _filters.phone);
    final cityController = TextEditingController(text: _filters.city);
    final stateController = TextEditingController(text: _filters.state);
    final companyController = TextEditingController(
      text: _filterCompany != null ? _companyDisplayName(_filterCompany!) : '',
    );

    String selectedStatus = _filters.status;
    String selectedPaymentMethod = _filters.preferredPaymentMethod;
    CompanySummary? selectedCompany = _filterCompany;

    final result = await showDialog<_ClientFilterResult>(
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
                          controller: companyController,
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
                                        companyController.clear();
                                      });
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                                IconButton(
                                  onPressed: () async {
                                    final company = await CompanyZoomModal.show(
                                      context: context,
                                      companyService: _companyService,
                                    );

                                    if (company == null) return;

                                    setModalState(() {
                                      selectedCompany = company;
                                      companyController.text =
                                          _companyDisplayName(company);
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
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cpfController,
                        decoration: const InputDecoration(
                          labelText: 'CPF/CNPJ',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cityController,
                        decoration: const InputDecoration(
                          labelText: 'Cidade',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: stateController,
                        decoration: const InputDecoration(
                          labelText: 'UF',
                          hintText: 'SC',
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(2),
                          _UpperCaseInputFormatter(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'ALL',
                            child: Text('Todos'),
                          ),
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
                          if (value == null) return;

                          setModalState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedPaymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Forma de pagamento',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Todos'),
                          ),
                          ..._paymentMethods.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(_formatOption(method)),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            selectedPaymentMethod = value ?? '';
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
                    Navigator.of(context).pop(
                      const _ClientFilterResult(
                        filters: ClientSearchFilters(),
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
                      _ClientFilterResult(
                        filters: ClientSearchFilters(
                          search: _searchController.text.trim(),
                          name: nameController.text.trim(),
                          cpfCnpj: onlyNumbers(cpfController.text),
                          phone: onlyNumbers(phoneController.text),
                          city: cityController.text.trim(),
                          state: stateController.text.trim().toUpperCase(),
                          status: selectedStatus,
                          preferredPaymentMethod: selectedPaymentMethod,
                          companyId: selectedCompany?.id ?? '',
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

    nameController.dispose();
    cpfController.dispose();
    phoneController.dispose();
    cityController.dispose();
    stateController.dispose();
    companyController.dispose();

    if (result == null) return;

    setState(() {
      _filters = result.filters;
      _filterCompany = result.company;
      _page = 0;
    });

    await _loadClients();
  }

  String _companyDisplayName(CompanySummary company) {
    if (company.tradeName.isNotEmpty) {
      return company.tradeName;
    }

    if (company.legalName.isNotEmpty) {
      return company.legalName;
    }

    return 'Empresa sem nome';
  }

  String _formatOption(String value) {
    return switch (value.toUpperCase()) {
      'ACTIVE' => 'Ativo',
      'INACTIVE' => 'Inativo',
      'PIX' => 'PIX',
      'CASH' => 'Dinheiro',
      'CREDIT_CARD' => 'Cartao de credito',
      'DEBIT_CARD' => 'Cartao de debito',
      'MASCULINO' => 'Masculino',
      'FEMININO' => 'Feminino',
      'OUTRO' => 'Outro',
      _ => value.replaceAll('_', ' '),
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor:
          isDark ? const Color(0xFF1C212B) : colorScheme.surfaceContainerHighest,
      prefixIcon: Icon(
        Icons.search,
        color: colorScheme.onSurface.withOpacity(0.65),
      ),
      suffixIcon: IconButton(
        onPressed: _loadClients,
        icon: const Icon(Icons.arrow_forward),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.outline.withOpacity(0.25),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.primary,
        ),
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
        icon: Icon(
          icon,
          size: 18,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: danger ? colorScheme.error : colorScheme.primary,
          foregroundColor: danger ? colorScheme.onError : colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
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
        icon: Icon(
          hasFilters ? Icons.filter_alt : Icons.tune,
          size: 18,
        ),
        label: Text(
          hasFilters ? 'Filtros aplicados' : 'Filtros',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: hasFilters ? colorScheme.primary : null,
          side: BorderSide(
            color: hasFilters
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.4),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
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
                'Clientes',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gerencie os clientes cadastrados no sistema',
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
              onPressed: _deleteSelectedClients,
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
      onSubmitted: (_) => _loadClients(),
      decoration: _inputDecoration(
        hint: 'Buscar por nome, CPF/CNPJ, telefone, cidade ou UF',
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                'Erro ao buscar clientes',
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadClients,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildClientsGrid(),
        if (!_last) ...[
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              onPressed: _loadingMore ? null : _loadMoreClients,
              child: _loadingMore
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Carregar mais'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClientsGrid() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11141B) : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.22),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            _buildGridHeader(),
            if (_clients.isEmpty)
              _buildEmptyGridState()
            else
              ..._clients.map(_buildGridRow),
          ],
        ),
      ),
    );
  }

  Widget _buildGridHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allSelected = _clients.isNotEmpty && _selectedIds.length == _clients.length;
    final partiallySelected =
        _selectedIds.isNotEmpty && _selectedIds.length < _clients.length;

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF171A22)
            : colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.18),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Checkbox(
              tristate: true,
              value: partiallySelected ? null : allSelected,
              onChanged: _clients.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds
                            ..clear()
                            ..addAll(_clients.map((item) => item.id));
                        } else {
                          _selectedIds.clear();
                        }
                      });
                    },
            ),
          ),
          _buildHeaderCell('Nome', flex: 3),
          _buildHeaderCell('CPF/CNPJ', flex: 2),
          _buildHeaderCell('Telefone', flex: 2),
          _buildHeaderCell('Cidade', flex: 2),
          _buildHeaderCell('UF', flex: 1),
          _buildHeaderCell('Pagamento', flex: 2),
          _buildHeaderCell('Status', flex: 2),
        ],
      ),
    );
  }

  Widget _buildGridRow(ClientSummary client) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _selectedIds.contains(client.id);

    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedIds.remove(client.id);
          } else {
            _selectedIds.add(client.id);
          }
        });
      },
      child: Container(
        minHeight: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary.withOpacity(0.08) : null,
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withOpacity(0.12),
            ),
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
                      _selectedIds.add(client.id);
                    } else {
                      _selectedIds.remove(client.id);
                    }
                  });
                },
              ),
            ),
            _buildBodyCell(client.name, flex: 3),
            _buildBodyCell(client.cpfCnpj, flex: 2),
            _buildBodyCell(client.phone, flex: 2),
            _buildBodyCell(client.city, flex: 2),
            _buildBodyCell(client.state, flex: 1),
            _buildBodyCell(
              client.preferredPaymentMethod.isEmpty
                  ? '-'
                  : _formatOption(client.preferredPaymentMethod),
              flex: 2,
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(
                  status: client.status,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(
    String text, {
    required int flex,
  }) {
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

  Widget _buildBodyCell(
    String value, {
    required int flex,
  }) {
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
            Icons.people_outline,
            color: colorScheme.onSurface.withOpacity(0.45),
            size: 52,
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhum cliente encontrado',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cadastre um novo cliente ou ajuste os filtros',
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
      appBar: AppBar(
        title: const Text('Administracao de clientes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1180,
            ),
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

class _ClientFilterResult {
  final ClientSearchFilters filters;
  final CompanySummary? company;

  const _ClientFilterResult({
    required this.filters,
    this.company,
  });
}

class _UpperCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upperText = newValue.text.toUpperCase();

    return TextEditingValue(
      text: upperText,
      selection: TextSelection.collapsed(
        offset: upperText.length,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final active = normalized == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF1E8F59).withOpacity(0.16)
            : Theme.of(context).colorScheme.error.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Ativo' : 'Inativo',
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