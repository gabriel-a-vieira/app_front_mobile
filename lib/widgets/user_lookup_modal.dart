import 'package:app_front_mobile/services/user_lookup_service.dart';
import 'package:app_front_mobile/widgets/common/single_select_lookup_dialog.dart';
import 'package:flutter/material.dart';

class UserLookupModal {
  const UserLookupModal._();

  static Future<UserLookupOption?> show({
    required BuildContext context,
    required String token,
    required UserLookupService service,
  }) {
    return showDialog<UserLookupOption>(
      context: context,
      builder: (_) => SingleSelectLookupDialog<UserLookupOption>(
        title: 'Selecionar usuario',
        searchHint: 'Buscar por nome ou email',
        errorLabel: 'Erro ao buscar usuarios',
        emptyLabel: 'Nenhum usuario encontrado',
        columns: [
          LookupColumn(
            label: 'Usuario',
            flex: 3,
            cellBuilder: (user) => Text(
              user.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          LookupColumn(
            label: 'Email',
            flex: 3,
            cellBuilder: (user) => Text(user.email, overflow: TextOverflow.ellipsis),
          ),
        ],
        loadPage: ({required page, required search}) async {
          final result = await service.findUsers(
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
