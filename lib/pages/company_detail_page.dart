import 'package:app_front_mobile/services/company_service.dart';
import 'package:flutter/material.dart';

class CompanyDetailPage extends StatelessWidget {
  final CompanySummary company;

  const CompanyDetailPage({
    super.key,
    required this.company,
  });

  String get _displayName {
    if (company.tradeName.trim().isNotEmpty) {
      return company.tradeName.trim();
    }

    return company.legalName.trim();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.arrow_back),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 980;

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 20),
                      _buildMainImage(context),
                      const SizedBox(height: 16),
                      _buildTabs(context),
                      const SizedBox(height: 28),
                      _buildComodidadesSection(context),
                      const SizedBox(height: 28),
                      _buildSidebar(context),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 18),
                          _buildMainImage(context),
                          const SizedBox(height: 16),
                          _buildTabs(context),
                          const SizedBox(height: 28),
                          _buildComodidadesSection(context),
                        ],
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 4,
                      child: _buildSidebar(context),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary.withOpacity(0.12),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.35),
            ),
          ),
          child: Icon(
            Icons.storefront,
            color: colorScheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _displayName,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(0xFFFFB800),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '5.0',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.75),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF181B22)
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              color: Color(0xFFE34B4B),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 42,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9F38),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Agendar agora'),
          ),
        ),
      ],
    );
  }

  Widget _buildMainImage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 410,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1116) : const Color(0xFFEDEFF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.18),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            ),
            const SizedBox(height: 14),
            Text(
              'Imagem do estabelecimento',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _displayName,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.52),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    final tabs = [
      'Serviços',
      'Profissionais',
      'Fidelidade',
      'Produtos',
      'Pacotes',
      'Assinaturas',
      'Avaliações',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: tabs.map((tab) {
            final selected = tab == 'Serviços';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tab,
                  style: TextStyle(
                    color: selected
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.78),
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (selected)
                  Container(
                    width: 48,
                    height: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Divider(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.22),
          height: 1,
        ),
      ],
    );
  }

  Widget _buildComodidadesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comodidades',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Clique no item para obter informações',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.62),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final itemWidth = width >= 760
                ? (width - 36) / 4
                : width >= 480
                    ? (width - 12) / 2
                    : width;

            final items = [
              (
                icon: Icons.wifi,
                label: 'Wi-fi',
              ),
              (
                icon: Icons.local_parking,
                label: 'Estacionamento',
              ),
              (
                icon: Icons.accessible,
                label: 'Acessibilidade',
              ),
              (
                icon: Icons.child_friendly,
                label: 'Atende crianças',
              ),
            ];

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items.map((item) {
                return SizedBox(
                  width: itemWidth,
                  child: _AmenityCard(
                    icon: item.icon,
                    label: item.label,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171920) : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationSection(context),
          _sidebarDivider(context),
          _buildOpeningHoursSection(context),
          _sidebarDivider(context),
          _buildPaymentSection(context),
          _sidebarDivider(context),
          _buildSocialSection(context),
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Localização',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Avenida Firmino da Silva 484, 484 - 89209-224 Parque Guarani - Joinville/SC',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.76),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          child: const Icon(Icons.navigation_outlined),
        ),
      ],
    );
  }

  Widget _buildOpeningHoursSection(BuildContext context) {
    final hours = [
      ('Segunda-Feira', '09:00 - 12:00', '13:00 - 18:00', true),
      ('Terça-Feira', '09:00 - 12:00', '14:00 - 20:30', false),
      ('Quarta-Feira', '09:00 - 12:00', '14:00 - 20:30', false),
      ('Quinta-Feira', '09:00 - 12:00', '14:00 - 20:30', false),
      ('Sexta-Feira', '09:00 - 12:00', '14:00 - 20:30', false),
      ('Sábado', '08:00 - 12:00', '13:00 - 17:00', false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horário de atendimento',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        ...hours.map((hour) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        hour.$1,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      if (hour.$4)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E8F59).withOpacity(0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Hoje',
                            style: TextStyle(
                              color: Color(0xFF2EC27E),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hour.$2,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.78),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hour.$3,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.78),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    final payments = [
      'Dinheiro',
      'Cartão de Crédito',
      'Cartão de Débito',
      'PIX',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Formas de pagamento',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: payments.map((payment) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF232732)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                payment,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSocialSection(BuildContext context) {
    final icons = [
      Icons.camera_alt_outlined,
      Icons.language,
      Icons.facebook_outlined,
      Icons.music_note,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Redes Sociais',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: icons.map((icon) {
            return Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF232732)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _sidebarDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Divider(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.18),
        height: 1,
      ),
    );
  }
}

class _AmenityCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AmenityCard({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12151C) : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
            color: colorScheme.onSurface.withOpacity(0.75),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.85),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}