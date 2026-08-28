import 'package:app_front_mobile/services/professional_lookup_service.dart';
import 'package:flutter/material.dart';

class ProfessionalLookupModal extends StatefulWidget {
  final String token;

  final ProfessionalLookupService service;

  final String companyId;

  const ProfessionalLookupModal({
    super.key,
    required this.token,
    required this.service,
    this.companyId = '',
  });

  static Future<ProfessionalLookupOption?> show({
    required BuildContext context,
    required String token,
    required ProfessionalLookupService service,
    String companyId = '',
  }) {
    return showDialog<ProfessionalLookupOption>(
      context: context,
      builder: (_) {
        return ProfessionalLookupModal(
          token: token,
          service: service,
          companyId: companyId,
        );
      },
    );
  }

  @override
  State<ProfessionalLookupModal> createState() =>
      _ProfessionalLookupModalState();
}

class _ProfessionalLookupModalState extends State<ProfessionalLookupModal> {
  final _searchCtrl = TextEditingController();

  List<ProfessionalLookupOption> _professionals = [];

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

    _loadProfessionals(page: 0);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();

    super.dispose();
  }

  Future<void> _loadProfessionals({required int page}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.service.findProfessionals(
        token: widget.token,
        page: page,
        size: _size,
        search: _searchCtrl.text.trim(),
        companyId: widget.companyId,
      );

      if (!mounted) return;

      setState(() {
        _professionals = result.content;

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

  String _formatCpf(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length != 11) {
      return value;
    }

    return '${digits.substring(0, 3)}.'
        '${digits.substring(3, 6)}.'
        '${digits.substring(6, 9)}-'
        '${digits.substring(9)}';
  }

  Widget _buildContent() {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 280,
        child: Center(
          child: Text(
            'Erro ao buscar profissionais',
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (_professionals.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(child: Text('Nenhum profissional encontrado')),
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
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Profissional',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'CPF',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          ..._professionals.map((professional) {
            return InkWell(
              onTap: () {
                Navigator.of(context).pop(professional);
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
                        professional.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatCpf(professional.cpfCnpj),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF171A22) : null,
      title: const Text('Selecionar profissional'),
      content: SizedBox(
        width: 760,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _loadProfessionals(page: 0),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou CPF',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () => _loadProfessionals(page: 0),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildContent(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Pagina ${_page + 1} de $_totalPages'),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _first
                      ? null
                      : () => _loadProfessionals(page: _page - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: _last
                      ? null
                      : () => _loadProfessionals(page: _page + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
