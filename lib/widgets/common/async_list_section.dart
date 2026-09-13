import 'package:flutter/material.dart';

/// Shared loading -> error -> content(+"load more") shell for the
/// `*_management_page.dart` list screens.
///
/// `ClientManagementPage`, `ProfessionalManagementPage` and
/// `ServiceOfferingManagementPage` each rebuilt this same spinner /
/// error-icon-with-retry / "Carregar mais" shape by hand, with only the
/// error label, the retry/load-more callbacks and the actual list content
/// differing.
///
/// Not every management page fits this shape - `AvailabilityManagementPage`
/// shows a plain error text with no retry action, and
/// `AppointmentManagementPage`/`HomePage` handle errors differently again
/// (snackbar, or a bilingual empty-state) - so this is intentionally scoped
/// to the three pages that already matched (or now match) this exact
/// pattern, not a catch-all for every list screen.
class AsyncListSection extends StatelessWidget {
  final bool loading;
  final bool hasError;
  final String errorLabel;
  final VoidCallback onRetry;
  final Widget content;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onLoadMore;

  const AsyncListSection({
    super.key,
    required this.loading,
    required this.hasError,
    required this.errorLabel,
    required this.onRetry,
    required this.content,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 42),
              const SizedBox(height: 12),
              Text(
                errorLabel,
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        content,
        if (hasMore) ...[
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              onPressed: loadingMore ? null : onLoadMore,
              child: loadingMore
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Carregar mais'),
            ),
          ),
        ],
      ],
    );
  }
}
