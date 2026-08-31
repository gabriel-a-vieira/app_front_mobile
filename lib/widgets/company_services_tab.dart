import 'package:app_front_mobile/services/public_company_service.dart';
import 'package:flutter/material.dart';

class CompanyServicesTab extends StatefulWidget {
  final String companyId;

  final void Function(PublicCompanyServiceOption service) onSchedule;

  const CompanyServicesTab({
    super.key,
    required this.companyId,
    required this.onSchedule,
  });

  @override
  State<CompanyServicesTab> createState() => _CompanyServicesTabState();
}

class _CompanyServicesTabState extends State<CompanyServicesTab> {
  final _service = PublicCompanyService(
    baseUrl: 'http://localhost:8081/public/company',
  );

  bool _loading = true;

  List<PublicCompanyServiceOption> _services = [];

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _service.findServices(companyId: widget.companyId);

      if (!mounted) return;

      setState(() {
        _services = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
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

    if (_loading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_services.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('Nenhum serviço disponível')),
      );
    }

    return Column(
      children: _services.map((service) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colorScheme.outline.withOpacity(0.18)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withOpacity(0.12),
                ),
                child: Icon(
                  Icons.design_services_outlined,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    if (service.description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        service.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.62),
                          fontSize: 13,
                        ),
                      ),
                    ],

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 15,
                          color: colorScheme.onSurface.withOpacity(0.65),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${service.durationMinutes} min',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              Text(
                _price(service.price),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(width: 18),

              SizedBox(
                height: 38,
                child: FilledButton(
                  onPressed: () => widget.onSchedule(service),
                  child: const Text('Agendar'),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
