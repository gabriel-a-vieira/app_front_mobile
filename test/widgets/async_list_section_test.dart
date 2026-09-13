import 'package:app_front_mobile/widgets/common/async_list_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// First widget-test example for the project (there was none before this -
/// only the untouched default counter-app test, which no longer matched
/// this app and was failing). AsyncListSection was picked because it's a
/// small, self-contained presentational widget with no network/service
/// dependency, making it a good template for testing the rest of
/// lib/widgets/common going forward.
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('shows a spinner and hides content while loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        AsyncListSection(
          loading: true,
          hasError: false,
          errorLabel: 'Erro ao buscar clientes',
          onRetry: () {},
          content: const Text('client list'),
          hasMore: false,
          loadingMore: false,
          onLoadMore: () {},
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('client list'), findsNothing);
  });

  testWidgets('shows the error label and invokes onRetry when tapped', (
    tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      wrap(
        AsyncListSection(
          loading: false,
          hasError: true,
          errorLabel: 'Erro ao buscar clientes',
          onRetry: () => retried = true,
          content: const Text('client list'),
          hasMore: false,
          loadingMore: false,
          onLoadMore: () {},
        ),
      ),
    );

    expect(find.text('Erro ao buscar clientes'), findsOneWidget);
    expect(find.text('client list'), findsNothing);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    expect(retried, isTrue);
  });

  testWidgets('shows content and a load-more button when hasMore is true', (
    tester,
  ) async {
    var loadedMore = false;

    await tester.pumpWidget(
      wrap(
        AsyncListSection(
          loading: false,
          hasError: false,
          errorLabel: 'Erro ao buscar clientes',
          onRetry: () {},
          content: const Text('client list'),
          hasMore: true,
          loadingMore: false,
          onLoadMore: () => loadedMore = true,
        ),
      ),
    );

    expect(find.text('client list'), findsOneWidget);
    expect(find.text('Carregar mais'), findsOneWidget);

    await tester.tap(find.text('Carregar mais'));
    await tester.pump();

    expect(loadedMore, isTrue);
  });

  testWidgets('hides the load-more button when hasMore is false', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        AsyncListSection(
          loading: false,
          hasError: false,
          errorLabel: 'Erro ao buscar clientes',
          onRetry: () {},
          content: const Text('client list'),
          hasMore: false,
          loadingMore: false,
          onLoadMore: () {},
        ),
      ),
    );

    expect(find.text('client list'), findsOneWidget);
    expect(find.text('Carregar mais'), findsNothing);
  });
}
