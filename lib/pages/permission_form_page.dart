import 'package:app_front_mobile/config/api_config.dart';
import 'package:app_front_mobile/models/system_module.dart';
import 'package:app_front_mobile/services/permission_service.dart';
import 'package:app_front_mobile/services/user_lookup_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/theme/app_colors.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/widgets/user_lookup_modal.dart';
import 'package:app_front_mobile/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';

/// Inserir/Editar form for a single user's permission profile: pick a user
/// (search modal, like the professional/company lookups elsewhere) then set
/// their CRUD flags per module.
class PermissionFormPage extends StatefulWidget {
  final PermissionProfile? profile;

  const PermissionFormPage({super.key, this.profile});

  bool get isEditing => profile != null;

  @override
  State<PermissionFormPage> createState() => _PermissionFormPageState();
}

class _PermissionFormPageState extends State<PermissionFormPage> {
  final _permissionService = PermissionService(
    baseUrl: '${ApiConfig.baseUrl}/permission',
  );

  final _userLookupService = UserLookupService(
    baseUrl: '${ApiConfig.baseUrl}/users',
  );

  final _tokenStorage = TokenStorage();
  final _userCtrl = TextEditingController();

  UserLookupOption? _selectedUser;

  List<ModulePermissionEntry> _entries = SystemModule.values
      .map(
        (module) => ModulePermissionEntry(
          module: module,
          canCreate: true,
          canUpdate: true,
          canList: true,
          canDelete: true,
        ),
      )
      .toList();

  bool _loading = false;
  bool _saving = false;

  String? get _userId =>
      widget.isEditing ? widget.profile!.userId : _selectedUser?.id;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _userCtrl.text = '${widget.profile!.name} (${widget.profile!.email})';
      _loadMatrix();
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  Future<void> _loadMatrix() async {
    setState(() {
      _loading = true;
    });

    try {
      final token = await _getToken();

      final entries = await _permissionService.findUserMatrix(
        token: token,
        userId: widget.profile!.userId,
      );

      if (!mounted) return;

      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      AppMessage.apiError(context, e, fallback: 'Erro ao carregar permissoes');
    }
  }

  Future<void> _openUserLookup() async {
    final token = await _getToken();

    if (!mounted) return;

    final user = await UserLookupModal.show(
      context: context,
      token: token,
      service: _userLookupService,
    );

    if (user == null) return;

    setState(() {
      _selectedUser = user;
      _userCtrl.text = '${user.name} (${user.email})';
    });
  }

  void _toggle(
    SystemModule module, {
    bool? canCreate,
    bool? canUpdate,
    bool? canList,
    bool? canDelete,
  }) {
    setState(() {
      _entries = _entries.map((entry) {
        if (entry.module != module) {
          return entry;
        }

        return entry.copyWith(
          canCreate: canCreate,
          canUpdate: canUpdate,
          canList: canList,
          canDelete: canDelete,
        );
      }).toList();
    });
  }

  ModulePermissionEntry? _entryFor(SystemModule module) {
    for (final entry in _entries) {
      if (entry.module == module) {
        return entry;
      }
    }

    return null;
  }

  Future<void> _submit() async {
    final userId = _userId;

    if (userId == null || userId.isEmpty) {
      AppMessage.info(context, 'Selecione o usuario');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final token = await _getToken();

      await _permissionService.updateUserMatrix(
        token: token,
        userId: userId,
        entries: _entries,
      );

      if (!mounted) return;

      AppMessage.success(
        context,
        widget.isEditing
            ? 'Permissoes atualizadas com sucesso'
            : 'Permissoes cadastradas com sucesso',
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(context, e, fallback: 'Erro ao salvar permissoes.');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark
          ? AppColors.darkInputFill
          : colorScheme.surfaceContainerHighest,
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

  Widget _buildUserField() {
    return TextFormField(
      controller: _userCtrl,
      readOnly: true,
      enabled: !widget.isEditing,
      onTap: widget.isEditing ? null : _openUserLookup,
      decoration: _inputDecoration(
        label: 'Usuario',
        hint: 'Selecione o usuario',
        suffixIcon: widget.isEditing
            ? null
            : IconButton(
                onPressed: _openUserLookup,
                icon: const Icon(Icons.search),
              ),
      ),
    );
  }

  Widget _buildMatrixTable() {
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Modulo')),
              DataColumn(label: Text('Inserir')),
              DataColumn(label: Text('Alterar')),
              DataColumn(label: Text('Listar')),
              DataColumn(label: Text('Deletar')),
            ],
            rows: SystemModule.values.map((module) {
              final entry = _entryFor(module);

              return DataRow(
                cells: [
                  DataCell(Text(module.label)),
                  DataCell(
                    Checkbox(
                      value: entry?.canCreate ?? true,
                      onChanged: (value) => _toggle(module, canCreate: value),
                    ),
                  ),
                  DataCell(
                    Checkbox(
                      value: entry?.canUpdate ?? true,
                      onChanged: (value) => _toggle(module, canUpdate: value),
                    ),
                  ),
                  DataCell(
                    Checkbox(
                      value: entry?.canList ?? true,
                      onChanged: (value) => _toggle(module, canList: value),
                    ),
                  ),
                  DataCell(
                    Checkbox(
                      value: entry?.canDelete ?? true,
                      onChanged: (value) => _toggle(module, canDelete: value),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isEditing ? 'Editar permissoes' : 'Cadastrar permissoes',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.22)),
          ),
          child: _buildUserField(),
        ),
        const SizedBox(height: 20),
        _buildMatrixTable(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    widget.isEditing ? 'Salvar alteracoes' : 'Cadastrar permissoes',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }
}
