import 'package:app_front_mobile/pages/availability_form_page.dart';
import 'package:app_front_mobile/services/availability_service.dart';
import 'package:app_front_mobile/services/company_lookup_service.dart';
import 'package:app_front_mobile/services/professional_lookup_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/widgets/company_lookup_modal.dart';
import 'package:app_front_mobile/widgets/professional_lookup_modal.dart';
import 'package:flutter/material.dart';

class AvailabilityManagementPage extends StatefulWidget {
  final String currentUserRole;

  const AvailabilityManagementPage({super.key, required this.currentUserRole});

  bool get isMasterAdmin {
    return currentUserRole.toUpperCase() == 'MASTER_ADMIN';
  }

  @override
  State<AvailabilityManagementPage> createState() =>
      _AvailabilityManagementPageState();
}

class _AvailabilityManagementPageState
    extends State<AvailabilityManagementPage> {
  final _availabilityService = AvailabilityService(
    baseUrl: 'http://localhost:8081/availability',
  );

  final _professionalLookupService = ProfessionalLookupService(
    baseUrl: 'http://localhost:8081/professional',
  );

  final _companyLookupService = CompanyLookupService(
    baseUrl: 'http://localhost:8081/company/companies/home-page',
  );

  final _tokenStorage = TokenStorage();

  final _searchCtrl = TextEditingController();

  final Set<String> _selectedIds = {};

  List<AvailabilitySummary> _availabilities = [];

  AvailabilitySearchFilters _filters = const AvailabilitySearchFilters();

  ProfessionalLookupOption? _filterProfessional;

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

    _loadAvailabilities();
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

  Future<void> _loadAvailabilities() async {
    setState(() {
      _loading = true;
      _error = null;

      _page = 0;
      _last = true;

      _selectedIds.clear();
    });

    try {
      final token = await _getToken();

      final result = await _availabilityService.findAll(
        token: token,
        page: 0,
        size: _size,
        filters: _filters.copyWith(search: _searchCtrl.text.trim()),
      );

      if (!mounted) return;

      setState(() {
        _availabilities = result.content;

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

  Future<void> _loadMore() async {
    if (_loadingMore || _last) {
      return;
    }

    setState(() {
      _loadingMore = true;
    });

    try {
      final token = await _getToken();

      final result = await _availabilityService.findAll(
        token: token,
        page: _page + 1,
        size: _size,
        filters: _filters.copyWith(search: _searchCtrl.text.trim()),
      );

      if (!mounted) return;

      setState(() {
        _availabilities.addAll(result.content);

        _page = result.number;

        _last = result.last;

        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingMore = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openCreatePage() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AvailabilityFormPage()),
    );

    if (!mounted) return;

    if (created == true) {
      await _loadAvailabilities();
    }
  }

  Future<void> _openEditPage() async {
    if (_selectedIds.isEmpty) {
      AppMessage.info(context, 'Selecione uma disponibilidade');
      return;
    }

    if (_selectedIds.length > 1) {
      AppMessage.info(context, 'Selecione apenas uma disponibilidade para editar');
      return;
    }

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AvailabilityFormPage(availabilityId: _selectedIds.first),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _loadAvailabilities();
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) {
      AppMessage.info(context, 'Selecione uma ou mais disponibilidades');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: const Text('Excluir disponibilidade'),
          content: Text(
            _selectedIds.length == 1
                ? 'Deseja excluir a disponibilidade selecionada?'
                : 'Deseja excluir as disponibilidades selecionadas?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final token = await _getToken();

      await _availabilityService.deleteAvailabilities(
        token: token,
        ids: _selectedIds.toList(),
      );

      if (!mounted) return;

      AppMessage.success(context, 'Disponibilidade excluida com sucesso');

      await _loadAvailabilities();
    } catch (e) {
      if (!mounted) return;

      AppMessage.error(context, 'Erro ao excluir disponibilidade: $e');
    }
  }

  Future<void> _openFilters() async {
    String selectedDay = _filters.dayWeek;

    ProfessionalLookupOption? selectedProfessional = _filterProfessional;

    CompanyLookupOption? selectedCompany = _filterCompany;

    final professionalCtrl = TextEditingController(
      text: selectedProfessional?.name ?? '',
    );

    final companyCtrl = TextEditingController(
      text: selectedCompany?.displayName ?? '',
    );

    final result = await showDialog<_AvailabilityFilterResult>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Filtros'),
              content: SizedBox(
                width: 560,
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
                                      selectedProfessional = null;

                                      companyCtrl.clear();

                                      professionalCtrl.clear();
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

                                    selectedProfessional = null;

                                    companyCtrl.text = company.displayName;

                                    professionalCtrl.clear();
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
                      controller: professionalCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Profissional',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selectedProfessional != null)
                              IconButton(
                                onPressed: () {
                                  setModalState(() {
                                    selectedProfessional = null;

                                    professionalCtrl.clear();
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

                                final professional =
                                    await ProfessionalLookupModal.show(
                                      context: context,
                                      token: token,
                                      service: _professionalLookupService,
                                      companyId: selectedCompany?.id ?? '',
                                    );

                                if (professional == null) {
                                  return;
                                }

                                setModalState(() {
                                  selectedProfessional = professional;

                                  professionalCtrl.text = professional.name;
                                });
                              },
                              icon: const Icon(Icons.search),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedDay,
                      decoration: const InputDecoration(
                        labelText: 'Dia da semana',
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Todos')),
                        DropdownMenuItem(
                          value: 'MONDAY',
                          child: Text('Segunda-feira'),
                        ),
                        DropdownMenuItem(
                          value: 'TUESDAY',
                          child: Text('Terca-feira'),
                        ),
                        DropdownMenuItem(
                          value: 'WEDNESDAY',
                          child: Text('Quarta-feira'),
                        ),
                        DropdownMenuItem(
                          value: 'THURSDAY',
                          child: Text('Quinta-feira'),
                        ),
                        DropdownMenuItem(
                          value: 'FRIDAY',
                          child: Text('Sexta-feira'),
                        ),
                        DropdownMenuItem(
                          value: 'SATURDAY',
                          child: Text('Sabado'),
                        ),
                        DropdownMenuItem(
                          value: 'SUNDAY',
                          child: Text('Domingo'),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          selectedDay = value ?? '';
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      const _AvailabilityFilterResult(
                        filters: AvailabilitySearchFilters(),
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
                      _AvailabilityFilterResult(
                        filters: AvailabilitySearchFilters(
                          search: _searchCtrl.text.trim(),
                          professionalId: selectedProfessional?.id ?? '',
                          dayWeek: selectedDay,
                          companyId: selectedCompany?.id ?? '',
                        ),
                        professional: selectedProfessional,
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

    professionalCtrl.dispose();
    companyCtrl.dispose();

    if (result == null) return;

    setState(() {
      _filters = result.filters;

      _filterProfessional = result.professional;

      _filterCompany = result.company;
    });

    await _loadAvailabilities();
  }

  String _dayLabel(String day) {
    return switch (day) {
      'MONDAY' => 'Segunda',
      'TUESDAY' => 'Terca',
      'WEDNESDAY' => 'Quarta',
      'THURSDAY' => 'Quinta',
      'FRIDAY' => 'Sexta',
      'SATURDAY' => 'Sabado',
      'SUNDAY' => 'Domingo',
      _ => day,
    };
  }

  String _timeLabel(String value) {
    if (value.length >= 5) {
      return value.substring(0, 5);
    }

    return value;
  }

  String _durationLabel(AvailabilitySummary item) {
    final start = _timeToMinutes(item.startTime);

    final end = _timeToMinutes(item.endTime);

    if (start == null || end == null || end <= start) {
      return '-';
    }

    final total = end - start;

    final hours = total ~/ 60;

    final minutes = total % 60;

    if (hours == 0) {
      return '$minutes min';
    }

    if (minutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${minutes}min';
  }

  int? _timeToMinutes(String value) {
    final parts = value.split(':');

    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);

    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    return hour * 60 + minute;
  }

  Widget _buildHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildBodyCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text.isEmpty ? '-' : text,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildGrid() {
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
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            color: isDark
                ? const Color(0xFF171A22)
                : colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const SizedBox(width: 42),
                _buildHeaderCell('Profissional', flex: 3),
                _buildHeaderCell('Dia', flex: 2),
                _buildHeaderCell('Inicio', flex: 2),
                _buildHeaderCell('Fim', flex: 2),
                _buildHeaderCell('Duracao', flex: 2),
              ],
            ),
          ),
          if (_availabilities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Text('Nenhuma disponibilidade encontrada'),
            )
          else
            ..._availabilities.map((availability) {
              final selected = _selectedIds.contains(availability.id);

              return InkWell(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedIds.remove(availability.id);
                    } else {
                      _selectedIds.add(availability.id);
                    }
                  });
                },
                child: Container(
                  height: 58,
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
                                _selectedIds.add(availability.id);
                              } else {
                                _selectedIds.remove(availability.id);
                              }
                            });
                          },
                        ),
                      ),
                      _buildBodyCell(availability.professionalName, flex: 3),
                      _buildBodyCell(_dayLabel(availability.dayWeek), flex: 2),
                      _buildBodyCell(
                        _timeLabel(availability.startTime),
                        flex: 2,
                      ),
                      _buildBodyCell(_timeLabel(availability.endTime), flex: 2),
                      _buildBodyCell(_durationLabel(availability), flex: 2),
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
      appBar: AppBar(title: const Text('Administracao de disponibilidade')),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disponibilidade',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Defina os dias e horarios de trabalho dos profissionais',
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _openCreatePage,
                          icon: const Icon(Icons.add),
                          label: const Text('Inserir'),
                        ),
                        FilledButton.icon(
                          onPressed: _openEditPage,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar'),
                        ),
                        FilledButton.icon(
                          onPressed: _deleteSelected,
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Excluir'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openFilters,
                          icon: Icon(
                            _filters.hasAdvancedFilters
                                ? Icons.filter_alt
                                : Icons.tune,
                          ),
                          label: Text(
                            _filters.hasAdvancedFilters
                                ? 'Filtros aplicados'
                                : 'Filtros',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _loadAvailabilities(),
                  decoration: InputDecoration(
                    hintText: 'Buscar profissional por nome ou CPF',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: _loadAvailabilities,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 64),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_error != null)
                  Center(
                    child: Text(
                      'Erro ao buscar disponibilidades',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  )
                else
                  _buildGrid(),
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

class _AvailabilityFilterResult {
  final AvailabilitySearchFilters filters;

  final ProfessionalLookupOption? professional;

  final CompanyLookupOption? company;

  const _AvailabilityFilterResult({
    required this.filters,
    this.professional,
    this.company,
  });
}
