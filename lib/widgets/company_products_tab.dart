import 'package:app_front_mobile/services/public_product_service.dart';
import 'package:flutter/material.dart';

class CompanyProductsTab extends StatefulWidget {
  final String companyId;

  const CompanyProductsTab({super.key, required this.companyId});

  @override
  State<CompanyProductsTab> createState() => _CompanyProductsTabState();
}

class _CompanyProductsTabState extends State<CompanyProductsTab> {
  final _service = PublicProductService(
    baseUrl: 'http://localhost:8081/public/company',
  );

  bool _loading = true;

  List<PublicProduct> _products = [];

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _service.findProducts(companyId: widget.companyId);

      if (!mounted) return;

      setState(() {
        _products = result;

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  String _money(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_products.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('Nenhum produto disponível')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 800
            ? 3
            : constraints.maxWidth >= 520
            ? 2
            : 1;

        final spacing = 12.0;

        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _products.map((product) {
            return SizedBox(
              width: itemWidth,
              child: _ProductCard(product: product, money: _money),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final PublicProduct product;

  final String Function(double) money;

  const _ProductCard({required this.product, required this.money});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final available = product.stockQuantity > 0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11141B) : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.35,
            child: Image.network(
              product.imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: colorScheme.onSurface.withOpacity(0.45),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 6),

                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        money(product.price),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: available
                            ? const Color(0xFF2EAD72).withOpacity(0.12)
                            : colorScheme.error.withOpacity(0.12),
                      ),
                      child: Text(
                        available ? 'Disponível' : 'Indisponível',
                        style: TextStyle(
                          color: available
                              ? const Color(0xFF2EAD72)
                              : colorScheme.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
