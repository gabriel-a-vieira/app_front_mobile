import 'package:app_front_mobile/services/professional_lookup_service.dart';
import 'package:app_front_mobile/widgets/common/single_select_lookup_dialog.dart';
import 'package:flutter/material.dart';

class ProfessionalLookupModal {
  const ProfessionalLookupModal._();

  static Future<ProfessionalLookupOption?> show({
    required BuildContext context,
    required String token,
    required ProfessionalLookupService service,
    String companyId = '',
  }) {
    return showDialog<ProfessionalLookupOption>(
      context: context,
      builder: (_) => SingleSelectLookupDialog<ProfessionalLookupOption>(
        title: 'Selecionar profissional',
        searchHint: 'Buscar por nome ou CPF',
        errorLabel: 'Erro ao buscar profissionais',
        emptyLabel: 'Nenhum profissional encontrado',
        columns: [
          LookupColumn(
            label: 'Profissional',
            flex: 3,
            cellBuilder: (professional) => Text(
              professional.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          LookupColumn(
            label: 'CPF',
            flex: 2,
            cellBuilder: (professional) =>
                Text(_formatCpf(professional.cpfCnpj)),
          ),
        ],
        loadPage: ({required page, required search}) async {
          final result = await service.findProfessionals(
            token: token,
            page: page,
            size: 10,
            search: search,
            companyId: companyId,
          );

          return LookupPage(
            items: result.content,
            number: result.number,
            totalPages: result.totalPages,
            first: result.first,
            last: result.last,
          );
        },
      ),
    );
  }
}

String _formatCpf(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

  if (digits.length != 11) {
    return value;
  }

  return '${digits.substring(0, 3)}.'
      '${digits.substring(3, 6)}.'
      '${digits.substring(6, 9)}-'
      '${digits.substring(9)}';
}
