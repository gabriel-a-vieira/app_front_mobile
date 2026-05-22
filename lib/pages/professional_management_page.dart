import 'package:app_front_mobile/pages/professional_form_page.dart';
import 'package:app_front_mobile/services/professional_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:flutter/material.dart';

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

      final result = await _professionalService.findProfessionals(
        token: token,
        page: 0,
        size: _size,
        search: _searchController.text,
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

      final result = await _professionalService.findProfessionals(
        token: token,
        page: _page + 1,
        size: _size,
        search: _searchController.text,
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
      MaterialPageRoute(
        builder: (_) => const ProfessionalFormPage(),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await _loadProfessionals();
    }
  }

  Future<void> _openEditPage() async {
    if (_selectedIds.isEmpty) {
      _showMessage('Selecione um profissional para editar');
      return;
    }

    if (_selectedIds.length > 1) {
      _showMessage('Selecione apenas um profissional para editar');
      return;
    }

    final professionalId = _selectedIds.first;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfessionalFormPage(
          professionalId: professionalId,
        ),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _loadProfessionals();
    }
  }

  Future<void> _deleteSelectedProfessionals() async {
    if (_selectedIds.isEmpty) {
      _showMessage('Selecione um ou mais profissionais para excluir');
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

      _showMessage('Profissional excluido com sucesso');
      await _loadProfessionals();
    } catch (e) {
      if (!mounted) return;

      _showMessage('Erro ao excluir profissional: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor:
          isDark ? const Color(0xFF1C212B) : colorScheme.surfaceContainerHighest,
      hintStyle: TextStyle(
        color: colorScheme.onSurface.withOpacity(0.45),
      ),
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
        borderSide: BorderSide(
          color: colorScheme.outline.withOpacity(0.25),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.primary,
        ),
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
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: danger ? colorScheme.error : colorScheme.primary,
          foregroundColor: danger ? colorScheme.onError : colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
        hint: 'Buscar profissional por nome',
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
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 42,
              ),
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

    if (_professionals.isEmpty) {
      return Center(
        child: Padding(
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
                'Cadastre um novo profissional para iniciar',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildTable(),
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

  Widget _buildTable() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11141B) : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.22),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: true,
            headingRowColor: WidgetStatePropertyAll(
              isDark
                  ? const Color(0xFF171A22)
                  : colorScheme.surfaceContainerHighest,
            ),
            dataRowMinHeight: 56,
            dataRowMaxHeight: 64,
            columns: const [
              DataColumn(label: Text('Nome')),
              DataColumn(label: Text('CPF')),
              DataColumn(label: Text('Telefone')),
              DataColumn(label: Text('Genero')),
              DataColumn(label: Text('Cidade')),
              DataColumn(label: Text('UF')),
              DataColumn(label: Text('Status')),
            ],
            rows: _professionals.map((professional) {
              final selected = _selectedIds.contains(professional.id);

              return DataRow(
                selected: selected,
                onSelectChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedIds.add(professional.id);
                    } else {
                      _selectedIds.remove(professional.id);
                    }
                  });
                },
                cells: [
                  DataCell(Text(professional.name)),
                  DataCell(Text(professional.cpfCnpj)),
                  DataCell(Text(professional.phone)),
                  DataCell(Text(professional.gender)),
                  DataCell(Text(professional.city)),
                  DataCell(Text(professional.state)),
                  DataCell(_StatusBadge(status: professional.status)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administracao de profissionais'),
      ),
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

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final active = normalized == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
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