import 'package:app_front_mobile/services/public_company_service.dart';
import 'package:flutter/material.dart';

class CompanyProfessionalsTab extends StatefulWidget {
  final String companyId;

  const CompanyProfessionalsTab({super.key, required this.companyId});

  @override
  State<CompanyProfessionalsTab> createState() =>
      _CompanyProfessionalsTabState();
}

class _CompanyProfessionalsTabState extends State<CompanyProfessionalsTab> {
  final _service = PublicCompanyService(
    baseUrl: 'http://localhost:8081/public/company',
  );

  bool _loading = true;

  String? _error;

  List<PublicCompanyProfessional> _professionals = [];

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.findProfessionals(
        companyId: widget.companyId,
      );

      if (!mounted) return;

      setState(() {
        _professionals = result;
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

    if (_error != null) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Erro ao carregar profissionais.',
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (_professionals.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('Nenhum profissional disponível')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double itemWidth;

        if (constraints.maxWidth >= 760) {
          itemWidth = (constraints.maxWidth - 36) / 4;
        } else if (constraints.maxWidth >= 520) {
          itemWidth = (constraints.maxWidth - 12) / 2;
        } else {
          itemWidth = constraints.maxWidth;
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _professionals.map((professional) {
            return Container(
              width: itemWidth,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF11141B) : colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.18),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withOpacity(0.14),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.25),
                      ),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 32,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    professional.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
