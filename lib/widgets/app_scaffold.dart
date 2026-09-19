import 'package:app_front_mobile/widgets/app_footer.dart';
import 'package:app_front_mobile/widgets/app_header.dart';
import 'package:flutter/material.dart';

/// Standard page shell: the shared [AppHeader] as the app bar, the page's own
/// [body] (scrollable content stays scrollable, the footer doesn't), and the
/// shared [AppFooter] pinned at the bottom. Every screen should build on top
/// of this instead of a bare [Scaffold] so the header/footer stay identical
/// and in sync across the app.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final AppHeaderRoute currentRoute;

  const AppScaffold({
    super.key,
    required this.body,
    this.currentRoute = AppHeaderRoute.none,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(currentRoute: currentRoute),
      body: Column(
        children: [
          Expanded(child: body),
          const AppFooter(),
        ],
      ),
    );
  }
}
