import 'package:app_front_mobile/services/client_lookup_service.dart';
import 'package:app_front_mobile/widgets/common/single_select_lookup_dialog.dart';
import 'package:flutter/material.dart';

class ClientLookupModal {
  const ClientLookupModal._();

  static Future<ClientLookupOption?> show({
    required BuildContext context,
    required String token,
    required ClientLookupService service,
    String companyId = '',
  }) {
    return showDialog<ClientLookupOption>(
      context: context,
      builder: (_) => SingleSelectLookupDialog<ClientLookupOption>(
        title: 'Selecionar cliente',
        searchHint: 'Buscar por nome ou CPF',
        errorLabel: 'Erro ao buscar clientes',
        emptyLabel: 'Nenhum cliente encontrado',
        columns: [
          LookupColumn(
            label: 'Cliente',
            flex: 3,
            cellBuilder: (client) =>
                Text(client.name, overflow: TextOverflow.ellipsis),
          ),
          LookupColumn(
            label: 'CPF',
            flex: 2,
            cellBuilder: (client) => Text(_formatCpf(client.cpfCnpj)),
          ),
        ],
        loadPage: ({required page, required search}) async {
          final result = await service.findClients(
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
