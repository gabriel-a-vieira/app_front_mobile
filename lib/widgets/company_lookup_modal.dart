import 'package:app_front_mobile/services/company_lookup_service.dart';
import 'package:app_front_mobile/widgets/common/single_select_lookup_dialog.dart';
import 'package:flutter/material.dart';

class CompanyLookupModal {
  const CompanyLookupModal._();

  static Future<CompanyLookupOption?> show({
    required BuildContext context,
    String? token,
    required CompanyLookupService service,
  }) {
    return showDialog<CompanyLookupOption>(
      context: context,
      builder: (_) => SingleSelectLookupDialog<CompanyLookupOption>(
        title: 'Selecionar empresa',
        searchHint: 'Buscar por nome, razao social ou CNPJ',
        errorLabel: 'Erro ao buscar empresas',
        emptyLabel: 'Nenhuma empresa encontrada',
        columns: [
          LookupColumn(
            label: 'Empresa',
            flex: 3,
            cellBuilder: (company) => Text(
              company.displayName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          LookupColumn(
            label: 'CNPJ',
            flex: 2,
            cellBuilder: (company) => Text(
              company.cnpj.isEmpty ? '-' : company.cnpj,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          LookupColumn(
            label: 'Tipo',
            flex: 2,
            cellBuilder: (company) => Text(
              company.type.isEmpty ? '-' : company.type,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        loadPage: ({required page, required search}) async {
          final result = await service.findCompanies(
            token: token,
            page: page,
            size: 10,
            search: search,
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
