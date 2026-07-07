import 'package:app_front_mobile/services/company_lookup_service.dart';
import 'package:flutter/material.dart';

class CompanyLookupModal extends StatefulWidget {
  final String? token;
  final CompanyLookupService service;

  const CompanyLookupModal({super.key, this.token, required this.service});

  static Future<CompanyLookupOption?> show({
    required BuildContext context,
    String? token,
    required CompanyLookupService service,
  }) {
    return showDialog<CompanyLookupOption>(
      context: context,
      builder: (_) {
        return CompanyLookupModal(token: token, service: service);
      },
    );
  }

  @override
  State<CompanyLookupModal> createState() => _CompanyLookupModalState();
}

class _CompanyLookupModalState extends State<CompanyLookupModal> {
  final _searchCtrl = TextEditingController();

  List<CompanyLookupOption> _companies = [];

  bool _loading = true;
  String? _error;

  int _page = 0;
  final int _size = 10;
  int _totalPages = 1;
  bool _first = true;
  bool _last = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies(page: 0);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies({required int page}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.service.findCompanies(
        token: widget.token,
        page: page,
        size: _size,
        search: _searchCtrl.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _companies = result.content;
        _page = result.number;
        _totalPages = result.totalPages;
        _first = result.first;
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

  InputDecoration _inputDecoration({required String hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark
          ? const Color(0xFF1C212B)
          : colorScheme.surfaceContainerHighest,
      prefixIcon: Icon(
        Icons.search,
        color: colorScheme.onSurface.withOpacity(0.65),
      ),
      suffixIcon: IconButton(
        onPressed: () => _loadCompanies(page: 0),
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

  Widget _buildGrid() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Text(
            'Erro ao buscar empresas',
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (_companies.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(child: Text('Nenhuma empresa encontrada')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11141B) : colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withOpacity(0.22)),
      ),
      child: Column(
        children: [
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF171A22)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Empresa',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'CNPJ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Tipo',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          ..._companies.map((company) {
            return InkWell(
              onTap: () {
                Navigator.of(context).pop(company);
              },
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withOpacity(0.12),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        company.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        company.cnpj.isEmpty ? '-' : company.cnpj,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        company.type.isEmpty ? '-' : company.type,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Pagina ${_page + 1} de $_totalPages'),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _first ? null : () => _loadCompanies(page: _page - 1),
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          onPressed: _last ? null : () => _loadCompanies(page: _page + 1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF171A22) : null,
      title: const Text('Selecionar empresa'),
      content: SizedBox(
        width: 760,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _loadCompanies(page: 0),
              decoration: _inputDecoration(
                hint: 'Buscar por nome, razao social ou CNPJ',
              ),
            ),
            const SizedBox(height: 16),
            _buildGrid(),
            const SizedBox(height: 12),
            _buildPagination(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
