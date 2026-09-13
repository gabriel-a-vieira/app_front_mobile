import 'package:flutter/material.dart';

/// One column of a [SingleSelectLookupDialog]'s table: a header label and
/// how to render that column for a given row.
class LookupColumn<T> {
  final String label;
  final int flex;
  final Widget Function(T item) cellBuilder;

  const LookupColumn({
    required this.label,
    required this.flex,
    required this.cellBuilder,
  });
}

/// One page of lookup results, shaped like the paginated response every
/// lookup service already returns (content/number/totalPages/first/last).
class LookupPage<T> {
  final List<T> items;
  final int number;
  final int totalPages;
  final bool first;
  final bool last;

  const LookupPage({
    required this.items,
    required this.number,
    required this.totalPages,
    required this.first,
    required this.last,
  });
}

/// Shared single-select "lookup" dialog: search field, paginated table and
/// a Cancelar action, resolving with the tapped row.
///
/// `ClientLookupModal`, `CompanyLookupModal` and `ProfessionalLookupModal`
/// each rebuilt this exact shape by hand - search field, results table with
/// a fixed-height viewport, pagination footer - with only the title, search
/// hint, table columns and the page-loading call actually differing. This
/// widget is that shared shape; each modal now only supplies those four
/// things.
///
/// `ServiceOfferingLookupModal` is intentionally NOT built on this: it is a
/// multi-select checkbox list with a Confirmar action, a genuinely
/// different interaction, not just a styling difference.
class SingleSelectLookupDialog<T> extends StatefulWidget {
  final String title;
  final String searchHint;
  final List<LookupColumn<T>> columns;
  final Future<LookupPage<T>> Function({required int page, required String search})
  loadPage;
  final String errorLabel;
  final String emptyLabel;

  const SingleSelectLookupDialog({
    super.key,
    required this.title,
    required this.searchHint,
    required this.columns,
    required this.loadPage,
    required this.errorLabel,
    required this.emptyLabel,
  });

  @override
  State<SingleSelectLookupDialog<T>> createState() =>
      _SingleSelectLookupDialogState<T>();
}

class _SingleSelectLookupDialogState<T>
    extends State<SingleSelectLookupDialog<T>> {
  static const double _contentHeight = 330;

  final _searchController = TextEditingController();

  List<T> _items = [];

  bool _loading = true;
  Object? _error;

  int _page = 0;
  int _totalPages = 1;
  bool _first = true;
  bool _last = true;

  @override
  void initState() {
    super.initState();
    _load(page: 0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({required int page}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.loadPage(
        page: page,
        search: _searchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _items = result.items;
        _page = result.number;
        _totalPages = result.totalPages;
        _first = result.first;
        _last = result.last;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF171A22) : null,
      title: Text(widget.title),
      content: SizedBox(
        width: 760,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              onSubmitted: (_) => _load(page: 0),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () => _load(page: 0),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(height: _contentHeight, child: _buildContent()),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Pagina ${_page + 1} de $_totalPages'),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _first ? null : () => _load(page: _page - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: _last ? null : () => _load(page: _page + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          widget.errorLabel,
          style: TextStyle(
            color: colorScheme.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(child: Text(widget.emptyLabel));
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11141B) : colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withOpacity(0.22)),
      ),
      child: Column(
        children: [
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: widget.columns
                  .map(
                    (column) => Expanded(
                      flex: column.flex,
                      child: Text(
                        column.label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _items[index];

                return InkWell(
                  onTap: () => Navigator.of(context).pop(item),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: widget.columns
                          .map(
                            (column) => Expanded(
                              flex: column.flex,
                              child: column.cellBuilder(item),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
