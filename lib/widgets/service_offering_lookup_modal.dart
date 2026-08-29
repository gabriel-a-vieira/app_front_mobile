import 'package:app_front_mobile/services/service_offering_lookup_service.dart';
import 'package:flutter/material.dart';

class ServiceOfferingLookupModal extends StatefulWidget {
  final String token;

  final ServiceOfferingLookupService service;

  final String companyId;

  final List<ServiceOfferingLookupOption> initialSelection;

  const ServiceOfferingLookupModal({
    super.key,
    required this.token,
    required this.service,
    this.companyId = '',
    this.initialSelection = const [],
  });

  static Future<List<ServiceOfferingLookupOption>?> show({
    required BuildContext context,
    required String token,
    required ServiceOfferingLookupService service,
    String companyId = '',
    List<ServiceOfferingLookupOption> initialSelection = const [],
  }) {
    return showDialog<List<ServiceOfferingLookupOption>>(
      context: context,
      builder: (_) => ServiceOfferingLookupModal(
        token: token,
        service: service,
        companyId: companyId,
        initialSelection: initialSelection,
      ),
    );
  }

  @override
  State<ServiceOfferingLookupModal> createState() =>
      _ServiceOfferingLookupModalState();
}

class _ServiceOfferingLookupModalState
    extends State<ServiceOfferingLookupModal> {
  final _searchCtrl = TextEditingController();

  final Map<String, ServiceOfferingLookupOption> _selected = {};

  List<ServiceOfferingLookupOption> _services = [];

  bool _loading = true;

  int _page = 0;
  int _totalPages = 1;

  bool _first = true;
  bool _last = true;

  @override
  void initState() {
    super.initState();

    for (final item in widget.initialSelection) {
      _selected[item.id] = item;
    }

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
      final result = await widget.service.findServices(
        token: widget.token,
        page: page,
        size: 10,
        search: _searchCtrl.text.trim(),
        companyId: widget.companyId,
      );

      if (!mounted) return;

      setState(() {
        _services = result.content;
        _page = result.number;
        _totalPages = result.totalPages;
        _first = result.first;
        _last = result.last;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _services = [];
        _loading = false;
      });
    }
  }

  String _price(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF171A22) : null,
      title: Text('Selecionar servicos (${_selected.length})'),
      content: SizedBox(
        width: 820,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(page: 0),
              decoration: InputDecoration(
                hintText: 'Buscar servico',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () => _load(page: 0),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 350,
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
                                SizedBox(width: 42),
                                Expanded(flex: 3, child: Text('Servico')),
                                Expanded(flex: 2, child: Text('Duracao')),
                                Expanded(flex: 2, child: Text('Preco')),
                              ],
                            ),
                          ),

                          ..._services.map((service) {
                            final selected = _selected.containsKey(service.id);

                            return Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
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
                                            _selected[service.id] = service;
                                          } else {
                                            _selected.remove(service.id);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(flex: 3, child: Text(service.name)),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${service.durationMinutes} min',
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(_price(service.price)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
            ),

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
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selected.values.toList()),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
