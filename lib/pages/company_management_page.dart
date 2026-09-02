import 'package:app_front_mobile/pages/company_form_page.dart';
import 'package:app_front_mobile/services/company_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:flutter/material.dart';

class CompanyManagementPage extends StatefulWidget {
  const CompanyManagementPage({super.key});

  @override
  State<CompanyManagementPage> createState() => _CompanyManagementPageState();
}

class _CompanyManagementPageState extends State<CompanyManagementPage> {
  final _service = CompanyService(baseUrl: 'http://localhost:8081/company');

  final _tokenStorage = TokenStorage();

  final _searchCtrl = TextEditingController();

  List<CompanyAdminSummary> _companies = [];

  List<CompanyTypeOption> _types = [];

  final Set<String> _selectedIds = {};

  bool _loading = true;

  int _page = 0;
  final int _size = 10;

  int _totalPages = 1;

  bool _first = true;
  bool _last = true;

  String _selectedType = '';
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();

    _loadInitial();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();

    super.dispose();
  }

  Future<String> _token() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  Future<void> _loadInitial() async {
    try {
      _types = await _service.findCompanyTypes();

      await _load(page: 0);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      AppMessage.apiError(context, e, fallback: 'Erro ao carregar empresas.');
    }
  }

  Future<void> _load({required int page}) async {
    setState(() {
      _loading = true;
    });

    try {
      final token = await _token();

      final result = await _service.findAdminCompanies(
        token: token,
        page: page,
        size: _size,
        search: _searchCtrl.text,
        type: _selectedType,
        status: _selectedStatus,
      );

      if (!mounted) return;

      setState(() {
        _companies = result.content;

        _page = result.number;

        _totalPages = result.totalPages;

        _first = result.first;

        _last = result.last;

        _selectedIds.clear();

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      AppMessage.apiError(context, e, fallback: 'Erro ao carregar empresas.');
    }
  }

  Future<void> _openCreate() async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CompanyFormPage()));

    if (result == true && mounted) {
      await _load(page: 0);
    }
  }

  Future<void> _openEdit(String id) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CompanyFormPage(companyId: id)),
    );

    if (result == true && mounted) {
      await _load(page: _page);
    }
  }

  Future<void> _deactivate() async {
    if (_selectedIds.isEmpty) {
      AppMessage.info(context, 'Selecione pelo menos uma empresa.');

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Inativar empresas'),
        content: Text('Deseja inativar ${_selectedIds.length} empresa(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Inativar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final token = await _token();

      await _service.deactivateCompanies(
        token: token,
        ids: _selectedIds.toList(),
      );

      if (!mounted) return;

      AppMessage.success(context, 'Empresa(s) inativada(s) com sucesso.');

      await _load(page: _page);
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(context, e, fallback: 'Erro ao inativar empresa.');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empresas'),
        actions: [
          TextButton.icon(
            onPressed: _openCreate,
            icon: const Icon(Icons.add),
            label: const Text('Nova empresa'),
          ),

          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildFilters(),

            const SizedBox(height: 18),

            Expanded(child: _buildContent()),

            const SizedBox(height: 12),

            _buildPagination(),
          ],
        ),
      ),
      floatingActionButton: _selectedIds.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _deactivate,
              icon: const Icon(Icons.block_outlined),
              label: const Text('Inativar'),
            ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _load(page: 0),
            decoration: InputDecoration(
              labelText: 'Buscar empresa',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () => _load(page: 0),
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Todos')),
              ..._types.map(
                (type) =>
                    DropdownMenuItem(value: type.code, child: Text(type.label)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedType = value ?? '';
              });

              _load(page: 0);
            },
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: '', child: Text('Todos')),
              DropdownMenuItem(value: 'ACTIVE', child: Text('Ativa')),
              DropdownMenuItem(value: 'INACTIVE', child: Text('Inativa')),
              DropdownMenuItem(value: 'SUSPENDED', child: Text('Suspensa')),
              DropdownMenuItem(value: 'BLOCKED', child: Text('Bloqueada')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value ?? '';
              });

              _load(page: 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_companies.isEmpty) {
      return const Center(child: Text('Nenhuma empresa encontrada.'));
    }

    return ListView.separated(
      itemCount: _companies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final company = _companies[index];

        final selected = _selectedIds.contains(company.id);

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Checkbox(
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

                const SizedBox(width: 8),

                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.tradeName.isNotEmpty
                            ? company.tradeName
                            : company.legalName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        company.legalName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                Expanded(flex: 2, child: Text(company.cnpj)),

                Expanded(flex: 2, child: Text(company.typeLabel)),

                Expanded(
                  flex: 2,
                  child: Text(
                    [
                      company.city,
                      company.state,
                    ].where((item) => item.isNotEmpty).join('/'),
                  ),
                ),

                Expanded(flex: 1, child: Text(_statusLabel(company.status))),

                IconButton(
                  tooltip: 'Editar',
                  onPressed: () => _openEdit(company.id),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Pagina ${_page + 1} de $_totalPages'),

        const SizedBox(width: 12),

        IconButton(
          onPressed: _first ? null : () => _load(page: _page - 1),
          icon: const Icon(Icons.chevron_left),
        ),

        IconButton(
          onPressed: _last ? null : () => _load(page: _page + 1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
