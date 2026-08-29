import 'package:app_front_mobile/services/client_lookup_service.dart';
import 'package:flutter/material.dart';

class ClientLookupModal extends StatefulWidget {
  final String token;
  final ClientLookupService service;
  final String companyId;

  const ClientLookupModal({
    super.key,
    required this.token,
    required this.service,
    this.companyId = '',
  });

  static Future<ClientLookupOption?> show({
    required BuildContext context,
    required String token,
    required ClientLookupService service,
    String companyId = '',
  }) {
    return showDialog<ClientLookupOption>(
      context: context,
      builder: (_) => ClientLookupModal(
        token: token,
        service: service,
        companyId: companyId,
      ),
    );
  }

  @override
  State<ClientLookupModal> createState() => _ClientLookupModalState();
}

class _ClientLookupModalState extends State<ClientLookupModal> {
  final _searchCtrl = TextEditingController();

  List<ClientLookupOption> _clients = [];

  bool _loading = true;

  int _page = 0;
  int _totalPages = 1;

  bool _first = true;
  bool _last = true;

  @override
  void initState() {
    super.initState();
    _load(page: 0);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({required int page}) async {
    setState(() {
      _loading = true;
    });

    try {
      final result = await widget.service.findClients(
        token: widget.token,
        page: page,
        size: 10,
        search: _searchCtrl.text.trim(),
        companyId: widget.companyId,
      );

      if (!mounted) return;

      setState(() {
        _clients = result.content;
        _page = result.number;
        _totalPages = result.totalPages;
        _first = result.first;
        _last = result.last;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _clients = [];
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF171A22) : null,
      title: const Text('Selecionar cliente'),
      content: SizedBox(
        width: 760,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(page: 0),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou CPF',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () => _load(page: 0),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 330,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF11141B)
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.22),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Cliente',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'CPF',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ..._clients.map(
                            (client) => InkWell(
                              onTap: () => Navigator.of(context).pop(client),
                              child: Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        client.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(_formatCpf(client.cpfCnpj)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Pagina ${_page + 1} de $_totalPages'),
                IconButton(
                  onPressed: _first ? null : () => _load(page: _page - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: _last ? null : () => _load(page: _page + 1),
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
