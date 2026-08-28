import 'package:app_front_mobile/pages/professional_form_page.dart';
import 'package:app_front_mobile/services/professional_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/utils/input_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfessionalManagementPage extends StatefulWidget {
  const ProfessionalManagementPage({super.key});

  @override
  State<ProfessionalManagementPage> createState() =>
      _ProfessionalManagementPageState();
}

class _ProfessionalManagementPageState
    extends State<ProfessionalManagementPage> {
  final _professionalService = ProfessionalService(
    baseUrl: 'http://localhost:8081/professional',
  );

  final _tokenStorage = TokenStorage();
  final _searchController = TextEditingController();

  final Set<String> _selectedIds = {};

  List<ProfessionalSummary> _professionals = [];

  ProfessionalSearchFilters _filters = const ProfessionalSearchFilters();

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  int _page = 0;
  final int _size = 10;
  bool _last = true;

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
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

  Future<void> _loadProfessionals() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _last = true;
      _selectedIds.clear();
    });

    try {
      final token = await _getToken();

      final result = await _professionalService.findAll(
        token: token,
        page: 0,
        size: _size,
        filters: _filters.copyWith(search: _searchController.text.trim()),
      );

      if (!mounted) return;

      setState(() {
        _professionals = result.content;
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

  Future<void> _loadMoreProfessionals() async {
    if (_loadingMore || _last) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      final token = await _getToken();

      final result = await _professionalService.findAll(
        token: token,
        page: _page + 1,
        size: _size,
        filters: _filters.copyWith(search: _searchController.text.trim()),
      );

      if (!mounted) return;

      setState(() {
        _professionals.addAll(result.content);
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
      MaterialPageRoute(builder: (_) => const ProfessionalFormPage()),
    );

    if (!mounted) return;

    if (created == true) {
      await _loadProfessionals();
    }
  }

  Future<void> _openEditPage() async {
    if (_selectedIds.isEmpty) {
      AppMessage.info(context, 'Selecione um profissional para editar');
      return;
    }

    if (_selectedIds.length > 1) {
      AppMessage.info(context, 'Selecione apenas um profissional para editar');
      return;
    }

    final professionalId = _selectedIds.first;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfessionalFormPage(professionalId: professionalId),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _loadProfessionals();
    }
  }

  Future<void> _deleteSelectedProfessionals() async {
    if (_selectedIds.isEmpty) {
      AppMessage.info(context, 'Selecione um ou mais profissionais para excluir');
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
          title: const Text('Excluir profissionais'),
          content: Text(
            _selectedIds.length == 1
                ? 'Deseja realmente excluir o profissional selecionado?'
                : 'Deseja realmente excluir os profissionais selecionados?',
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

      await _professionalService.deleteProfessionals(
        token: token,
        ids: _selectedIds.toList(),
      );

      if (!mounted) return;

      AppMessage.success(context, 'Profissional excluido com sucesso');
      await _loadProfessionals();
    } catch (e) {
      if (!mounted) return;

      AppMessage.error(context, 'Erro ao excluir profissional: $e');
    }
  }

  Future<void> _openAdvancedSearchModal() async {
    final nameCtrl = TextEditingController(text: _filters.name);
    final cpfCtrl = TextEditingController(text: _filters.cpfCnpj);
    final phoneCtrl = TextEditingController(text: _filters.phone);
    final cityCtrl = TextEditingController(text: _filters.city);
    final stateCtrl = TextEditingController(text: _filters.state);

    String selectedStatus = _filters.status;

    final result = await showDialog<ProfessionalSearchFilters>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF171A22) : null,
              title: const Text('Pesquisa avancada'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nome'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cpfCtrl,
                        decoration: const InputDecoration(labelText: 'CPF'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cityCtrl,
                        decoration: const InputDecoration(labelText: 'Cidade'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: stateCtrl,
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
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('Todos')),
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
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop(const ProfessionalSearchFilters());
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
                      ProfessionalSearchFilters(
                        search: _searchController.text.trim(),
                        name: nameCtrl.text.trim(),
                        cpfCnpj: onlyNumbers(cpfCtrl.text),
                        phone: onlyNumbers(phoneCtrl.text),
                        city: cityCtrl.text.trim(),
                        state: stateCtrl.text.trim().toUpperCase(),
                        status: selectedStatus,
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

    nameCtrl.dispose();
    cpfCtrl.dispose();
    phoneCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();

    if (result == null) return;

    setState(() {
      _filters = result;
      _page = 0;
    });

    await _loadProfessionals();
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
      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.45)),
      prefixIcon: Icon(
        Icons.search,
        color: colorScheme.onSurface.withOpacity(0.65),
      ),
      suffixIcon: IconButton(
        onPressed: _loadProfessionals,
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
                'Profissionais',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gerencie os profissionais cadastrados no sistema',
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
              onPressed: _deleteSelectedProfessionals,
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
      onSubmitted: (_) => _loadProfessionals(),
      decoration: _inputDecoration(
        hint: 'Buscar por nome, CPF, telefone, cidade ou UF',
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
              Icon(Icons.error_outline, color: colorScheme.error, size: 42),
              const SizedBox(height: 12),
              Text(
                'Erro ao buscar profissionais',
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadProfessionals,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildProfessionalsGrid(),
        if (!_last) ...[
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              onPressed: _loadingMore ? null : _loadMoreProfessionals,
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
    );
  }

  Widget _buildProfessionalsGrid() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11141B) : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.22)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            _buildGridHeader(),
            if (_professionals.isEmpty)
              _buildEmptyGridState()
            else
              ..._professionals.map(_buildGridRow),
          ],
        ),
      ),
    );
  }

  Widget _buildGridHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allSelected =
        _professionals.isNotEmpty &&
        _selectedIds.length == _professionals.length;

    final partiallySelected =
        _selectedIds.isNotEmpty && _selectedIds.length < _professionals.length;

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF171A22)
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
              onChanged: _professionals.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds
                            ..clear()
                            ..addAll(_professionals.map((item) => item.id));
                        } else {
                          _selectedIds.clear();
                        }
                      });
                    },
            ),
          ),
          _buildHeaderCell('Nome', flex: 3),
          _buildHeaderCell('CPF', flex: 2),
          _buildHeaderCell('Telefone', flex: 2),
          _buildHeaderCell('Genero', flex: 2),
          _buildHeaderCell('Cidade', flex: 2),
          _buildHeaderCell('UF', flex: 1),
          _buildHeaderCell('Status', flex: 2),
        ],
      ),
    );
  }

  Widget _buildGridRow(ProfessionalSummary professional) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _selectedIds.contains(professional.id);

    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedIds.remove(professional.id);
          } else {
            _selectedIds.add(professional.id);
          }
        });
      },
      child: Container(
        height: 58,
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
                      _selectedIds.add(professional.id);
                    } else {
                      _selectedIds.remove(professional.id);
                    }
                  });
                },
              ),
            ),
            _buildBodyCell(professional.name, flex: 3),
            _buildBodyCell(professional.cpfCnpj, flex: 2),
            _buildBodyCell(professional.phone, flex: 2),
            _buildBodyCell(_formatOptionLabel(professional.gender), flex: 2),
            _buildBodyCell(professional.city, flex: 2),
            _buildBodyCell(professional.state, flex: 1),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(status: professional.status),
              ),
            ),
          ],
        ),
      ),
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
            Icons.badge_outlined,
            color: colorScheme.onSurface.withOpacity(0.45),
            size: 52,
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhum profissional encontrado',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cadastre um novo profissional ou ajuste os filtros',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatOptionLabel(String value) {
    return switch (value.toUpperCase()) {
      'ACTIVE' => 'Ativo',
      'INACTIVE' => 'Inativo',
      'MASCULINO' => 'Masculino',
      'FEMININO' => 'Feminino',
      'OUTRO' => 'Outro',
      _ => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administracao de profissionais')),
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

class _UpperCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upperText = newValue.text.toUpperCase();

    return TextEditingValue(
      text: upperText,
      selection: TextSelection.collapsed(offset: upperText.length),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final active = normalized == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
