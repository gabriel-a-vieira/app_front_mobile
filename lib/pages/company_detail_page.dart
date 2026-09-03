import 'package:app_front_mobile/services/company_service.dart';
import 'package:app_front_mobile/services/public_company_service.dart';
import 'package:app_front_mobile/services/company_review_service.dart';
import 'package:app_front_mobile/utils/auth_gate.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/widgets/company_services_tab.dart';
import 'package:app_front_mobile/widgets/company_professionals_tab.dart';
import 'package:app_front_mobile/widgets/company_reviews_tab.dart';
import 'package:app_front_mobile/widgets/service_booking_modal.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_front_mobile/widgets/company_products_tab.dart';

class CompanyDetailPage extends StatefulWidget {
  final CompanySummary company;

  const CompanyDetailPage({super.key, required this.company});

  @override
  State<CompanyDetailPage> createState() => _CompanyDetailPageState();
}

class _CompanyDetailPageState extends State<CompanyDetailPage> {
  final _companyReviewService = CompanyReviewService(
    baseUrl: 'http://localhost:8081',
  );

  final _publicCompanyService = PublicCompanyService(
    baseUrl: 'http://localhost:8081/public/company',
  );

  PublicCompanyDetail? _companyDetail;

  bool _loadingCompanyDetail = true;

  String _selectedTab = 'services';

  CompanyReviewSummary _reviewSummary = const CompanyReviewSummary(
    average: 0,
    total: 0,
  );

  bool _loadingReviewSummary = true;

  String get _displayName {
    if (widget.company.tradeName.trim().isNotEmpty) {
      return widget.company.tradeName.trim();
    }

    return widget.company.legalName.trim();
  }

  @override
  void initState() {
    super.initState();

    _loadCompanyDetail();
    _loadReviewSummary();
  }

  Future<void> _loadReviewSummary() async {
    try {
      final summary = await _companyReviewService.findSummary(
        companyId: widget.company.id,
      );

      if (!mounted) return;

      setState(() {
        _reviewSummary = summary;
        _loadingReviewSummary = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingReviewSummary = false;
      });
    }
  }

  Future<void> _loadCompanyDetail() async {
    try {
      final detail = await _publicCompanyService.findDetail(
        companyId: widget.company.id,
      );

      if (!mounted) return;

      setState(() {
        _companyDetail = detail;
        _loadingCompanyDetail = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingCompanyDetail = false;
      });
    }
  }

  Future<void> _openMainSchedule() async {
    final logged = await AuthGate.requireLogin(
      context,
      reason: 'Você precisa estar logado para realizar um agendamento.',
    );

    if (!logged || !mounted) {
      return;
    }

    setState(() {
      _selectedTab = 'services';
    });

    AppMessage.info(
      context,
      'Selecione um serviço para continuar o agendamento.',
    );
  }

  Future<void> _scheduleService(PublicCompanyServiceOption service) async {
    final logged = await AuthGate.requireLogin(
      context,
      reason: 'Você precisa estar logado para agendar este serviço.',
    );

    if (!logged || !mounted) {
      return;
    }

    final scheduled = await ServiceBookingModal.show(
      context: context,
      companyId: widget.company.id,
      companyName: _displayName,
      service: service,
    );

    if (scheduled == true && mounted) {
      AppMessage.success(context, 'Seu horário foi agendado.');
    }
  }

  /*
   * Abre o endereço da empresa no Google Maps.
   */
  Future<void> _openGoogleMaps() async {
    final address = _companyDetail?.address;

    if (address == null) {
      return;
    }

    String query;

    if (address.latitude != null && address.longitude != null) {
      query = '${address.latitude},${address.longitude}';
    } else {
      query = address.formattedAddress;
    }

    if (query.trim().isEmpty) {
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/'
      '?api=1&query=${Uri.encodeComponent(query)}',
    );

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      AppMessage.info(context, 'Não foi possível abrir o Google Maps.');
    }
  }

  /*
   * Método único para Instagram, Facebook,
   * Website e TikTok.
   *
   * Também aceita links cadastrados sem
   * "https://".
   */
  Future<void> _openExternalUrl(String? value) async {
    if (value == null || value.trim().isEmpty) {
      return;
    }

    String url = value.trim();

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);

    if (uri == null || !uri.hasScheme) {
      if (!mounted) return;

      AppMessage.info(context, 'Link inválido.');

      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        AppMessage.info(context, 'Não foi possível abrir o link.');
      }
    } catch (_) {
      if (!mounted) return;

      AppMessage.info(context, 'Não foi possível abrir o link.');
    }
  }

  void _selectTab(String key) {
    setState(() {
      _selectedTab = key;
    });
  }

  String _amenityLabel(String amenity) {
    switch (amenity) {
      case 'WIFI':
        return 'Wi-fi';

      case 'PARKING':
        return 'Estacionamento';

      case 'ACCESSIBILITY':
        return 'Acessibilidade';

      case 'CHILD_FRIENDLY':
        return 'Atende crianças';

      case 'AIR_CONDITIONING':
        return 'Ar-condicionado';

      case 'PET_FRIENDLY':
        return 'Aceita pets';

      default:
        return _formatEnumLabel(amenity);
    }
  }

  IconData _amenityIcon(String amenity) {
    switch (amenity) {
      case 'WIFI':
        return Icons.wifi;

      case 'PARKING':
        return Icons.local_parking;

      case 'ACCESSIBILITY':
        return Icons.accessible;

      case 'CHILD_FRIENDLY':
        return Icons.child_friendly;

      case 'AIR_CONDITIONING':
        return Icons.ac_unit;

      case 'PET_FRIENDLY':
        return Icons.pets_outlined;

      default:
        return Icons.check_circle_outline;
    }
  }

  /*
   * Caso um novo enum seja criado no backend
   * e ainda não exista tradução específica
   * no frontend, evita mostrar algo como:
   *
   * PRIVATE_ROOM
   *
   * e mostra:
   *
   * Private Room
   */
  String _formatEnumLabel(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return '';
    }

    final words = normalized
        .toLowerCase()
        .split('_')
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return normalized;
    }

    return words
        .map((word) {
          if (word.length == 1) {
            return word.toUpperCase();
          }

          return '${word[0].toUpperCase()}'
              '${word.substring(1)}';
        })
        .join(' ');
  }

  String _dayLabel(String day) {
    switch (day) {
      case 'MONDAY':
        return 'Segunda-Feira';

      case 'TUESDAY':
        return 'Terça-Feira';

      case 'WEDNESDAY':
        return 'Quarta-Feira';

      case 'THURSDAY':
        return 'Quinta-Feira';

      case 'FRIDAY':
        return 'Sexta-Feira';

      case 'SATURDAY':
        return 'Sábado';

      case 'SUNDAY':
        return 'Domingo';

      default:
        return day;
    }
  }

  String _todayDayWeek() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 'MONDAY';

      case DateTime.tuesday:
        return 'TUESDAY';

      case DateTime.wednesday:
        return 'WEDNESDAY';

      case DateTime.thursday:
        return 'THURSDAY';

      case DateTime.friday:
        return 'FRIDAY';

      case DateTime.saturday:
        return 'SATURDAY';

      case DateTime.sunday:
        return 'SUNDAY';

      default:
        return '';
    }
  }

  String _formatHour(String value) {
    if (value.length >= 5) {
      return value.substring(0, 5);
    }

    return value;
  }

  String _paymentLabel(String payment) {
    switch (payment) {
      case 'CASH':
        return 'Dinheiro';

      case 'PIX':
        return 'PIX';

      case 'BANK_TRANSFER':
        return 'Transferência bancária';

      case 'CREDIT_CARD':
        return 'Cartão de Crédito';

      case 'DEBIT_CARD':
        return 'Cartão de Débito';

      default:
        return _formatEnumLabel(payment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          _displayName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                      const SizedBox(height: 28),
                      _buildComodidadesSection(context),
                      const SizedBox(height: 32),
                      _buildTabs(context),
                      const SizedBox(height: 24),
                      _buildSelectedTabContent(),
                      const SizedBox(height: 32),
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
                          const SizedBox(height: 28),
                          _buildComodidadesSection(context),
                          const SizedBox(height: 32),
                          _buildTabs(context),
                          const SizedBox(height: 24),
                          _buildSelectedTabContent(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(flex: 4, child: _buildSidebar(context)),
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
            border: Border.all(color: colorScheme.primary.withOpacity(0.35)),
          ),
          child: Icon(Icons.storefront, color: colorScheme.primary, size: 28),
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

              _buildRatingHeader(context),
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
            child: const Icon(Icons.favorite_border, color: Color(0xFFE34B4B)),
          ),
        ),

        const SizedBox(width: 12),

        SizedBox(
          height: 42,
          child: ElevatedButton(
            onPressed: _openMainSchedule,
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

  Widget _buildRatingHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loadingReviewSummary) {
      return SizedBox(
        width: 70,
        height: 18,
        child: LinearProgressIndicator(
          minHeight: 2,
          backgroundColor: Colors.transparent,
          color: colorScheme.primary,
        ),
      );
    }

    if (_reviewSummary.total == 0) {
      return Row(
        children: [
          Icon(
            Icons.star_border,
            color: colorScheme.onSurface.withOpacity(0.55),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            'Sem avaliações',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.65),
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () {
        _selectTab('reviews');
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Color(0xFFFFB800), size: 18),
            const SizedBox(width: 6),
            Text(
              _reviewSummary.average.toStringAsFixed(1),
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.78),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '(${_reviewSummary.total})',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.52),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.72),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _displayName,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.52),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final tabs = [
      (key: 'services', label: 'Serviços', enabled: true),
      (key: 'professionals', label: 'Profissionais', enabled: true),
      (key: 'loyalty', label: 'Fidelidade', enabled: false),
      (key: 'products', label: 'Produtos', enabled: true),
      (key: 'packages', label: 'Pacotes', enabled: false),
      (key: 'subscriptions', label: 'Assinaturas', enabled: false),
      (key: 'reviews', label: 'Avaliações', enabled: true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: tabs.map((tab) {
            final selected = _selectedTab == tab.key;

            final enabled = tab.enabled;

            return InkWell(
              onTap: enabled
                  ? () {
                      _selectTab(tab.key);
                    }
                  : null,
              borderRadius: BorderRadius.circular(6),
              child: Opacity(
                opacity: enabled ? 1 : 0.45,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: selected
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withOpacity(0.78),
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 48,
                        height: 2,
                        color: selected
                            ? colorScheme.primary
                            : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Divider(color: colorScheme.outline.withOpacity(0.22), height: 1),
      ],
    );
  }

  Widget _buildSelectedTabContent() {
    final companyId = widget.company.id;

    switch (_selectedTab) {
      case 'services':
        return CompanyServicesTab(
          companyId: companyId,
          onSchedule: _scheduleService,
        );

      case 'professionals':
        return CompanyProfessionalsTab(companyId: companyId);

      case 'reviews':
        return CompanyReviewsTab(companyId: companyId);

      case 'products':
        return CompanyProductsTab(companyId: companyId);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildComodidadesSection(BuildContext context) {
    final amenities = _companyDetail?.amenities ?? [];

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
          'Comodidades disponíveis no estabelecimento',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.62),
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 18),

        if (_loadingCompanyDetail)
          const Center(child: CircularProgressIndicator())
        else if (amenities.isEmpty)
          const Text('Nenhuma comodidade informada.')
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              final itemWidth = width >= 760
                  ? (width - 36) / 4
                  : width >= 480
                  ? (width - 12) / 2
                  : width;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: amenities.map((amenity) {
                  return SizedBox(
                    width: itemWidth,
                    child: _AmenityCard(
                      icon: _amenityIcon(amenity),
                      label: _amenityLabel(amenity),
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
        border: Border.all(color: colorScheme.outline.withOpacity(0.18)),
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
    final address = _companyDetail?.address;

    final hasAddress =
        address != null && address.formattedAddress.trim().isNotEmpty;

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

              if (_loadingCompanyDetail)
                const Text('Carregando...')
              else
                Text(
                  hasAddress
                      ? address.formattedAddress
                      : 'Endereço não informado',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.76),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 14),

        IconButton(
          tooltip: 'Abrir no Google Maps',
          onPressed: hasAddress ? _openGoogleMaps : null,
          icon: const Icon(Icons.navigation_outlined),
        ),
      ],
    );
  }

  Widget _buildOpeningHoursSection(BuildContext context) {
    final days = _companyDetail?.openingHours ?? [];

    final today = _todayDayWeek();

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

        if (_loadingCompanyDetail)
          const Center(child: CircularProgressIndicator())
        else if (days.isEmpty)
          const Text('Horários não informados')
        else
          ...days.map((day) {
            final isToday = day.dayWeek == today;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(_dayLabel(day.dayWeek)),

                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
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
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (day.intervals.isEmpty)
                    const Text('Fechado')
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: day.intervals.map((interval) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            '${_formatHour(interval.startTime)}'
                            ' - '
                            '${_formatHour(interval.endTime)}',
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    final payments = _companyDetail?.paymentMethods ?? [];

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

        if (_loadingCompanyDetail)
          const Text('Carregando...')
        else if (payments.isEmpty)
          const Text('Não informado')
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: payments.map((payment) {
              return Chip(label: Text(_paymentLabel(payment)));
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSocialSection(BuildContext context) {
    if (_loadingCompanyDetail) {
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
          const Text('Carregando...'),
        ],
      );
    }

    final detail = _companyDetail;

    if (detail == null) {
      return const SizedBox.shrink();
    }

    final socialLinks = [
      _SocialLink(
        tooltip: 'Instagram',
        icon: Icons.camera_alt_outlined,
        url: detail.instagramUrl,
      ),
      _SocialLink(
        tooltip: 'Website',
        icon: Icons.language,
        url: detail.websiteUrl,
      ),
      _SocialLink(
        tooltip: 'Facebook',
        icon: Icons.facebook_outlined,
        url: detail.facebookUrl,
      ),
      _SocialLink(
        tooltip: 'TikTok',
        icon: Icons.music_note,
        url: detail.tiktokUrl,
      ),
    ].where((item) => item.url.trim().isNotEmpty).toList();

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

        if (socialLinks.isEmpty)
          Text(
            'Nenhuma rede social informada.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.60),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: socialLinks.map((social) {
              return Tooltip(
                message: social.tooltip,
                child: InkWell(
                  onTap: () => _openExternalUrl(social.url),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF232732)
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(social.icon),
                  ),
                ),
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

  const _AmenityCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12151C) : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: colorScheme.onSurface.withOpacity(0.75)),

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

class _SocialLink {
  final String tooltip;
  final IconData icon;
  final String url;

  const _SocialLink({
    required this.tooltip,
    required this.icon,
    required this.url,
  });
}
