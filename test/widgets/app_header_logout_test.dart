import 'dart:convert';

import 'package:app_front_mobile/config/api_client.dart';
import 'package:app_front_mobile/utils/auth_session.dart';
import 'package:app_front_mobile/widgets/app_header.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

/// Fake backend for the two calls AuthSession.refreshProfile() makes while
/// logged in: /profile/me and /permission/me.
class _FakeBackendAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final Object body = options.path.endsWith('/profile/me')
        ? {'userId': '1', 'name': 'Gabriel Vieira', 'role': 'MASTER_ADMIN'}
        : <String, dynamic>{};

    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// JWT with an `exp` far in the future, so TokenStorage.isAccessTokenValid()
/// treats the session as logged in (the signature is never checked locally).
String _validJwt() {
  String part(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

  return '${part({'alg': 'HS256'})}.${part({'exp': 4102444800})}.sig';
}

class _PageWithHeader extends StatelessWidget {
  final String label;
  final Widget? next;

  const _PageWithHeader({required this.label, this.next});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: Column(
        children: [
          Text(label),
          if (next != null)
            ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => next!)),
              child: const Text('abrir'),
            ),
        ],
      ),
    );
  }
}

/// Regression: logging out from a page stacked on top of the home page
/// (admin module, profile, my appointments...) must take the user back to
/// the home page instead of leaving the logged-in page on screen.
void main() {
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storage = <String, String>{};
  late HttpClientAdapter originalAdapter;

  setUp(() {
    storage
      ..clear()
      ..['access_token'] = _validJwt();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final key = args['key'] as String?;

          switch (call.method) {
            case 'read':
              return storage[key];
            case 'write':
              storage[key!] = args['value'] as String;
              return null;
            case 'delete':
              storage.remove(key);
              return null;
          }
          return null;
        });

    originalAdapter = ApiClient.dio.httpClientAdapter;
    ApiClient.dio.httpClientAdapter = _FakeBackendAdapter();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
    ApiClient.dio.httpClientAdapter = originalAdapter;
    AuthSession.cachedFirstName = null;
    AuthSession.cachedRole = null;
  });

  testWidgets('logout from a pushed page returns to the home page logged out', (
    tester,
  ) async {
    await useDesktopTestSurface(tester);

    await tester.pumpWidget(
      testApp(
        const _PageWithHeader(
          label: 'pagina inicial',
          next: _PageWithHeader(label: 'pagina logada'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('pagina logada'), findsOneWidget);
    expect(AuthSession.cachedRole, 'MASTER_ADMIN');

    // Open the logged-in user menu and pick "Sair".
    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('pagina logada'), findsNothing);
    expect(find.text('pagina inicial'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(storage.containsKey('access_token'), isFalse);
    expect(AuthSession.cachedRole, isNull);
  });
}
