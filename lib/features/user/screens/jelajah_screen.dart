import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/models.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../controllers/listing_controller.dart';
import 'detail_listing_screen.dart';
import 'notifikasi_screen.dart';

class JelajahScreen extends ConsumerStatefulWidget {
  const JelajahScreen({super.key});

  @override
  ConsumerState<JelajahScreen> createState() => _JelajahScreenState();
}

class _JelajahScreenState extends ConsumerState<JelajahScreen> {
  static const _dropSeconds = 15 * 60;
  final _searchCtrl = TextEditingController();
  Timer? _timer;
  StreamSubscription<LatLng>? _locSub;
  int _secondsLeft = _dropSeconds;
  LatLng? _userLoc;
  String? _locName;
  String _locNameKey = '';
  final Map<String, TokoProfileModel> _tokos = {};
  ImpactSummaryModel? _impact;
  bool _notifBadge = true;

  Future<void> _loadImpact() async {
    try {
      final p = await ref.read(listingRepositoryProvider).getMyImpact();
      if (mounted) setState(() => _impact = p);
    } catch (_) {}
  }

  Future<void> _loadNotifBadge() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getBool('notif_unread_local') ?? true;
      if (mounted && v != _notifBadge) setState(() => _notifBadge = v);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadNotifBadge();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_secondsLeft <= 1) {
          _secondsLeft = _dropSeconds;
        } else {
          _secondsLeft--;
        }
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(listingControllerProvider.notifier).loadInitial();
      _initLocation();
      _loadImpact();
    });
  }

  Future<void> _initLocation({bool manual = false}) async {
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
    if (mounted && loc != null) {
      setState(() => _userLoc = loc);
      _resolveName(loc);
    } else if (mounted && manual) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Aktifkan GPS & izinkan akses lokasi untuk jarak real-time.',
            ),
          ),
        );
    }
    _locSub ??= LocationService().positionStream().listen((p) {
      if (mounted) {
        setState(() => _userLoc = p);
        _resolveName(p);
      }
    });
  }

  Future<void> _resolveName(LatLng p) async {
    final key =
        '${p.latitude.toStringAsFixed(2)},${p.longitude.toStringAsFixed(2)}';
    if (key == _locNameKey) return;
    _locNameKey = key;
    final name = await LocationService().placeName(p);
    if (mounted && name != null && name.isNotEmpty) {
      setState(() => _locName = name);
    }
  }

  String get _locationLabel => _locName ?? 'Aktifkan GPS';

  String? _jarak(FoodListingModel l) {
    final loc = _userLoc;
    final t = _tokos[l.tokoId];
    if (loc == null || t == null) return null;
    final lat = t.latitude;
    final lng = t.longitude;
    if (lat == null || lng == null) return null;
    final km = LocationService.distanceKm(loc, LatLng(lat, lng));
    return km < 1
        ? '${(km * 1000).round()} m dari kamu'
        : '${km.toStringAsFixed(1)} km dari kamu';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listingControllerProvider);
    final controller = ref.read(listingControllerProvider.notifier);

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: controller.loadInitial,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                _BrandHeader(
                  locationLabel: _locationLabel,
                  hasNotif: _notifBadge,
                  onLocation: () => _initLocation(manual: true),
                  onAlert: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotifikasiScreen(),
                      ),
                    );
                    if (mounted) _loadNotifBadge();
                  },
                ),
                const SizedBox(height: 12),
                _SearchField(
                  controller: _searchCtrl,
                  onSearch: controller.setSearch,
                ),
                const SizedBox(height: 14),
                _FlashBanner(
                  secondsLeft: _secondsLeft,
                  totalSeconds: _dropSeconds,
                  tahap: state.listings.isNotEmpty
                      ? _computeTahap(state.listings.first)
                      : 2,
                  discountPct: state.listings.isNotEmpty
                      ? _discount(state.listings.first)
                      : 65,
                ),
                const SizedBox(height: 12),
                _ImpactBento(impact: _impact),
                const SizedBox(height: 16),
                _FilterChips(
                  selected: state.selectedCategory,
                  total: state.listings.length,
                  categories: controller.categories,
                  onSelect: controller.selectCategory,
                ),
                const SizedBox(height: 12),
                _FeedSection(),
                _buildFeed(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed(ListingState state) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.error != null && state.listings.isEmpty) {
      return AppErrorView(
        message: state.error!,
        onRetry: () =>
            ref.read(listingControllerProvider.notifier).loadInitial(),
      );
    }
    if (state.listings.isEmpty) {
      return const AppEmptyState(
        icon: Icons.eco,
        message: 'Belum ada penawaran penyelamatan aktif saat ini.',
      );
    }
    return Column(
      children: [
        ...state.listings.map(
          (l) => _ListingCard(
            listing: l,
            jarakText: _jarak(l),
            onSecure: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      DetailListingScreen(listingId: l.id, listing: l),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (state.isLoadingMore)
          const Center(child: CircularProgressIndicator(strokeWidth: 2))
        else if (state.hasMore)
          GestureDetector(
            onTap: () =>
                ref.read(listingControllerProvider.notifier).loadMore(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Muat lebih banyak',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  static int _discount(FoodListingModel l) {
    if (l.initialPrice <= 0) return 0;
    return ((1 - l.currentPrice / l.initialPrice) * 100).round().clamp(0, 99);
  }

  static int _computeTahap(FoodListingModel l) {
    final span = l.initialPrice - l.minimumPrice;
    if (span <= 0) return 3;
    final progress = (l.initialPrice - l.currentPrice) / span;
    final tahap = (progress * 3).floor() + 1;
    return tahap.clamp(1, 3);
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  const _SearchField({required this.controller, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (value) => onSearch(value.trim()),
      decoration: InputDecoration(
        hintText: 'Cari makanan surplus di sekitarmu…',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.clear();
                  onSearch('');
                },
              ),
      ),
    );
  }
}

class _FlashBanner extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;
  final int tahap;
  final int discountPct;

  const _FlashBanner({
    required this.secondsLeft,
    required this.totalSeconds,
    required this.tahap,
    required this.discountPct,
  });

  @override
  Widget build(BuildContext context) {
    final mm = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (secondsLeft % 60).toString().padLeft(2, '0');
    final progress = secondsLeft / totalSeconds;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryContainer,
            AppColors.secondaryContainer,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33005321),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Text(
              'Tahap $tahap (-$discountPct%)',
              style: AppTheme.labelMd(color: AppColors.onSecondary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flash Drop Batch Sore Ini',
                      style: AppTheme.headlineMd(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Harga turun tiap 30 menit',
                      style: AppTheme.bodySm(
                        color: AppColors.primaryFixed.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _CountdownCircle(progress: progress, label: '$mm:$ss'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownCircle extends StatelessWidget {
  final double progress;
  final String label;

  const _CountdownCircle({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              color: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTheme.headlineSm(
                  color: Colors.white,
                ).copyWith(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(
                'Sisa',
                style: AppTheme.labelCaps(
                  color: Colors.white.withOpacity(0.8),
                ).copyWith(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactBento extends StatelessWidget {
  final ImpactSummaryModel? impact;

  const _ImpactBento({this.impact});

  @override
  Widget build(BuildContext context) {
    final kg = impact?.totalFoodSavedKg ?? 0;
    final money = impact?.totalMoneySaved ?? 0;
    final orders = impact?.totalOrders ?? 0;
    final kosong = kg <= 0 && money <= 0 && orders <= 0;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.onPrimaryFixedVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'KAMU SUDAH SELAMATKAN',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.labelCaps(
                            color: AppColors.primaryFixed,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.eco,
                        size: 18,
                        color: AppColors.primaryFixed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${kg.toStringAsFixed(1)} kg',
                      style: AppTheme.metricLg(color: AppColors.primaryFixed),
                    ),
                  ),
                  Text(
                    'Aman dari tempat sampah',
                    style: AppTheme.bodySm(color: AppColors.primaryFixedDim),
                  ),
                  const SizedBox(height: 8),
                  const Spacer(),
                  Container(
                    height: 28,
                    child: CustomPaint(
                      size: const Size(double.infinity, 28),
                      painter: _SparklinePainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
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
                      Expanded(
                        child: Text(
                          'TOTAL HEMAT',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.labelCaps(color: AppColors.secondary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.account_balance_wallet,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(Fmt.money(money), style: AppTheme.metricSm()),
                  ),
                  Text(
                    kosong
                        ? 'Belum ada transaksi. Coba slot pertama!'
                        : 'Hemat yang masuk kantong',
                    style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            kosong
                                ? 'Mulai sekarang, yuk!'
                                : '$orders pesanan berhasil',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.labelCaps(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primaryFixed;
    final path = Path()
      ..moveTo(0, 20)
      ..quadraticBezierTo(size.width * 0.2, 18, size.width * 0.35, 14)
      ..quadraticBezierTo(size.width * 0.55, 9, size.width * 0.7, 8)
      ..quadraticBezierTo(size.width * 0.85, 6, size.width, 3);
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size.width, 3),
      3,
      Paint()..color = AppColors.secondaryContainer,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FilterChips extends StatelessWidget {
  final String? selected;
  final int total;
  final List<String> categories;
  final ValueChanged<String?> onSelect;

  const _FilterChips({
    required this.selected,
    required this.total,
    required this.categories,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('Semua ($total)', selected == null, onSelect, selected: ''),
          ...categories.map(
            (c) => _chip(c, selected == c, onSelect, selected: c, badge: c),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    String label,
    bool active,
    ValueChanged<String?> onSelect, {
    String? selected,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? AppColors.primary : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          onTap: () => onSelect(selected),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: AppTheme.labelMd(
                color: active ? AppColors.onPrimary : AppColors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Peluang Penyelamatan Aktif', style: AppTheme.headlineSm()),
          const SizedBox(height: 3),
          Text(
            'Berdasarkan lokasi kamu',
            style: AppTheme.labelCaps(),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final FoodListingModel listing;
  final VoidCallback onSecure;
  final String? jarakText;

  const _ListingCard({
    required this.listing,
    required this.onSecure,
    this.jarakText,
  });

  @override
  Widget build(BuildContext context) {
    final initial = listing.initialPrice;
    final current = listing.currentPrice;
    final minimum = listing.minimumPrice;
    final discount = initial > 0 ? ((1 - current / initial) * 100).round() : 0;
    final span = initial - minimum;
    final progress = span > 0
        ? ((initial - current) / span).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onSecure,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A005321),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardImage(
                listing: listing,
                stock: listing.stockQuantity,
                discount: discount,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PriceTrack(
                      initial: initial,
                      current: current,
                      minimum: minimum,
                      progress: progress,
                    ),
                    const SizedBox(height: 10),
                    _SpecChips(listing: listing),
                    if (jarakText != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              jarakText!,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.labelCaps(
                                color: AppColors.primary,
                              ).copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Fmt.money(initial),
                                style:
                                    AppTheme.labelCaps(
                                      color: AppColors.outline,
                                    ).copyWith(
                                      decoration: TextDecoration.lineThrough,
                                    ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Flexible(
                                    child: Text(
                                      Fmt.money(current),
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.metricSm(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryFixed,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '-$discount%',
                                      style: AppTheme.labelCaps(
                                        color: AppColors.onSecondaryFixed,
                                      ).copyWith(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 44,
                          child: FilledButton(
                            onPressed: onSecure,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: Text(
                              'Amankan',
                              style: AppTheme.labelMd(
                                color: AppColors.onPrimary,
                              ),
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
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final FoodListingModel listing;
  final int stock;
  final int discount;

  const _CardImage({
    required this.listing,
    required this.stock,
    required this.discount,
  });

  @override
  Widget build(BuildContext context) {
    final url = listing.photoUrl;
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null && url.isNotEmpty)
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const _ImageFallback(),
            )
          else
            const _ImageFallback(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withOpacity(0.92),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tersisa $stock Porsi',
                    style: AppTheme.labelCaps(color: AppColors.onSurface),
                  ),
                ],
              ),
            ),
          ),
          if (discount >= 30)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
                child: Text(
                  'DISKON -$discount%',
                  style: AppTheme.labelCaps(color: AppColors.onPrimary),
                ),
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.category.toUpperCase(),
                  style: AppTheme.labelCaps(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  listing.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headlineSm(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryFixed.withOpacity(0.15),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_menu,
        size: 48,
        color: AppColors.primary,
      ),
    );
  }
}

class _PriceTrack extends StatelessWidget {
  final double initial;
  final double current;
  final double minimum;
  final double progress;

  const _PriceTrack({
    required this.initial,
    required this.current,
    required this.minimum,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DINAMIKA NILAI WAKTU',
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelCaps(color: AppColors.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Terendah ${Fmt.money(minimum)}',
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelCaps(
                    color: AppColors.secondary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.secondaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  Fmt.money(initial),
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelCaps(
                    color: AppColors.onSurfaceVariant,
                  ).copyWith(fontSize: 11),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: Text(
                  '${Fmt.money(current)} (Sekarang)',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelCaps(
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  Fmt.money(minimum),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelCaps(
                    color: AppColors.onSurfaceVariant,
                  ).copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecChips extends StatelessWidget {
  final FoodListingModel listing;

  const _SpecChips({required this.listing});

  @override
  Widget build(BuildContext context) {
    final safeTime = listing.safeUntil != null
        ? 'Sebelum ${Fmt.time(Fmt.parse(listing.safeUntil))} WIB'
        : (listing.pickupEndTime != null
              ? 'Ambil sebelum ${Fmt.time(Fmt.parse(listing.pickupEndTime))} WIB'
              : null);
    return Row(
      children: [
        if (safeTime != null) ...[
          Expanded(
            child: _specChip(
              icon: Icons.schedule,
              color: AppColors.outline,
              label: safeTime,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: _specChip(
            icon: Icons.moped,
            color: AppColors.primary,
            label:
                listing.pickupStartTime != null || listing.pickupEndTime != null
                ? 'Ambil hari ini'
                : 'Kurir internal siap',
          ),
        ),
      ],
    );
  }

  Widget _specChip({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final VoidCallback onLocation;
  final VoidCallback onAlert;
  final String locationLabel;
  final bool hasNotif;

  const _BrandHeader({
    required this.onLocation,
    required this.onAlert,
    required this.hasNotif,
    this.locationLabel = 'Aktifkan GPS',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14005321),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/Foodrescue.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RESCUE OS',
                style: AppTheme.labelCaps(
                  color: AppColors.tertiary,
                ).copyWith(letterSpacing: 2),
              ),
              Text('Jelajah', style: AppTheme.headlineSm()),
            ],
          ),
        ),
        GestureDetector(
          onTap: onLocation,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.near_me, size: 15, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.labelMd().copyWith(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAlert,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications, size: 20),
                if (hasNotif)
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
