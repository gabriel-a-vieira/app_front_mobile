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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_services.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('Nenhum servico disponivel')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 700
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _services.map((service) {
            return Container(
              width: width,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF11141B)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (service.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      service.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 17,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 5),
                      Text('${service.durationMinutes} min'),
                      const Spacer(),
                      Text(
                        _price(service.price),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
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
      },
    );
  }
}
