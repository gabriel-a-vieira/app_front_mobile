import 'package:app_front_mobile/pages/appointment_form_page.dart';
import 'package:app_front_mobile/services/appointment_service.dart';
import 'package:app_front_mobile/services/company_lookup_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/widgets/company_lookup_modal.dart';
import 'package:flutter/material.dart';

class AppointmentManagementPage extends StatefulWidget {
  final String currentUserRole;

  const AppointmentManagementPage({super.key, required this.currentUserRole});

  bool get isMasterAdmin => currentUserRole.toUpperCase() == 'MASTER_ADMIN';

  @override
  State<AppointmentManagementPage> createState() =>
      _AppointmentManagementPageState();
}

class _AppointmentManagementPageState extends State<AppointmentManagementPage> {
  final _appointmentService = AppointmentService(
    baseUrl: 'http://localhost:8081/appointment',
  );

  final _companyLookupService = CompanyLookupService(
    baseUrl: 'http://localhost:8081/company/companies/home-page',
  );

  final _tokenStorage = TokenStorage();

  final _searchCtrl = TextEditingController();

  final Set<String> _selectedIds = {};

  List<AppointmentSummary> _appointments = [];

  AppointmentSearchFilters _filters = const AppointmentSearchFilters();

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
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;

      _page = 0;
      _last = true;

      _selectedIds.clear();
    });

    try {
      final token = await _getToken();

      final result = await _appointmentService.findAll(
        token: token,
        page: 0,
        size: _size,
        filters: _filters.copyWith(search: _searchCtrl.text.trim()),
      );

      if (!mounted) return;

      setState(() {
        _appointments = result.content;

        _page = result.number;
        _last = result.last;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });

      AppMessage.apiError(context, e, fallback: 'Erro ao buscar agendamentos.');
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _last) {
      return;
    }

    setState(() {
      _loadingMore = true;
    });

    try {
      final token = await _getToken();

      final result = await _appointmentService.findAll(
        token: token,
        page: _page + 1,
        size: _size,
        filters: _filters.copyWith(search: _searchCtrl.text.trim()),
      );

      if (!mounted) return;

      setState(() {
        _appointments.addAll(result.content);

        _page = result.number;
        _last = result.last;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingMore = false;
      });

      AppMessage.apiError(context, e);
    }
  }

  Future<void> _create() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AppointmentFormPage(currentUserRole: widget.currentUserRole),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _load();
    }
  }

  Future<void> _edit() async {
    if (_selectedIds.length != 1) {
      AppMessage.info(context, 'Selecione apenas um agendamento para editar.');
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AppointmentFormPage(
          appointmentId: _selectedIds.first,
          currentUserRole: widget.currentUserRole,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _load();
    }
  }

  Future<void> _cancel() async {
    if (_selectedIds.isEmpty) {
      AppMessage.info(context, 'Selecione um ou mais agendamentos.');

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancelar agendamento'),
          content: Text(
            _selectedIds.length == 1
                ? 'Deseja cancelar o agendamento selecionado?'
                : 'Deseja cancelar os agendamentos selecionados?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final token = await _getToken();

      await _appointmentService.cancelAppointments(
        token: token,
        ids: _selectedIds.toList(),
      );

      if (!mounted) return;

      AppMessage.success(context, 'Agendamento cancelado com sucesso');

      await _load();
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(
        context,
        e,
        fallback: 'Erro ao cancelar agendamento.',
      );
    }
  }

  Future<void> _filtersModal() async {
    String status = _filters.status;

    DateTime? dateFrom = _parseApiDate(_filters.dateFrom);

    DateTime? dateTo = _parseApiDate(_filters.dateTo);

    CompanyLookupOption? selectedCompany = _filterCompany;

    final companyCtrl = TextEditingController(
      text: selectedCompany?.displayName ?? '',
    );

    final result = await showDialog<_AppointmentFilterResult>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Filtros'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isMasterAdmin) ...[
                      TextField(
                        controller: companyCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Empresa',
                          suffixIcon: IconButton(
                            onPressed: () async {
                              final token = await _getToken();

                              if (!context.mounted) {
                                return;
                              }

                              final company = await CompanyLookupModal.show(
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
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Todos')),
                        DropdownMenuItem(
                          value: 'SCHEDULED',
                          child: Text('Agendado'),
                        ),
                        DropdownMenuItem(
                          value: 'CONFIRMED',
                          child: Text('Confirmado'),
                        ),
                        DropdownMenuItem(
                          value: 'CANCELLED',
                          child: Text('Cancelado'),
                        ),
                        DropdownMenuItem(
                          value: 'COMPLETED',
                          child: Text('Concluido'),
                        ),
                        DropdownMenuItem(
                          value: 'NO_SHOW',
                          child: Text('Nao compareceu'),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          status = value ?? '';
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    ListTile(
                      title: const Text('Data inicial'),
                      subtitle: Text(
                        dateFrom != null
                            ? _formatDate(dateFrom!)
                            : 'Nao informado',
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final value = await showDatePicker(
                          context: context,
                          initialDate: dateFrom ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );

                        if (value != null) {
                          setModalState(() {
                            dateFrom = value;
                          });
                        }
                      },
                    ),

                    ListTile(
                      title: const Text('Data final'),
                      subtitle: Text(
                        dateTo != null ? _formatDate(dateTo!) : 'Nao informado',
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final value = await showDatePicker(
                          context: context,
                          initialDate: dateTo ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );

                        if (value != null) {
                          setModalState(() {
                            dateTo = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(
                    const _AppointmentFilterResult(
                      filters: AppointmentSearchFilters(),
                    ),
                  ),
                  child: const Text('Limpar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    _AppointmentFilterResult(
                      filters: AppointmentSearchFilters(
                        status: status,
                        companyId: selectedCompany?.id ?? '',
                        dateFrom: dateFrom != null ? _apiDate(dateFrom!) : '',
                        dateTo: dateTo != null ? _apiDate(dateTo!) : '',
                      ),
                      company: selectedCompany,
                    ),
                  ),
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    companyCtrl.dispose();

    if (result == null) return;

    setState(() {
      _filters = result.filters;
      _filterCompany = result.company;
    });

    await _load();
  }

  String _statusLabel(String value) {
    return switch (value) {
      'SCHEDULED' => 'Agendado',
      'CONFIRMED' => 'Confirmado',
      'CANCELLED' => 'Cancelado',
      'COMPLETED' => 'Concluido',
      'NO_SHOW' => 'Nao compareceu',
      _ => value,
    };
  }

  String _servicesLabel(AppointmentSummary item) {
    return item.services.map((service) => service.name).join(', ');
  }

  String _dateTimeLabel(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return '${_formatDate(date)} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _apiDate(DateTime value) {
    return '${value.year}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseApiDate(String value) {
    if (value.isEmpty) return null;

    return DateTime.tryParse(value);
  }

  Widget _cell(String value, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        value.isEmpty ? '-' : value,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _grid() {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11141B) : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.22)),
      ),
      child: Column(
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            color: isDark
                ? const Color(0xFF171A22)
                : colorScheme.surfaceContainerHighest,
            child: const Row(
              children: [
                SizedBox(width: 42),
                Expanded(flex: 3, child: Text('Cliente')),
                Expanded(flex: 3, child: Text('Profissional')),
                Expanded(flex: 3, child: Text('Servicos')),
                Expanded(flex: 2, child: Text('Data/Hora')),
                Expanded(flex: 2, child: Text('Status')),
              ],
            ),
          ),

          if (_appointments.isEmpty)
            const SizedBox(
              height: 150,
              child: Center(child: Text('Nenhum agendamento encontrado')),
            )
          else
            ..._appointments.map((item) {
              final selected = _selectedIds.contains(item.id);

              return InkWell(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedIds.remove(item.id);
                    } else {
                      _selectedIds.add(item.id);
                    }
                  });
                },
                child: Container(
                  height: 62,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primary.withOpacity(0.08)
                        : null,
                    border: Border(
                      top: BorderSide(
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
                                _selectedIds.add(item.id);
                              } else {
                                _selectedIds.remove(item.id);
                              }
                            });
                          },
                        ),
                      ),
                      _cell(item.clientName, flex: 3),
                      _cell(item.professionalName, flex: 3),
                      _cell(_servicesLabel(item), flex: 3),
                      _cell(_dateTimeLabel(item.startAt), flex: 2),
                      _cell(_statusLabel(item.status), flex: 2),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Administracao de agendamentos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Agendamentos',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    Wrap(
                      spacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _create,
                          icon: const Icon(Icons.add),
                          label: const Text('Inserir'),
                        ),
                        FilledButton.icon(
                          onPressed: _edit,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                        ),
                        FilledButton.icon(
                          onPressed: _cancel,
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                          ),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancelar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _filtersModal,
                          icon: const Icon(Icons.tune),
                          label: const Text('Filtros'),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: 'Buscar por cliente ou profissional',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: _load,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Center(
                    child: Text(
                      'Erro ao carregar agendamentos',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  )
                else
                  _grid(),

                if (!_last && !_loading) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: OutlinedButton(
                      onPressed: _loadingMore ? null : _loadMore,
                      child: _loadingMore
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Carregar mais'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentFilterResult {
  final AppointmentSearchFilters filters;

  final CompanyLookupOption? company;

  const _AppointmentFilterResult({required this.filters, this.company});
}
