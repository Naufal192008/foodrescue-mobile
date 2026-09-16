import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/models.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/listing_controller.dart';
import '../controllers/order_controller.dart';
import 'order_success_screen.dart';

class DetailListingScreen extends ConsumerStatefulWidget {
  final String listingId;
  final FoodListingModel? listing;

  const DetailListingScreen({
    super.key,
    required this.listingId,
    this.listing,
  });

  @override
  ConsumerState<DetailListingScreen> createState() =>
      _DetailListingScreenState();
}

enum _Fulfillment { kurir, pickup }

class _DetailListingScreenState extends ConsumerState<DetailListingScreen> {
  static const _dropSeconds = 15 * 60;

  FoodListingModel? _listing;
  bool _loading = false;
  String? _error;

  _Fulfillment _fulfillment = _Fulfillment.kurir;
  int _quantity = 1;
  bool _secured = false;

  Timer? _timer;
  int _secondsLeft = _dropSeconds;

  StreamSubscription<LatLng>? _locSub;
  LatLng? _userLoc;
  final Map<String, TokoProfileModel> _tokos = {};

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_secondsLeft <= 1) {
          _secondsLeft = _dropSeconds;
        } else {
          _secondsLeft--;
        }
      });
    });
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  Future<void> _initLocation() async {
    try {
      final tokos = await ref
          .read(listingRepositoryProvider)
          .getApprovedTokos();
      if (mounted && tokos.isNotEmpty) {
        setState(() {
          _tokos
            ..clear()
            ..addAll({for (final t in tokos) t.id: t});
        });
      }
    } catch (_) {}
    final loc = await LocationService().getCurrentPosition();
    if (mounted && loc != null) setState(() => _userLoc = loc);
    _locSub ??= LocationService()
        .positionStream()
        .listen((p) {
          if (mounted) setState(() => _userLoc = p);
        });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _listing == null;
      _error = null;
    });
    try {
      final fresh = await ref
          .read(listingRepositoryProvider)
          .getListing(widget.listingId);
      if (!mounted) return;
      setState(() {
        _listing = fresh;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _secure() async {
    final listing = _listing;
    if (listing == null) return;
    final orderCtrl = ref.read(orderStateProvider.notifier);
    final ok = await orderCtrl.createOrder(
      listing: listing,
      quantity: _quantity,
      fulfillmentMethod: _fulfillment == _Fulfillment.kurir
          ? 'diantar_kurir'
          : 'pickup_mandiri',
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _secured = true);
      final state = ref.read(orderStateProvider);
      final order = state.createdOrder;
      if (order != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(orderId: order.id, order: order),
          ),
        );
        return;
      }
    }
    final err = ref.read(orderStateProvider).error;
    if (err != null && err.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  String _fmtKm(double km) => km < 1
      ? '${(km * 1000).round()} m'
      : '${km.toStringAsFixed(1)} km';

  Future<void> _openMaps(TokoProfileModel t) async {
    final lat = t.latitude;
    final lng = t.longitude;
    final target = lat != null && lng != null
        ? '$lat,$lng'
        : Uri.encodeComponent(t.address.isNotEmpty ? t.address : '');
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$target',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Google Maps tidak ditemukan.')),
          );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Gagal membuka Google Maps.')),
        );
    }
  }

  Widget _lokasiCard() {
    final l = _listing;
    final t = l == null ? null : _tokos[l.tokoId];
    double? km;
    if (_userLoc != null && t != null && t.latitude != null && t.longitude != null) {
      km = LocationService.distanceKm(_userLoc!, LatLng(t.latitude!, t.longitude!));
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LOKASI & RUTE', style: AppTheme.labelCaps()),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.near_me_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  km != null
                      ? 'Berjarak ${_fmtKm(km)} dari lokasimu saat ini'
                      : 'Lagi menghitung jarak ke mitra...',
                  style: AppTheme.bodyMd(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: t != null
                  ? () => _openMaps(t)
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: const Text('Buka Rute di Google Maps'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = _listing;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null && listing == null)
            _ErrorView(message: _error!, onRetry: _load)
          else if (listing != null)
            ListView(
              padding: const EdgeInsets.only(bottom: 230),
              children: [
                _HeroImage(listing: listing),
                _TrustBadges(listing: listing),
                const SizedBox(height: 12),
                _PriceCurveCard(
                  listing: listing,
                  secondsLeft: _secondsLeft,
                  totalSeconds: _dropSeconds,
                ),
                const SizedBox(height: 12),
                _NutritionCard(),
                const SizedBox(height: 12),
                _SafetyLogCard(listing: listing),
                const SizedBox(height: 12),
                _LogisticsCard(
                  selected: _fulfillment,
                  onChanged: (v) => setState(() => _fulfillment = v),
                ),
                const SizedBox(height: 12),
                _lokasiCard(),
              ],
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _secured
                ? _SecuredDrawer(fulfillment: _fulfillment)
                : _RescueDrawer(
                    listing: listing,
                    quantity: _quantity,
                    onQuantityChanged: (v) => setState(() => _quantity = v),
                    loading: listing == null,
                    onSecure: _secure,
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final FoodListingModel listing;

  const _HeroImage({required this.listing});

  @override
  Widget build(BuildContext context) {
    final discount = listing.initialPrice > 0
        ? ((1 - listing.currentPrice / listing.initialPrice) * 100).round()
        : 0;
    final url = listing.photoUrl;

    return SizedBox(
      height: 340,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null && url.isNotEmpty)
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const _DetailPlaceholder(),
            )
          else
            const _DetailPlaceholder(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _circleBtn(
                  context,
                  Icons.arrow_back,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        listing.stockQuantity <= 0
                            ? 'Stok Habis'
                            : 'Sisa ${listing.stockQuantity} Porsi',
                        style: AppTheme.labelCaps(
                          color: AppColors.onSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _circleBtn(context, Icons.bookmark_border),
                const SizedBox(width: 8),
                _circleBtn(
                  context,
                  Icons.share_outlined,
                  onTap: _shareListing,
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: AppColors.primaryFixed,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${listing.category} • Standard Quality',
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.labelCaps(
                          color: AppColors.primaryFixed,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (discount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                        ),
                        child: Text(
                          '-$discount% DISKON SPESIAL',
                          style: AppTheme.labelCaps(
                            color: AppColors.onSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  listing.name,
                  style: AppTheme.headlineMd(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: AppColors.secondaryFixed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '4.9',
                      style: AppTheme.labelMd(color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(ulasan tersedia)',
                      style: AppTheme.bodySm(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(width: 8),
                    if (listing.distanceKm != null)
                      Text(
                        '${listing.distanceKm} km',
                        style: AppTheme.bodySm(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      )
                    else
                      Text(
                        'Fresh batch',
                        style: AppTheme.bodySm(
                          color: Colors.white.withValues(alpha: 0.7),
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

  void _shareListing() {
    final message = '${listing.name} cuma ${Fmt.money(listing.currentPrice)} untuk '
        '${listing.stockQuantity} porsi dari ${listing.tokoName ?? 'mitra Food Rescue OS'}. '
        'Yuk amankan sebelum terbuang!\n\n'
        '#FoodRescue #ZeroFoodWaste #ZeroWaste';
    Share.share(message);
  }

  Widget _circleBtn(BuildContext context, IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: AppColors.surfaceContainerLowest.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () {},
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppColors.onSurface),
        ),
      ),
    );
  }
}

class _DetailPlaceholder extends StatelessWidget {
  const _DetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryFixed.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_menu,
        size: 64,
        color: AppColors.primary,
      ),
    );
  }
}

class _TrustBadges extends StatelessWidget {
  final FoodListingModel listing;

  const _TrustBadges({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _badge(Icons.eco, AppColors.primary, 'Grade A Surplus Segar'),
            _badge(
              Icons.health_and_safety,
              AppColors.primary,
              listing.foodSafetyNotes != null
                  ? 'Terjaga Cold-chain'
                  : 'Standar Keamanan Pangan',
            ),
            if (listing.distanceKm != null)
              _badge(
                Icons.near_me,
                AppColors.secondary,
                '${listing.distanceKm} km dari Lokasimu',
              )
            else
              _badge(
                Icons.schedule,
                AppColors.secondary,
                listing.pickupStartTime != null
                    ? 'Ambil mulai ${Fmt.time(Fmt.parse(listing.pickupStartTime))} WIB'
                    : 'Siap Hari Ini',
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, Color color, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.labelCaps().copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCurveCard extends StatelessWidget {
  final FoodListingModel listing;
  final int secondsLeft;
  final int totalSeconds;

  const _PriceCurveCard({
    required this.listing,
    required this.secondsLeft,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final initial = listing.initialPrice;
    final current = listing.currentPrice;
    final minimum = listing.minimumPrice;
    final span = initial - minimum;
    final progress = span > 0
        ? ((initial - current) / span).clamp(0.0, 1.0)
        : 0.0;
    final tier = (progress * 3).floor() + 1;

    final hh = (secondsLeft ~/ 3600).toString().padLeft(2, '0');
    final mm = ((secondsLeft % 3600) ~/ 60).toString().padLeft(2, '0');
    final ss = (secondsLeft % 60).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14005321),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_down, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'MEKANISME FINANSIAL SURPLUS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelCaps(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tier $tier Aktif',
                      style: AppTheme.labelCaps(color: AppColors.secondary)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Algoritma Penurunan Harga Dinamis',
            style: AppTheme.headlineSm(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 110),
                  painter: _PriceCurvePainter(progress: progress),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tierColumn(
                      label: 'AWAL',
                      price: Fmt.money(initial),
                      note: 'Mulai listing',
                      align: TextAlign.left,
                      highlight: false,
                    ),
                    const SizedBox(width: 6),
                    _tierColumn(
                      label: 'SEKARANG',
                      price: Fmt.money(current),
                      note: '-${(progress * 100).round()}% Penyelamatan',
                      align: TextAlign.center,
                      highlight: true,
                    ),
                    const SizedBox(width: 6),
                    _tierColumn(
                      label: 'FINAL',
                      price: Fmt.money(minimum),
                      note: 'Terendah',
                      align: TextAlign.right,
                      highlight: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.timer,
                    size: 18,
                    color: AppColors.onSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RESET NILAI BERIKUTNYA',
                        style: AppTheme.labelCaps(),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$hh:$mm:$ss',
                            style: AppTheme.labelMd(
                              color: AppColors.secondary,
                            ).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'menuju ${Fmt.money(minimum)}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: AppTheme.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'RISIKO KEHABISAN',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.labelCaps(color: AppColors.error)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        listing.stockQuantity <= 0
                            ? 'Stok Habis'
                            : '${listing.stockQuantity} porsi tersisa',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.labelMd(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierColumn({
    required String label,
    required String price,
    required String note,
    required TextAlign align,
    required bool highlight,
  }) {
    final content = Column(
      crossAxisAlignment: align == TextAlign.left
          ? CrossAxisAlignment.start
          : align == TextAlign.center
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.end,
      children: [
        if (highlight)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'SEKARANG',
                style: AppTheme.labelCaps(color: AppColors.secondary)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          )
        else
          Text(
            'AWAL'.contains(label) ? 'AWAL' : 'FINAL',
            style: AppTheme.labelCaps(),
          ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: align == TextAlign.left
              ? Alignment.centerLeft
              : align == TextAlign.center
                  ? Alignment.center
                  : Alignment.centerRight,
          child: Text(
            price,
            maxLines: 1,
            style: highlight
                ? AppTheme.headlineSm(color: AppColors.secondary)
                    .copyWith(fontWeight: FontWeight.w700)
                : AppTheme.labelMd().copyWith(color: AppColors.outline),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          note,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
        ),
      ],
    );

    if (highlight) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: content,
        ),
      );
    }
    return Expanded(child: content);
  }
}

class _PriceCurvePainter extends CustomPainter {
  final double progress;

  _PriceCurvePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const h1 = 20.0;
    const h2 = 60.0;
    const h3 = 100.0;
    const left = 20.0;
    final right = size.width - 20;

    final guide = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.5)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (final y in [h1, h2, h3]) {
      const dash = 4.0;
      const gap = 4.0;
      var x = left;
      while (x < right) {
        canvas.drawLine(Offset(x, y), Offset(x + dash, y), guide);
        x += dash + gap;
      }
    }

    // Garis penuh (kabur)
    final full = Path()
      ..moveTo(left, h1)
      ..lineTo(left + 50, h1)
      ..lineTo(left + 80, h2)
      ..lineTo(right - 80, h2)
      ..lineTo(right - 50, h3)
      ..lineTo(right, h3);
    canvas.drawPath(
      full,
      Paint()
        ..color = AppColors.outlineVariant
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Segmen aktif mengikuti progress
    final tx = left + progress * (right - left);
    final active = Path()
      ..moveTo(left, h1)
      ..lineTo(left + 50, h1)
      ..lineTo(left + 80, h2)
      ..lineTo(tx, h2);
    canvas.drawPath(
      active,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.primaryContainer, AppColors.secondaryContainer],
        ).createShader(Rect.fromLTWH(left, 0, right - left, 110))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Titik awal
    canvas.drawCircle(
      Offset(left + 50, h1),
      4.5,
      Paint()..color = AppColors.onSurfaceVariant,
    );
    canvas.drawCircle(
      Offset(left + 50, h1),
      2,
      Paint()..color = Colors.white,
    );

    // Titik aktif (current)
    canvas.drawCircle(
      Offset(tx, h2),
      10,
      Paint()
        ..color = AppColors.secondaryContainer.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      Offset(tx, h2),
      7,
      Paint()..color = AppColors.secondaryContainer,
    );
    canvas.drawCircle(
      Offset(tx, h2),
      3,
      Paint()..color = Colors.white,
    );

    // Titik final
    canvas.drawCircle(
      Offset(right - 50, h3),
      4.5,
      Paint()..color = AppColors.outlineVariant,
    );
    canvas.drawCircle(
      Offset(right - 50, h3),
      2,
      Paint()..color = AppColors.surface,
    );
  }

  @override
  bool shouldRepaint(covariant _PriceCurvePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _NutritionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33005321),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 16,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI NUTRISI & PORSI',
                  style: AppTheme.labelCaps(color: AppColors.primaryFixed),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.onPrimaryFixedVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
                child: Text(
                  'AKURASI 98%',
                  style: AppTheme.labelCaps(color: AppColors.primaryFixed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Ideal untuk 1 porsi makan bergizi tinggi, estimasi nutrisi otomatis dari foto & porsi halaman ini.',
            style: AppTheme.bodyMd(color: AppColors.primaryFixed),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _nutritionTile('KALORI', '540', 'kkal / porsi'),
              const SizedBox(width: 6),
              _nutritionTile('PROTEIN', '34g', 'Sumber utama'),
              const SizedBox(width: 6),
              _nutritionTile('KARBO', '62g', 'Energi harian'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nutritionTile(String label, String value, String note) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.tertiary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.labelCaps(color: AppColors.tertiaryFixed),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTheme.metricSm(color: AppColors.onTertiary),
            ),
            Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySm(color: AppColors.tertiaryFixedDim),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyLogCard extends StatelessWidget {
  final FoodListingModel listing;

  const _SafetyLogCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final safeTime = listing.safeUntil != null
        ? 'Sebelum ${Fmt.time(Fmt.parse(listing.safeUntil))} WIB'
        : 'Belum ditentukan';
    final prodTime = listing.pickupStartTime != null
        ? 'Mulai ${Fmt.time(Fmt.parse(listing.pickupStartTime))} WIB'
        : 'Fresh batch hari ini';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Protokol Keamanan Pangan',
                  style: AppTheme.headlineSm(),
                ),
              ),
              Text(
                'LOG HACCP',
                style: AppTheme.labelCaps(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _logRow(
            icon: Icons.kitchen,
            color: AppColors.primary,
            label: 'WAKTU PRODUKSI / SIAP',
            value: prodTime,
            chip: 'Fresh',
          ),
          _logRow(
            icon: Icons.event_available,
            color: AppColors.secondary,
            label: 'BATAS AMAN KONSUMSI',
            value: safeTime,
            chip: 'Terpantau',
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.ac_unit, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PENYIMPANAN & CARA SANTAP',
                        style: AppTheme.labelCaps(),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        listing.foodSafetyNotes ??
                            'Terjaga suhu aman, terstandar keamanan pangan. Hangatkan sebelum disantap untuk rasa maksimal.',
                        style: AppTheme.bodySm(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String chip,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.labelCaps()),
                Text(
                  value,
                  style: AppTheme.bodyMd().copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color == AppColors.secondary
                  ? AppColors.secondaryContainer
                  : AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Text(
              chip,
              style: AppTheme.labelCaps(
                color: color == AppColors.secondary
                    ? AppColors.onSecondary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogisticsCard extends StatelessWidget {
  final _Fulfillment selected;
  final ValueChanged<_Fulfillment> onChanged;

  const _LogisticsCard({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isKurir = selected == _Fulfillment.kurir;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PILIHAN METODE PENGAMBILAN',
            style: AppTheme.labelCaps(),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _option(
                    active: isKurir,
                    icon: Icons.local_shipping,
                    title: 'Kurir Khusus (Diantar)',
                    subtitle: 'Armada Eco-Fleet insulated (+Rp 8.000)',
                    onTap: () => onChanged(_Fulfillment.kurir),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _option(
                    active: !isKurir,
                    icon: Icons.storefront,
                    title: 'Self Pick-up (Ambil Sendiri)',
                    subtitle: 'Ambil langsung di toko (gratis ongkir)',
                    onTap: () => onChanged(_Fulfillment.pickup),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isKurir
                        ? 'Kurir Eco-Fleet siap antar dalam 25 menit setelah pesanan terkonfirmasi.'
                        : 'Ambil sendiri di toko. Kode konfirmasi diberikan setelah pembayaran.',
                    style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _option({
    required bool active,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active ? AppColors.primary : AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: active
                        ? AppColors.onPrimary
                        : AppColors.onSurface,
                  ),
                  Icon(
                    active ? Icons.circle : Icons.circle_outlined,
                    size: 14,
                    color: active
                        ? AppColors.primaryFixed
                        : AppColors.outlineVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.labelMd(
                  color: active
                      ? AppColors.onPrimary
                      : AppColors.onSurface,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodySm(
                  color: active
                      ? AppColors.primaryFixed
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RescueDrawer extends StatelessWidget {
  final FoodListingModel? listing;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final bool loading;
  final VoidCallback onSecure;

  const _RescueDrawer({
    required this.listing,
    required this.quantity,
    required this.onQuantityChanged,
    required this.loading,
    required this.onSecure,
  });

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final initial = l?.initialPrice ?? 0;
    final current = l?.currentPrice ?? 0;
    final total = current * quantity;
    final savings = initial - current;
    final discount = initial > 0
        ? ((1 - current / initial) * 100).round()
        : 0;
    final buyable = (l?.status ?? '') == 'active' && (l?.stockQuantity ?? 0) > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33005321),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HARGA PENYELAMATAN',
                      style: AppTheme.labelCaps(),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 8,
                      children: [
                        Text(
                          Fmt.money(total),
                          style: AppTheme.metricSm(
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          initial * quantity > 0
                              ? Fmt.money(initial * quantity)
                              : '',
                          style: AppTheme.bodyMd(
                            color: AppColors.outline,
                          ).copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (discount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                        ),
                        child: Text(
                          '-$discount% OFF',
                          style: AppTheme.labelCaps(
                            color: AppColors.onSecondary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Hemat ${Fmt.money(savings * quantity)}',
                        style: AppTheme.labelCaps(
                          color: AppColors.primary,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (buyable)
            Row(
              children: [
                _QtyStepper(
                  value: quantity,
                  min: 1,
                  max: l?.stockQuantity ?? 1,
                  onChanged: onQuantityChanged,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: loading ? null : onSecure,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.onPrimary,
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Amankan Sekarang',
                                style: AppTheme.labelMd(
                                  color: AppColors.onPrimary,
                                ).copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerHigh,
                  foregroundColor: AppColors.onSurfaceVariant,
                  disabledBackgroundColor: AppColors.surfaceContainerHigh,
                  disabledForegroundColor: AppColors.onSurfaceVariant,
                ),
                child: Text(
                  (l?.stockQuantity ?? 0) <= 0
                      ? 'Stok Makanan Habis'
                      : 'Makanan Tidak Tersedia',
                  textAlign: TextAlign.center,
                  style: AppTheme.labelMd(
                    color: AppColors.onSurfaceVariant,
                  ).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Uang kamu aman 100% • Garansi sampai pesanan diterima',
              style: AppTheme.labelCaps().copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _QtyStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, bool enabled, VoidCallback onTap) {
      return Material(
        color: enabled
            ? AppColors.surfaceContainerLow
            : AppColors.surfaceContainerLow.withValues(alpha: 0.5),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 18,
              color: enabled
                  ? AppColors.onSurface
                  : AppColors.outline.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove, value > min, () => onChanged(value - 1)),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTheme.headlineSm().copyWith(fontSize: 18),
          ),
        ),
        const SizedBox(width: 8),
        btn(Icons.add, value < max, () => onChanged(value + 1)),
      ],
    );
  }
}

class _SecuredDrawer extends StatelessWidget {
  final _Fulfillment fulfillment;

  const _SecuredDrawer({required this.fulfillment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33005321),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.onPrimary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harga Terkunci',
                  style: AppTheme.labelCaps(color: AppColors.primaryFixed),
                ),
                const SizedBox(height: 2),
                Text(
                  'Slot aman, lanjut bayar di halaman sukses.',
                  style: AppTheme.bodySm(color: AppColors.onPrimary),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: AppColors.onPrimary),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 68, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}