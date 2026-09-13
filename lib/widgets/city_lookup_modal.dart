import 'package:app_front_mobile/services/city_service.dart';
import 'package:app_front_mobile/services/state_service.dart';
import 'package:app_front_mobile/widgets/common/lookup_dialog_shell.dart';
import 'package:flutter/material.dart';

class CityLookupModal {
  const CityLookupModal._();

  static Future<CityOption?> show({
    required BuildContext context,
    required CityService service,
    required StateOption state,
    CityOption? selectedCity,
  }) {
    return showDialog<CityOption>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (_) => _CityLookupDialog(
        service: service,
        state: state,
        selectedCity: selectedCity,
      ),
    );
  }
}

class _CityLookupDialog extends StatefulWidget {
  final CityService service;
  final StateOption state;
  final CityOption? selectedCity;

  const _CityLookupDialog({
    required this.service,
    required this.state,
    required this.selectedCity,
  });

  @override
  State<_CityLookupDialog> createState() => _CityLookupDialogState();
}

class _CityLookupDialogState extends State<_CityLookupDialog> {
  final _searchController = TextEditingController();

  List<CityOption> _cities = [];

  bool _loading = true;

  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await widget.service.findCitiesByState(
        state: widget.state.abbreviation,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _cities = cities;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  List<CityOption> get _filteredCities {
    final search = _searchController.text.trim().toLowerCase();

    if (search.isEmpty) {
      return _cities;
    }

    return _cities.where((city) {
      return city.name.toLowerCase().contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LookupDialogShell(
      title: 'Selecionar cidade - ${widget.state.abbreviation}',
      maxWidth: 680,
      maxHeight: 660,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              enabled: !_loading,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar cidade',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(child: _buildContent(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: colorScheme.error),
              const SizedBox(height: 12),
              const Text(
                'Não foi possível carregar as cidades.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadCities,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final items = _filteredCities;

    if (items.isEmpty) {
      return const Center(child: Text('Nenhuma cidade encontrada.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final city = items[index];

        final selected =
            widget.selectedCity?.name.toLowerCase() == city.name.toLowerCase();

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.primary.withOpacity(0.12),
            child: Icon(
              Icons.location_city_outlined,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(city.name),
          trailing: selected
              ? Icon(Icons.check, color: colorScheme.primary)
              : const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).pop(city),
        );
      },
    );
  }
}
