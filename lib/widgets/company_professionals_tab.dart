import 'package:app_front_mobile/services/public_company_service.dart';
import 'package:flutter/material.dart';

class CompanyProfessionalsTab extends StatefulWidget {
  final String companyId;

  final void Function(PublicCompanyProfessional professional) onViewSchedule;

  const CompanyProfessionalsTab({
    super.key,
    required this.companyId,
    required this.onViewSchedule,
  });

  @override
  State<CompanyProfessionalsTab> createState() =>
      _CompanyProfessionalsTabState();
}

class _CompanyProfessionalsTabState extends State<CompanyProfessionalsTab> {
  final _service = PublicCompanyService(
    baseUrl: 'http://localhost:8081/public/company',
  );

  bool _loading = true;

  List<PublicCompanyProfessional> _professionals = [];

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _service.findProfessionals(
        companyId: widget.companyId,
      );

      if (!mounted) return;

      setState(() {
        _professionals = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
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

    if (_professionals.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('Nenhum profissional disponivel')),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _professionals.map((professional) {
        return Container(
          width: 230,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF11141B)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outline.withOpacity(0.22)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primary.withOpacity(0.14),
                child: Icon(
                  Icons.person_outline,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                professional.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton(
                  onPressed: () => widget.onViewSchedule(professional),
                  child: const Text('Ver horarios'),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
