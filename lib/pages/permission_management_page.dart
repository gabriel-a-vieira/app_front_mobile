import 'package:app_front_mobile/config/api_config.dart';
import 'package:app_front_mobile/models/system_module.dart';
import 'package:app_front_mobile/services/permission_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:flutter/material.dart';

/// MASTER_ADMIN-only screen to parametrize, per role, which CRUD actions are
/// allowed on each system module. New modules show up here automatically as
/// soon as they're added to SystemModule (Dart) + SystemModule (Java) --
/// nothing else needs to change on this screen.
class PermissionManagementPage extends StatefulWidget {
  const PermissionManagementPage({super.key});

  @override
  State<PermissionManagementPage> createState() =>
      _PermissionManagementPageState();
}

const _configurableRoles = <String, String>{
  'COMPANY_ADMIN': 'Administrador da empresa',
  'PROFESSIONAL': 'Profissional',
};

class _PermissionManagementPageState extends State<PermissionManagementPage> {
  final _permissionService = PermissionService(
    baseUrl: '${ApiConfig.baseUrl}/permission',
  );

  final _tokenStorage = TokenStorage();

  List<RolePermissionEntry> _entries = [];

  String _selectedRole = 'COMPANY_ADMIN';

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMatrix();
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
      final entries = await _permissionService.findMatrix(token: token);

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

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });

    try {
      final token = await _getToken();

      await _permissionService.updateMatrix(token: token, entries: _entries);

      if (!mounted) return;

      AppMessage.success(context, 'Permissoes atualizadas com sucesso');
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(context, e, fallback: 'Erro ao salvar permissoes');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _toggle(SystemModule module, {
    bool? canCreate,
    bool? canUpdate,
    bool? canList,
    bool? canDelete,
  }) {
    setState(() {
      _entries = _entries.map((entry) {
        if (entry.role != _selectedRole || entry.module != module) {
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

  RolePermissionEntry? _entryFor(SystemModule module) {
    for (final entry in _entries) {
      if (entry.role == _selectedRole && entry.module == module) {
        return entry;
      }
    }

    return null;
  }

  Widget _buildRoleSelector() {
    return SegmentedButton<String>(
      segments: _configurableRoles.entries
          .map(
            (entry) => ButtonSegment(value: entry.key, label: Text(entry.value)),
          )
          .toList(),
      selected: {_selectedRole},
      onSelectionChanged: (selection) {
        setState(() {
          _selectedRole = selection.first;
        });
      },
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissoes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Defina, por funcao, o que cada role pode fazer em cada modulo do cadastro.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  _buildRoleSelector(),
                  const SizedBox(height: 20),
                  _buildTable(),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Salvar',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
