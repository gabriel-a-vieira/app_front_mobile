import 'package:app_front_mobile/config/api_config.dart';
import 'package:app_front_mobile/models/system_module.dart';
import 'package:app_front_mobile/pages/user_form_page.dart';
import 'package:app_front_mobile/services/user_admin_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/theme/app_colors.dart';
import 'package:app_front_mobile/utils/api_error_handler.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/utils/user_permissions.dart';
import 'package:app_front_mobile/widgets/common/async_list_section.dart';
import 'package:flutter/material.dart';

class UserManagementPage extends StatefulWidget {
  final String currentUserRole;

  const UserManagementPage({super.key, required this.currentUserRole});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _userAdminService = UserAdminService(
    baseUrl: '${ApiConfig.baseUrl}/users',
  );

  final _tokenStorage = TokenStorage();
  final _searchController = TextEditingController();

  final Set<String> _selectedIds = {};

  List<UserSummary> _users = [];

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  int _page = 0;
  final int _size = 10;
  bool _last = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
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

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _last = true;
      _selectedIds.clear();
    });

    try {
      final token = await _getToken();

      final result = await _userAdminService.findAll(
        token: token,
        page: 0,
        size: _size,
        search: _searchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _users = result.content;
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

  Future<void> _loadMoreUsers() async {
    if (_loadingMore || _last) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      final token = await _getToken();

      final result = await _userAdminService.findAll(
        token: token,
        page: _page + 1,
        size: _size,
        search: _searchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _users.addAll(result.content);
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
        builder: (_) => UserFormPage(currentUserRole: widget.currentUserRole),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await _loadUsers();
    }
  }

  Future<void> _openEditPage() async {
    if (_selectedIds.isEmpty) {
      AppMessage.info(context, 'Selecione um usuario para editar');
      return;
    }

    if (_selectedIds.length > 1) {
      AppMessage.info(context, 'Selecione apenas um usuario para editar');
      return;
    }

    final userId = _selectedIds.first;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UserFormPage(
          currentUserRole: widget.currentUserRole,
          userId: userId,
        ),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _loadUsers();
    }
  }

  Future<void> _deleteSelectedUsers() async {
    if (_selectedIds.isEmpty) {
      AppMessage.info(context, 'Selecione um ou mais usuarios para excluir');
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
          title: const Text('Excluir usuarios'),
          content: Text(
            _selectedIds.length == 1
                ? 'Deseja realmente excluir o usuario selecionado?'
                : 'Deseja realmente excluir os usuarios selecionados?',
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

      await _userAdminService.deleteUsers(
        token: token,
        ids: _selectedIds.toList(),
      );

      if (!mounted) return;

      AppMessage.success(context, 'Usuario excluido com sucesso');
      await _loadUsers();
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(context, e, fallback: 'Erro ao excluir usuario.');
    }
  }

  String _roleLabel(String role) {
    return switch (role.toUpperCase()) {
      'MASTER_ADMIN' => 'Administrador da plataforma',
      'COMPANY_ADMIN' => 'Administrador da empresa',
      'PROFESSIONAL' => 'Profissional',
      'CLIENT' => 'Cliente',
      _ => role,
    };
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
        onPressed: _loadUsers,
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
                'Usuarios',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gerencie os usuarios cadastrados no sistema',
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
            if (UserPermissions.can(SystemModule.user, CrudAction.create))
              _buildActionButton(
                label: 'Inserir',
                icon: Icons.add,
                onPressed: _openCreatePage,
              ),
            if (UserPermissions.can(SystemModule.user, CrudAction.update))
              _buildActionButton(
                label: 'Editar',
                icon: Icons.edit_outlined,
                onPressed: _openEditPage,
              ),
            if (UserPermissions.can(SystemModule.user, CrudAction.delete))
              _buildActionButton(
                label: 'Excluir',
                icon: Icons.delete_outline,
                danger: true,
                onPressed: _deleteSelectedUsers,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onSubmitted: (_) => _loadUsers(),
      decoration: _inputDecoration(hint: 'Buscar por nome ou email'),
    );
  }

  Widget _buildContent() {
    return AsyncListSection(
      loading: _loading,
      hasError: _error != null,
      errorLabel: 'Erro ao buscar usuarios',
      onRetry: _loadUsers,
      content: _buildUsersGrid(),
      hasMore: !_last,
      loadingMore: _loadingMore,
      onLoadMore: _loadMoreUsers,
    );
  }

  Widget _buildUsersGrid() {
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
            if (_users.isEmpty)
              _buildEmptyGridState()
            else
              ..._users.map(_buildGridRow),
          ],
        ),
      ),
    );
  }

  Widget _buildGridHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allSelected = _users.isNotEmpty && _selectedIds.length == _users.length;
    final partiallySelected =
        _selectedIds.isNotEmpty && _selectedIds.length < _users.length;

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
              onChanged: _users.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds
                            ..clear()
                            ..addAll(_users.map((item) => item.id));
                        } else {
                          _selectedIds.clear();
                        }
                      });
                    },
            ),
          ),
          _buildHeaderCell('Nome', flex: 3),
          _buildHeaderCell('Email', flex: 3),
          _buildHeaderCell('Funcao', flex: 2),
        ],
      ),
    );
  }

  Widget _buildGridRow(UserSummary user) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _selectedIds.contains(user.id);

    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedIds.remove(user.id);
          } else {
            _selectedIds.add(user.id);
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
                      _selectedIds.add(user.id);
                    } else {
                      _selectedIds.remove(user.id);
                    }
                  });
                },
              ),
            ),
            _buildBodyCell(user.name, flex: 3),
            _buildBodyCell(user.email, flex: 3),
            _buildBodyCell(_roleLabel(user.role), flex: 2),
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
            Icons.people_alt_outlined,
            color: colorScheme.onSurface.withOpacity(0.45),
            size: 52,
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhum usuario encontrado',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cadastre um novo usuario ou ajuste a busca',
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
      appBar: AppBar(title: const Text('Administracao de usuarios')),
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
