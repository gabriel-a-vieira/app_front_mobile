# app_front_mobile — Frontend/Mobile do Schedule App

Contexto geral do produto em `../CLAUDE.md`. Este arquivo cobre convenções e problemas específicos do frontend Flutter.

**Contexto importante:** boa parte deste código foi construído com bem menos domínio de Flutter/Dart do que o backend em Java — funcional, mas com bastante divergência visual e duplicação entre telas. As regras abaixo existem para corrigir isso daqui pra frente, não para justificar uma reescrita geral.

## Stack

Flutter (Dart SDK `^3.11.0`), `go_router`, `dio` (HTTP), `provider` (state para tema/idioma), `flutter_secure_storage` (token), `google_sign_in`, `flutter_localizations` + `l10n.yaml` (PT/EN configurados).

## Estrutura atual

- `lib/pages/` — uma tela por arquivo, geralmente `<entidade>_management_page.dart` (listagem/CRUD) + `<entidade>_form_page.dart` (criar/editar).
- `lib/widgets/` — modais de busca/seleção (`*_lookup_modal.dart`), tabs de detalhe de empresa (`company_*_tab.dart`), botão de login Google.
- `lib/services/` — um arquivo por entidade/feature, espelhando os módulos do backend. Cada Service encapsula um `Dio` e monta a URL/headers manualmente.
- `lib/storage/token_storage.dart`, `lib/utils/` (`api_error_handler.dart`, `app_message.dart`, `input_formatters.dart`, `auth_gate.dart`).

Esse espelhamento Service↔feature do backend é bom e deve continuar quando uma feature nova nascer.

## Problemas concretos já identificados (evidência real do código, não achismo)

1. **Navegação inconsistente.** `app_router.dart` define `buildRouter()` com `go_router`, e `main.dart` até instancia esse router (`final GoRouter router = buildRouter();`) — mas o `MaterialApp` usa `home: const HomePage()`, não `MaterialApp.router(routerConfig: router)`. O router construído **nunca é usado**. Toda navegação real acontece via `Navigator.of(context).push(MaterialPageRoute(...))` espalhado pelas páginas. Duas abordagens de navegação coexistindo, só uma funcionando de fato.
2. **Duplicação real entre os modais de lookup.** `city_lookup_modal.dart` e `state_lookup_modal.dart` (provável padrão nos outros `*_lookup_modal.dart` também) repetem um widget privado `_Header` **idêntico** — mesmo layout, mesma altura, mesmo botão de fechar — cada um copiado à mão no seu arquivo. É exatamente a divergência que você descreveu.
3. **Cores/estilos hardcoded por arquivo.** Valores hex de dark mode (`0xFF171A22`, `0xFF11141B`, `0xFF1C212B`, `0xFF15171D`, ...), raios de borda (8/12), tamanhos de fonte (13/14/17) aparecem soltos, repetidos, dentro de cada page/modal — não vêm de um `ThemeData`/tokens central.
4. **Base URL da API hardcoded por página.** Ex.: `ClientService(baseUrl: 'http://localhost:8081/client')` é instanciado dentro do `State` da própria `ClientManagementPage`. Não há config de ambiente (dev/staging/prod) — trocar de ambiente exigiria editar código em N arquivos.
5. **Header de autenticação repetido manualmente.** Todo método de todo Service repete `options: Options(headers: {'Authorization': 'Bearer $token'})`. Não há um `Dio` compartilhado com interceptor que injete o token automaticamente.
6. **`AppLocalizations` configurado mas não usado.** PT/EN estão plugados em `main.dart`, mas nenhuma tela usa `AppLocalizations.of(context)` — todo texto de UI é string literal em português direto no widget. A infraestrutura de i18n existe só "de decoração".
7. **Tratamento de erro inconsistente.** Em vários lugares (`ClientManagementPage._loadClients`, por exemplo) o erro exibido é `e.toString()` cru, enquanto `ApiErrorHandler.getMessage(e)` já existe e traduz códigos HTTP para mensagens amigáveis em PT-BR — só não é chamado sempre.
8. **Sem testes** além do `test/widget_test.dart` padrão do template Flutter (não customizado).
9. **Lógica de dados dentro do `State` de cada página.** `Provider` só é usado para tema/idioma; fetch, paginação, filtros e seleção múltipla são reimplementados via `setState` em cada `*_management_page.dart` — funciona, mas cada tela reconstrói o mesmo esqueleto (loading/erro/paginação "carregar mais") do zero.

## Regras para código novo a partir de agora

1. **Antes de criar um modal/lookup novo**, veja se dá pra extrair uma base comum (`lib/widgets/common/lookup_dialog_shell.dart` com header + busca + lista genéricos) em vez de copiar um `*_lookup_modal.dart` existente e trocar os nomes.
2. **Cores, raios e tamanhos de fonte de dark/light mode** devem vir de um `AppTheme`/arquivo de design tokens central — não escrever hex literal novo em um widget. Se esse arquivo ainda não existir quando for necessário, é um bom momento para criá-lo a partir dos valores já espalhados hoje (unificando, não inventando um novo padrão).
3. **Toda `*_management_page.dart` nova** deve seguir a mesma estrutura das existentes (header com título+ações, busca, grid/lista, "carregar mais") — copie a estrutura de uma página existente como `client_management_page.dart`. Se for a 3ª ou 4ª página repetindo esse esqueleto, é o momento de extrair um widget/mixin base em vez de copiar de novo.
4. **Sempre usar `ApiErrorHandler.getMessage(e)`** para mostrar erro ao usuário — nunca `e.toString()` diretamente numa tela.
5. **Não hardcode a base URL da API** dentro de uma página/Service. Centralize (ex.: `lib/config/api_config.dart`) antes de adicionar mais um Service com URL fixa.
6. **Se for tocar em navegação**, decida explicitamente: ou adota `go_router` de fato (`MaterialApp.router`, rotas nomeadas, guard de autenticação) ou remove `buildRouter()`/`app_router.dart` morto. Não deixe os dois construídos como está hoje.
7. **Se for tocar em um novo `Service` HTTP**, use (ou crie, se ainda não existir) um `Dio` compartilhado com interceptor de `Authorization`, em vez de repetir `Options(headers: {...})` em cada método.
8. **Texto de UI:** hoje é PT-BR hardcoded mesmo com `AppLocalizations` configurado. Antes de usar `AppLocalizations.of(context)` num arquivo novo, confirme com o usuário se a decisão é adotar i18n de verdade agora ou manter PT-BR direto por enquanto — não misturar as duas abordagens no mesmo arquivo.
