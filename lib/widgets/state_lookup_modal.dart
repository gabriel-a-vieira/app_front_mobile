import 'package:app_front_mobile/services/state_service.dart';
import 'package:app_front_mobile/widgets/common/lookup_dialog_shell.dart';
import 'package:flutter/material.dart';

class StateLookupModal {
  const StateLookupModal._();

  static Future<StateOption?> show({
    required BuildContext context,
    required List<StateOption> states,
    StateOption? selectedState,
  }) {
    return showDialog<StateOption>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (_) =>
          _StateLookupDialog(states: states, selectedState: selectedState),
    );
  }
}

class _StateLookupDialog extends StatefulWidget {
  final List<StateOption> states;
  final StateOption? selectedState;

  const _StateLookupDialog({required this.states, required this.selectedState});

  @override
  State<_StateLookupDialog> createState() => _StateLookupDialogState();
}

class _StateLookupDialogState extends State<_StateLookupDialog> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StateOption> get _filteredStates {
    final search = _searchController.text.trim().toLowerCase();

    final items = [...widget.states];

    items.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );

    if (search.isEmpty) {
      return items;
    }

    return items.where((state) {
      return state.label.toLowerCase().contains(search) ||
          state.abbreviation.toLowerCase().contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final items = _filteredStates;

    return LookupDialogShell(
      title: 'Selecionar UF',
      maxWidth: 620,
      maxHeight: 620,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar por estado ou sigla',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Nenhuma UF encontrada.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final state = items[index];

                      final selected =
                          widget.selectedState?.abbreviation.toUpperCase() ==
                          state.abbreviation.toUpperCase();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withOpacity(
                            0.12,
                          ),
                          child: Text(
                            state.abbreviation,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(state.label),
                        trailing: selected
                            ? Icon(Icons.check, color: colorScheme.primary)
                            : const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).pop(state),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
