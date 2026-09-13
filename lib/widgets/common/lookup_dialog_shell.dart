import 'package:flutter/material.dart';

/// Shared header for the "lookup" dialogs (city, state, ...): a title with
/// a close button, matching the style every lookup dialog used to redefine
/// on its own.
class LookupDialogHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const LookupDialogHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.18)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}

/// Shared dialog shell for "lookup" modals (search + pick one item from a
/// list). Wraps [child] with the same [Dialog] sizing/coloring and a
/// [LookupDialogHeader] every lookup dialog used to rebuild by hand.
///
/// [child] is expected to lay out its own search field followed by an
/// [Expanded] results area (see [CityLookupModal]/[StateLookupModal]) -
/// this shell only owns the header and the outer dialog frame.
class LookupDialogShell extends StatelessWidget {
  final String title;
  final Widget child;
  final double maxWidth;
  final double maxHeight;

  const LookupDialogShell({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 680,
    this.maxHeight = 660,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: isDark ? const Color(0xFF15171D) : colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Column(
          children: [
            LookupDialogHeader(
              title: title,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
