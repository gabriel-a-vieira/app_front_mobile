import 'package:app_front_mobile/pages/product_form_page.dart';
import 'package:app_front_mobile/services/company_lookup_service.dart';
import 'package:app_front_mobile/services/product_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/theme/app_colors.dart';
import 'package:app_front_mobile/utils/api_error_handler.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/widgets/common/async_list_section.dart';
import 'package:app_front_mobile/widgets/company_lookup_modal.dart';
import 'package:flutter/material.dart';
import 'package:app_front_mobile/config/api_config.dart';
import 'package:app_front_mobile/models/system_module.dart';
import 'package:app_front_mobile/utils/user_permissions.dart';

class ProductManagementPage extends StatefulWidget {
  final String currentUserRole;

  const ProductManagementPage({super.key, required this.currentUserRole});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final _service = ProductService(baseUrl: '${ApiConfig.baseUrl}/product');

  final _companyLookupService = CompanyLookupService(
    baseUrl: '${ApiConfig.baseUrl}/company',
  );

  final _tokenStorage = TokenStorage();
  final _searchController = TextEditingController();

  final Set<String> _selectedIds = {};

  List<ProductSummary> _products = [];

  _ProductFilters _filters = const _ProductFilters();
  String _companyName = '';

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  int _page = 0;
  final int _size = 10;
  bool _last = true;

  bool get _isMasterAdmin => widget.currentUserRole == 'MASTER_ADMIN';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _last = true;
      _selectedIds.clear();
    });

    try {
      final token = await _getToken();

      final result = await _service.findAll(
        token: token,
        page: 0,
        size: _size,
        search: _searchController.text.trim(),
        status: _filters.status,
        minPrice: _filters.minPrice,
        maxPrice: _filters.maxPrice,
        companyId: _isMasterAdmin ? _filters.companyId : null,
      );

      if (!mounted) return;

      setState(() {
        _products = result.content;
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

  Future<void> _loadMoreProducts() async {
    if (_loadingMore || _last) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      final token = await _getToken();

      final result = await _service.findAll(
        token: token,
        page: _page + 1,
        size: _size,
        search: _searchController.text.trim(),
        status: _filters.status,
        minPrice: _filters.minPrice,
        maxPrice: _filters.maxPrice,
        companyId: _isMasterAdmin ? _filters.companyId : null,
      );

      if (!mounted) return;

      setState(() {
        _products.addAll(result.content);
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
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProductFormPage(currentUserRole: widget.currentUserRole),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await _loadProducts();
    }
  }

  Future<void> _openEditPage() async {
    if (_selectedIds.isEmpty) {
      AppMessage.info(context, 'Selecione um produto para editar');
      return;
    }

    if (_selectedIds.length > 1) {
      AppMessage.info(context, 'Selecione apenas um produto para editar');
      return;
    }

    final productId = _selectedIds.first;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProductFormPage(
          currentUserRole: widget.currentUserRole,
          productId: productId,
        ),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _loadProducts();
    }
  }

  Future<void> _deleteSelectedProducts() async {
    if (_selectedIds.isEmpty) {
      AppMessage.info(context, 'Selecione um ou mais produtos para excluir');
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
          title: const Text('Excluir produtos'),
          content: Text(
            _selectedIds.length == 1
                ? 'Deseja realmente excluir o produto selecionado?'
                : 'Deseja realmente excluir os produtos selecionados?',
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

      await _service.deleteMany(
        token: token,
        ids: _selectedIds.toList(),
        companyId: _isMasterAdmin ? _filters.companyId : null,
      );

      if (!mounted) return;

      AppMessage.success(context, 'Produto(s) excluido(s) com sucesso');
      await _loadProducts();
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(context, e, fallback: 'Erro ao excluir produtos.');
    }
  }

  Future<void> _openAdvancedSearchModal() async {
    final minPriceController = TextEditingController(
      text: _filters.minPrice?.toStringAsFixed(2) ?? '',
    );
    final maxPriceController = TextEditingController(
      text: _filters.maxPrice?.toStringAsFixed(2) ?? '',
    );
    final companyController = TextEditingController(text: _companyName);

    String selectedStatus = _filters.status;
    String? selectedCompanyId = _filters.companyId;
    String selectedCompanyName = _companyName;

    final result = await showDialog<_ProductFilterResult>(
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
                      if (_isMasterAdmin) ...[
                        TextField(
                          controller: companyController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Empresa',
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selectedCompanyId != null)
                                  IconButton(
                                    onPressed: () {
                                      setModalState(() {
                                        selectedCompanyId = null;
                                        selectedCompanyName = '';
                                        companyController.clear();
                                      });
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                                IconButton(
                                  onPressed: () async {
                                    final token = await _getToken();

                                    final company = await CompanyLookupModal.show(
                                      context: context,
                                      token: token,
                                      service: _companyLookupService,
                                    );

                                    if (company == null) return;

                                    setModalState(() {
                                      selectedCompanyId = company.id;
                                      selectedCompanyName = company.displayName;
                                      companyController.text = company.displayName;
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
                          DropdownMenuItem(value: '', child: Text('Todos')),
                          DropdownMenuItem(value: 'ACTIVE', child: Text('Ativos')),
                          DropdownMenuItem(
                            value: 'INACTIVE',
                            child: Text('Inativos'),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            selectedStatus = value ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: minPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Preco minimo',
                          prefixText: 'R\$ ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: maxPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Preco maximo',
                          prefixText: 'R\$ ',
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
                      const _ProductFilterResult(
                        filters: _ProductFilters(),
                        companyName: '',
                      ),
                    );
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
                      _ProductFilterResult(
                        filters: _ProductFilters(
                          status: selectedStatus,
                          minPrice: _parsePrice(minPriceController.text),
                          maxPrice: _parsePrice(maxPriceController.text),
                          companyId: selectedCompanyId,
                        ),
                        companyName: selectedCompanyName,
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

    minPriceController.dispose();
    maxPriceController.dispose();
    companyController.dispose();

    if (result == null) return;

    setState(() {
      _filters = result.filters;
      _companyName = result.companyName;
    });

    await _loadProducts();
  }

  double? _parsePrice(String value) {
    final text = value.trim().replaceAll(',', '.');

    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(text);
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
        onPressed: _loadProducts,
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
                'Produtos',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gerencie os produtos cadastrados no sistema',
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
            if (UserPermissions.can(SystemModule.product, CrudAction.create))
              _buildActionButton(
                label: 'Inserir',
                icon: Icons.add,
                onPressed: _openCreatePage,
              ),
            if (UserPermissions.can(SystemModule.product, CrudAction.update))
              _buildActionButton(
                label: 'Editar',
                icon: Icons.edit_outlined,
                onPressed: _openEditPage,
              ),
            if (UserPermissions.can(SystemModule.product, CrudAction.delete))
              _buildActionButton(
                label: 'Excluir',
                icon: Icons.delete_outline,
                danger: true,
                onPressed: _deleteSelectedProducts,
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
      onSubmitted: (_) => _loadProducts(),
      decoration: _inputDecoration(
        hint: _isMasterAdmin
            ? 'Buscar por nome, descricao ou empresa'
            : 'Buscar por nome ou descricao',
      ),
    );
  }

  Widget _buildContent() {
    return AsyncListSection(
      loading: _loading,
      hasError: _error != null,
      errorLabel: 'Erro ao buscar produtos',
      onRetry: _loadProducts,
      content: _buildProductsGrid(),
      hasMore: !_last,
      loadingMore: _loadingMore,
      onLoadMore: _loadMoreProducts,
    );
  }

  Widget _buildProductsGrid() {
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
            if (_products.isEmpty)
              _buildEmptyGridState()
            else
              ..._products.map(_buildGridRow),
          ],
        ),
      ),
    );
  }

  Widget _buildGridHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allSelected =
        _products.isNotEmpty && _selectedIds.length == _products.length;
    final partiallySelected =
        _selectedIds.isNotEmpty && _selectedIds.length < _products.length;

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
              onChanged: _products.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds
                            ..clear()
                            ..addAll(_products.map((item) => item.id));
                        } else {
                          _selectedIds.clear();
                        }
                      });
                    },
            ),
          ),
          _buildHeaderCell('Produto', flex: 4),
          if (_isMasterAdmin) _buildHeaderCell('Empresa', flex: 2),
          _buildHeaderCell('Preco', flex: 2),
          _buildHeaderCell('Estoque', flex: 1),
          _buildHeaderCell('Status', flex: 2),
        ],
      ),
    );
  }

  Widget _buildGridRow(ProductSummary product) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _selectedIds.contains(product.id);

    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedIds.remove(product.id);
          } else {
            _selectedIds.add(product.id);
          }
        });
      },
      child: Container(
        height: 62,
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
                flex: 2,
                child: Text(
                  product.companyName.isEmpty ? '-' : product.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                ),
              ),
            _buildBodyCell(_money(product.price), flex: 2),
            _buildBodyCell('${product.stockQuantity} un.', flex: 1),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(
                  active: product.status.toUpperCase() == 'ACTIVE',
                  label: _statusLabel(product.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Peculiaridade do cadastro de produtos: a celula "Produto" mostra uma
  /// miniatura da imagem, ao contrario das outras telas cujo grid e so texto.
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
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
            Icons.inventory_2_outlined,
            color: colorScheme.onSurface.withOpacity(0.45),
            size: 52,
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhum produto encontrado',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cadastre um novo produto ou ajuste os filtros',
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
      appBar: AppBar(title: const Text('Administracao de produtos')),
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

class _ProductFilters {
  final String status;
  final double? minPrice;
  final double? maxPrice;
  final String? companyId;

  const _ProductFilters({
    this.status = '',
    this.minPrice,
    this.maxPrice,
    this.companyId,
  });

  bool get hasAdvancedFilters =>
      status.isNotEmpty || minPrice != null || maxPrice != null || companyId != null;
}

class _ProductFilterResult {
  final _ProductFilters filters;
  final String companyName;

  const _ProductFilterResult({required this.filters, required this.companyName});
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
