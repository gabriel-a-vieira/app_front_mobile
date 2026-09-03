import 'package:app_front_mobile/pages/product_form_page.dart';
import 'package:app_front_mobile/services/company_lookup_service.dart';
import 'package:app_front_mobile/services/product_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/widgets/company_lookup_modal.dart';
import 'package:flutter/material.dart';

class ProductManagementPage extends StatefulWidget {
  final String currentUserRole;

  const ProductManagementPage({super.key, required this.currentUserRole});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final _service = ProductService(baseUrl: 'http://localhost:8081/product');

  final _companyLookupService = CompanyLookupService(
    baseUrl: 'http://localhost:8081/company',
  );

  final _tokenStorage = TokenStorage();

  final _searchController = TextEditingController();

  final _minPriceController = TextEditingController();

  final _maxPriceController = TextEditingController();

  List<ProductSummary> _products = [];

  final Set<String> _selectedIds = {};

  bool _loading = true;

  bool _showFilters = false;

  int _page = 0;

  final int _size = 10;

  int _totalPages = 1;

  bool _first = true;

  bool _last = true;

  String _status = '';

  String? _companyId;

  String _companyName = '';

  bool get _isMasterAdmin => widget.currentUserRole == 'MASTER_ADMIN';

  bool get _hasSelection => _selectedIds.isNotEmpty;

  bool get _canEdit => _selectedIds.length == 1;

  bool get _allCurrentPageSelected {
    if (_products.isEmpty) {
      return false;
    }

    return _products.every((product) => _selectedIds.contains(product.id));
  }

  @override
  void initState() {
    super.initState();

    _load(page: 0);
  }

  @override
  void dispose() {
    _searchController.dispose();

    _minPriceController.dispose();

    _maxPriceController.dispose();

    super.dispose();
  }

  Future<String> _token() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  double? _parsePrice(String value) {
    final text = value.trim().replaceAll(',', '.');

    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(text);
  }

  Future<void> _load({required int page}) async {
    setState(() {
      _loading = true;
    });

    try {
      final token = await _token();

      final result = await _service.findAll(
        token: token,
        page: page,
        size: _size,
        search: _searchController.text.trim(),
        status: _status,
        minPrice: _parsePrice(_minPriceController.text),
        maxPrice: _parsePrice(_maxPriceController.text),
        companyId: _isMasterAdmin ? _companyId : null,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _products = result.content;

        _page = result.number;

        _totalPages = result.totalPages;

        _first = result.first;

        _last = result.last;

        _selectedIds.clear();

        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      AppMessage.apiError(context, e, fallback: 'Erro ao carregar produtos.');
    }
  }

  Future<void> _openCreate() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ProductFormPage(currentUserRole: widget.currentUserRole),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await _load(page: 0);
    }
  }

  Future<void> _openEdit() async {
    if (!_canEdit) {
      return;
    }

    final productId = _selectedIds.first;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProductFormPage(
          currentUserRole: widget.currentUserRole,
          productId: productId,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await _load(page: _page);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final quantity = _selectedIds.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir produtos'),
          content: Text(
            quantity == 1
                ? 'Deseja excluir o produto selecionado?'
                : 'Deseja excluir os $quantity produtos selecionados?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
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
      final token = await _token();

      await _service.deleteMany(
        token: token,
        ids: _selectedIds.toList(),
        companyId: _isMasterAdmin ? _companyId : null,
      );

      if (!mounted) {
        return;
      }

      AppMessage.success(
        context,
        quantity == 1
            ? 'Produto excluído com sucesso.'
            : 'Produtos excluídos com sucesso.',
      );

      await _load(page: _page);
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppMessage.apiError(context, e, fallback: 'Erro ao excluir produtos.');
    }
  }

  Future<void> _selectCompanyFilter() async {
    try {
      final token = await _token();

      if (!mounted) {
        return;
      }

      final selected = await CompanyLookupModal.show(
        context: context,
        token: token,
        service: _companyLookupService,
      );

      if (selected == null || !mounted) {
        return;
      }

      setState(() {
        _companyId = selected.id;

        _companyName = selected.displayName;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppMessage.apiError(context, e, fallback: 'Erro ao selecionar empresa.');
    }
  }

  void _clearCompanyFilter() {
    setState(() {
      _companyId = null;

      _companyName = '';
    });
  }

  void _clearFilters() {
    setState(() {
      _status = '';

      _companyId = null;

      _companyName = '';

      _minPriceController.clear();

      _maxPriceController.clear();
    });

    _load(page: 0);
  }

  void _toggleCurrentPageSelection(bool? value) {
    setState(() {
      if (value == true) {
        for (final product in _products) {
          _selectedIds.add(product.id);
        }
      } else {
        for (final product in _products) {
          _selectedIds.remove(product.id);
        }
      }
    });
  }

  String _money(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Ativo';

      case 'INACTIVE':
        return 'Inativo';

      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip: 'Voltar',
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.arrow_back),
                      ),

                      const SizedBox(width: 8),

                      Expanded(child: _buildHeader()),
                    ],
                  ),

                  const SizedBox(height: 22),

                  _buildSearchBar(),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: !_showFilters
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: _buildFilters(),
                          ),
                  ),

                  const SizedBox(height: 18),

                  Expanded(child: _buildContent()),

                  const SizedBox(height: 14),

                  _buildPagination(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Produtos',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gerencie os produtos cadastrados no sistema',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.62),
                fontSize: 13,
              ),
            ),
          ],
        );

        final actions = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: _openCreate,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Inserir'),
            ),

            FilledButton.icon(
              onPressed: _canEdit ? _openEdit : null,
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text('Editar'),
            ),

            FilledButton.icon(
              onPressed: _hasSelection ? _deleteSelected : null,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
              ),
              icon: const Icon(Icons.delete_outline, size: 17),
              label: const Text('Excluir'),
            ),

            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              icon: const Icon(Icons.tune, size: 17),
              label: const Text('Filtros'),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 16), actions],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _searchController,
      onSubmitted: (_) {
        _load(page: 0);
      },
      decoration: InputDecoration(
        hintText: _isMasterAdmin
            ? 'Buscar por nome, descrição ou empresa'
            : 'Buscar por nome ou descrição',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: 'Buscar',
          onPressed: () {
            _load(page: 0);
          },
          icon: const Icon(Icons.arrow_forward),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.55),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildFilters() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withOpacity(0.20)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final fields = [
            SizedBox(
              width: compact ? constraints.maxWidth : 220,
              child: DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Todos')),
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Ativos')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Inativos')),
                ],
                onChanged: (value) {
                  setState(() {
                    _status = value ?? '';
                  });
                },
              ),
            ),

            SizedBox(
              width: compact ? constraints.maxWidth : 180,
              child: TextField(
                controller: _minPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Preço mínimo',
                  prefixText: 'R\$ ',
                ),
              ),
            ),

            SizedBox(
              width: compact ? constraints.maxWidth : 180,
              child: TextField(
                controller: _maxPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Preço máximo',
                  prefixText: 'R\$ ',
                ),
              ),
            ),

            if (_isMasterAdmin)
              SizedBox(
                width: compact ? constraints.maxWidth : 280,
                child: InkWell(
                  onTap: _selectCompanyFilter,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Empresa',
                      suffixIcon: _companyId == null
                          ? const Icon(Icons.search)
                          : IconButton(
                              tooltip: 'Limpar empresa',
                              onPressed: _clearCompanyFilter,
                              icon: const Icon(Icons.close),
                            ),
                    ),
                    child: Text(
                      _companyName.isEmpty ? 'Todas' : _companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          ];

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...fields,

              FilledButton.icon(
                onPressed: () {
                  _load(page: 0);
                },
                icon: const Icon(Icons.search),
                label: const Text('Aplicar'),
              ),

              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Limpar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return const Center(child: Text('Nenhum produto encontrado.'));
    }

    return _buildTable();
  }

  Widget _buildTable() {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        //
        // A tabela nunca terá menos de 980px.
        //
        // Se a tela for maior que isso,
        // usamos toda a largura disponível.
        //
        // O ponto importante aqui é:
        // tableWidth SEMPRE possui valor finito.
        //
        final double tableWidth = constraints.maxWidth < 980
            ? 980
            : constraints.maxWidth;

        return Container(
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outline.withOpacity(0.22)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              //
              // ESSA É A CORREÇÃO PRINCIPAL.
              //
              // Agora os Rows abaixo recebem
              // uma largura FINITA.
              //
              width: tableWidth,
              child: Column(
                children: [
                  _buildTableHeader(),

                  Expanded(
                    child: ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        return _buildProductRow(_products[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.60),
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.20)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Checkbox(
              value: _allCurrentPageSelected,
              onChanged: _toggleCurrentPageSelection,
            ),
          ),

          const Expanded(flex: 4, child: _TableHeaderText('Produto')),

          if (_isMasterAdmin)
            const Expanded(flex: 3, child: _TableHeaderText('Empresa')),

          const Expanded(flex: 2, child: _TableHeaderText('Preço')),

          const Expanded(flex: 2, child: _TableHeaderText('Estoque')),

          const Expanded(flex: 2, child: _TableHeaderText('Status')),
        ],
      ),
    );
  }

  Widget _buildProductRow(ProductSummary product) {
    final colorScheme = Theme.of(context).colorScheme;

    final selected = _selectedIds.contains(product.id);

    return InkWell(
      onDoubleTap: () {
        setState(() {
          _selectedIds
            ..clear()
            ..add(product.id);
        });

        _openEdit();
      },
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withOpacity(0.05)
              : Colors.transparent,
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
                      _selectedIds.add(product.id);
                    } else {
                      _selectedIds.remove(product.id);
                    }
                  });
                },
              ),
            ),

            Expanded(flex: 4, child: _buildProductCell(product)),

            if (_isMasterAdmin)
              Expanded(
                flex: 3,
                child: Text(
                  product.companyName.isEmpty ? '-' : product.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            Expanded(
              flex: 2,
              child: Text(
                _money(product.price),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            Expanded(flex: 2, child: Text('${product.stockQuantity} un.')),

            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusBadge(product.status),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCell(ProductSummary product) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: colorScheme.surfaceContainerHighest,
          ),
          child: product.imageUrl.trim().isEmpty
              ? const Icon(Icons.image_outlined)
              : Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const Icon(Icons.broken_image_outlined);
                  },
                ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),

              if (product.description.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  product.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final colorScheme = Theme.of(context).colorScheme;

    final active = status == 'ACTIVE';

    final color = active ? const Color(0xFF2EAD72) : colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Página ${_page + 1} de ${_totalPages == 0 ? 1 : _totalPages}'),

        const SizedBox(width: 10),

        IconButton(
          tooltip: 'Página anterior',
          onPressed: _first
              ? null
              : () {
                  _load(page: _page - 1);
                },
          icon: const Icon(Icons.chevron_left),
        ),

        IconButton(
          tooltip: 'Próxima página',
          onPressed: _last
              ? null
              : () {
                  _load(page: _page + 1);
                },
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  final String text;

  const _TableHeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    );
  }
}
