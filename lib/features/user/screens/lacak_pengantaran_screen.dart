import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/models.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/listing_controller.dart';
import 'chat_screen.dart';
import 'notifikasi_screen.dart';

enum _LacakTahap {
  konfirmasi(1, 'Konfirmasi', 'Terverifikasi', Icons.verified_user),
  penjemputan(2, 'Penjemputan', 'Selesai', Icons.inventory_2),
  perjalanan(3, 'Perjalanan', 'Berlangsung', Icons.route),
  tujuan(4, 'Tujuan', 'Menunggu', Icons.flag_circle),
  ;

  const _LacakTahap(this.nomor, this.label, this.status, this.icon);
  final int nomor;
  final String label;
  final String status;
  final IconData icon;
}

class LacakPengantaranScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  final FoodListingModel? listing;

  const LacakPengantaranScreen({
    super.key,
    required this.order,
    this.listing,
  });

  @override
  ConsumerState<LacakPengantaranScreen> createState() =>
      _LacakPengantaranScreenState();
}

class _LacakPengantaranScreenState extends ConsumerState<LacakPengantaranScreen> {
  FoodListingModel? _listing;

  // Telemetry template (backend telemetri belum tersedia).
  static const _suhu = 4.2;
  static const _kecepatan = 32;

  StreamSubscription<LatLng>? _locSub;
  LatLng? _userLoc;
  LatLng? _prevLoc;
  DateTime? _prevT;
  final Map<String, TokoProfileModel> _tokos = {};

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
    if (_listing == null && widget.order.listingId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final l = await ref
              .read(listingRepositoryProvider)
              .getListing(widget.order.listingId);
          if (mounted) setState(() => _listing = l);
        } catch (_) {}
      });
    }
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
    final now = DateTime.now();
    if (mounted && loc != null) {
      setState(() {
        _userLoc = loc;
        _prevLoc = loc;
        _prevT = now;
      });
    }
    _locSub ??= LocationService().positionStream().listen((p) {
      if (!mounted) return;
      setState(() {
        _prevLoc = _userLoc;
        _prevT = _userLoc != null ? DateTime.now() : _prevT;
        _userLoc = p;
      });
    });
  }

  String get _latLngLabel {
    final loc = _userLoc;
    if (loc == null) return 'GPS aktif...';
    return '${loc.latitude.toStringAsFixed(5)}, '
        '${loc.longitude.toStringAsFixed(5)}';
  }

  String _fmtKm(double km) => km < 1
      ? '${(km * 1000).round()} m'
      : '${km.toStringAsFixed(1)} km';

  @override
  void dispose() {
    _locSub?.cancel();
    super.dispose();
  }

  double get _speedKmh {
    final a = _prevLoc;
    final b = _userLoc;
    final t = _prevT;
    if (a == null || b == null || t == null) return _kecepatan.toDouble();
    final dt = DateTime.now().difference(t).inSeconds;
    if (dt <= 0) return _kecepatan.toDouble();
    final d = LocationService.distanceKm(a, b);
    return (d / (dt / 3600)).roundToDouble();
  }

  double? get _jarakTokoKm {
    final loc = _userLoc;
    final t = _listing == null ? null : _tokos[_listing!.tokoId];
    if (loc == null || t == null) return null;
    final lat = t.latitude;
    final lng = t.longitude;
    if (lat == null || lng == null) return null;
    return LocationService.distanceKm(loc, LatLng(lat, lng));
  }

  Future<void> _openMapsRoute() async {
    final t = _listing == null ? null : _tokos[_listing!.tokoId];
    final lat = t?.latitude;
    final lng = t?.longitude;
    final target = lat != null && lng != null
        ? '$lat,$lng'
        : Uri.encodeComponent(_listing?.address ?? '');
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$target',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  int get _tahapAktif {
    final t = widget.order.raw['trip_status'] as String?;
    if (t == 'diterima_user') return 4;
    if (t == 'barang_diambil') return 3;
    return 3; // kurir ditemukan → sedang berjalan
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _brandBar(),
              const SizedBox(height: 16),
              _heroOrderCard(),
              const SizedBox(height: 12),
              _mapCard(),
              const SizedBox(height: 12),
              _etaCard(),
              const SizedBox(height: 16),
              _telemetryRow(),
              const SizedBox(height: 16),
              _stepsCard(),
              const SizedBox(height: 12),
              _kurirCard(),
              const SizedBox(height: 12),
              _manifestCard(),
              const SizedBox(height: 12),
              _impactCard(),
              const SizedBox(height: 12),
              _guaranteeCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── BRAND BAR ─────────────────────────
  Widget _brandBar() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/Foodrescue.png',
            width: 34,
            height: 34,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 34,
              height: 34,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'RESCUE OS',
          style: AppTheme.labelCaps(color: AppColors.primary)
              .copyWith(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
          ),
          icon: const Icon(Icons.notifications_outlined),
        ),
      ],
    );
  }

  // ───────────────────────── HERO CARD ─────────────────────────
  Widget _heroOrderCard() {
    final id = widget.order.id.length >= 3
        ? widget.order.id.substring(0, 3).toUpperCase()
        : widget.order.id;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.electric_moped,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _listing?.tokoName ?? 'Eco-Fleet',
                  style: AppTheme.labelCaps(color: Colors.white70),
                ),
                Text(
                  'Eco-Fleet • #FR-$id',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8BFA9E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Aktif • ${_speedKmh.round()} km/jam',
                      style: AppTheme.labelCaps(color: Colors.white),
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

  // ───────────────────────── MAP CARD ─────────────────────────
  Widget _mapCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const h = 210.0;
        final t = _listing == null ? null : _tokos[_listing!.tokoId];
        final tLat = t?.latitude;
        final tLng = t?.longitude;
        final hasToko = tLat != null && tLng != null;

        Offset tokoPt = const Offset(0.80, 0.26);
        Offset kurirPt = const Offset(0.44, 0.52);
        Offset userPt = const Offset(0.14, 0.82);
        if (hasToko && _userLoc != null) {
          final latL = [tLat, _userLoc!.latitude];
          final lngL = [tLng, _userLoc!.longitude];
          final minLat = latL.reduce(min), maxLat = latL.reduce(max);
          final minLng = lngL.reduce(min), maxLng = lngL.reduce(max);
          double fx(double lng) {
            final r = (lng - minLng) / (maxLng - minLng);
            return 0.10 + (r.isFinite ? r : 0.5) * 0.80;
          }
          double fy(double lat) {
            final r = (lat - minLat) / (maxLat - minLat);
            return 1 - (0.10 + (r.isFinite ? r : 0.5) * 0.80);
          }
          tokoPt = Offset(fx(tLng), fy(tLat));
          userPt = Offset(fx(_userLoc!.longitude), fy(_userLoc!.latitude));
          kurirPt = Offset.lerp(tokoPt, userPt, 0.42)!;
        }
        final route = [tokoPt, kurirPt, userPt];
        final km = _jarakTokoKm;

        Widget pin(Offset p, {required String label, required IconData icon}) {
          return Positioned(
            left: (p.dx * w - 40).clamp(0.0, w - 100),
            top: (p.dy * h - 14).clamp(0.0, h - 40),
            child: _pinCard(label: label, icon: icon),
          );
        }

        return Container(
          height: h,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          child: Stack(
            children: [
              const CustomPaint(
                size: Size.infinite,
                painter: _PetaLandasanPainter(),
              ),
              CustomPaint(
                size: Size.infinite,
                painter: _RutePainter(route),
              ),
              pin(tokoPt, label: 'Jemput', icon: Icons.storefront),
              pin(kurirPt, label: 'Kurir', icon: Icons.electric_moped),
              Positioned(
                left: (userPt.dx * w - 12).clamp(0.0, w - 40),
                top: (userPt.dy * h - 12).clamp(0.0, h - 60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.45),
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kamu · Tujuan',
                      style: AppTheme.labelCaps(
                        color: AppColors.primary,
                      ).copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              if (km != null)
                Positioned(
                  left: (kurirPt.dx * w + 8).clamp(0.0, w - 130),
                  top: (kurirPt.dy * h + 6).clamp(0.0, h - 34),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_fmtKm(km)} ke toko',
                      style: AppTheme.labelCaps(
                        color: AppColors.onPrimary,
                      ).copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'ETA ${_etaClock}',
                        style: AppTheme.labelCaps(
                          color: Colors.white,
                        ).copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: OutlinedButton(
                  onPressed: _openMapsRoute,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Buka Rute'),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _userLoc == null ? Icons.location_off : Icons.my_location,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _latLngLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String get _etaClock {
    final now = DateTime.now().add(const Duration(minutes: 25));
    final hr = now.hour.toString().padLeft(2, '0');
    final mi = now.minute.toString().padLeft(2, '0');
    return '$hr:$mi';
  }

  Widget _pinCard({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33005321),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label, style: AppTheme.labelCaps()),
        ],
      ),
    );
  }

  // ───────────────────────── ETA ─────────────────────────
  Widget _etaCard() {
    final km = _jarakTokoKm;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F005321),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Estimasi Kedatangan', style: AppTheme.labelCaps()),
          const SizedBox(height: 6),
          Text(
            '08:31',
            style: AppTheme.metricSm().copyWith(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Text('MENIT', style: AppTheme.labelCaps(color: AppColors.primary)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.68,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            km != null
                ? 'Kurir akan tiba ~${_kecepatan} menit lagi '
                    '• berjarak ${_fmtKm(km)} dari lokasimu.'
                : 'Kurir akan tiba ~${_kecepatan} menit lagi sesuai rute optimal.',
            style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ───────────────────────── TELEMETRY ─────────────────────────
  Widget _telemetryRow() {
    return Row(
      children: [
        Expanded(
          child: _telemetryTile(
            icon: Icons.thermostat,
            label: 'Suhu Boks',
            value: '$_suhu°C',
            note: 'Optimal Dingin',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _telemetryTile(
            icon: Icons.speed,
            label: 'Kecepatan',
            value: '${_speedKmh.round()} km/jam',
            note: 'Stabil',
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _telemetryTile({
    required IconData icon,
    required String label,
    required String value,
    required String note,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label, style: AppTheme.labelCaps()),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.labelMd().copyWith(fontSize: 16),
          ),
          Text(note, style: AppTheme.bodySm(color: color)),
        ],
      ),
    );
  }

  // ───────────────────────── STEPS ─────────────────────────
  Widget _stepsCard() {
    final aktif = _tahapAktif;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proses Penyelamatan • Tahap $aktif dari 4',
            style: AppTheme.labelCaps(),
          ),
          const SizedBox(height: 14),
          Row(
            children: _LacakTahap.values.map((t) {
              final done = t.nomor < aktif;
              final now = t.nomor == aktif;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: (done || now)
                            ? AppColors.primary
                            : AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        done ? Icons.check : t.icon,
                        size: 15,
                        color: (done || now)
                            ? AppColors.onPrimary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(t.label, style: AppTheme.labelCaps().copyWith(fontSize: 9)),
                    Text(
                      t.status,
                      style: AppTheme.bodySm(
                        color: now ? AppColors.primary : AppColors.outline,
                      ).copyWith(fontSize: 9),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── KURIR ─────────────────────────
  Widget _kurirCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 28,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 10,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kurir Eco-Fleet',
                      style: AppTheme.headlineMd().copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFFFB300),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '4.98 • 1.240 Rescue Antaran',
                          style: AppTheme.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.health_and_safety,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Insulated Food Safety Certified (#ID-8821)',
                  style: AppTheme.labelCaps(color: AppColors.primary)
                      .copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(order: widget.order),
                      ),
                    ),
                    child: const Text('Hubungi Kurir'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimary,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {
                      final km = _jarakTokoKm;
                      Share.share(
                        'Pesanan makanan penyelamatan sedang dalam perjalanan! '
                        '${km != null ? 'Kurir ~${_fmtKm(km)} dari lokasiku. ' : ''}'
                        'Nol makanan terbuang hari ini. #FoodRescue #ZeroWaste',
                      );
                    },
                    child: const Text('Bagikan Live'),
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      side: const BorderSide(color: AppColors.outline),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────── MANIFEST ─────────────────────────
  Widget _manifestCard() {
    final l = _listing ?? widget.order.listing;
    final name = l?.name ?? 'Makanan Terselamatkan';
    final toko = l?.tokoName ?? 'Mitra • Jakarta';
    final itemTotal = widget.order.priceAtPurchase * widget.order.quantity;
    final initialTotal =
        l != null ? l.initialPrice * widget.order.quantity : 0.0;
    final fee = 8000.0;
    final hemat = (initialTotal + fee) - widget.order.totalAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Manifest', style: AppTheme.labelCaps()),
              const Spacer(),
              Text(
                '#FR-${widget.order.id.length >= 4 ? widget.order.id.substring(0, 4) : widget.order.id}'
                    .toUpperCase(),
                style: AppTheme.labelCaps(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fastfood,
                  size: 24,
                  color: AppColors.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyMd().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$toko • ${widget.order.quantity}x Porsi',
                      style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _manifestRow('Makanan Terselamatkan', Fmt.money(itemTotal)),
          const SizedBox(height: 6),
          _manifestRow('Biaya Pengantaran Eco-Fleet Instant', Fmt.money(fee)),
          if (initialTotal > 0) ...[
            const SizedBox(height: 6),
            _manifestRow(
              'Nilai Pasar Reguler',
              Fmt.money(initialTotal + fee),
              muted: true,
            ),
            const SizedBox(height: 6),
            _manifestRow(
              'Hemat Penyelamatanmu',
              '- ${Fmt.money(hemat)}',
              accent: true,
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Bayar', style: AppTheme.labelMd()),
              Text(
                Fmt.money(widget.order.totalAmount),
                style: AppTheme.metricSm().copyWith(fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _manifestRow(String label, String value,
      {bool muted = false, bool accent = false}) {
    final color = muted
        ? AppColors.outline
        : accent
            ? AppColors.primary
            : AppColors.onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodySm(color: muted ? color : AppColors.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
            decoration: muted ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }

  // ───────────────────────── IMPACT & GUARANTEE ─────────────────────────
  Widget _impactCard() {
    final kg = (widget.order.quantity * 0.6).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, size: 30, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Dampak kamu nyata: $kg kg sampah makanan nggak masuk TPA!',
              style: AppTheme.bodyMd().copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guaranteeCard() {
    return const Row(
      children: [
        Icon(Icons.shield, size: 18, color: AppColors.primary),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            '100% terlindungi sampai barang tiba.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// Painter rute putus-putus Jemput -> Kurir -> Kamu.
class _RutePainter extends CustomPainter {
  final List<Offset> points;
  _RutePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = const Color(0xFF8AB6E0)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final dashes = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (int i = 1; i < points.length; i++) {
      final a = Offset(points[i - 1].dx * size.width, points[i - 1].dy * size.height);
      final b = Offset(points[i].dx * size.width, points[i].dy * size.height);
      _drawDashed(canvas, a, b, paint, dashes, Colors.blue.shade600);
    }
  }

  void _drawDashed(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint halo,
    Paint outline,
    Color core,
  ) {
    canvas.drawLine(a, b, halo);
    canvas.drawLine(a, b, outline);
    const dash = 8.0;
    const gap = 6.0;
    final total = (b - a).distance;
    final unit = (b - a) / total;
    final corePaint = Paint()
      ..color = core
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    var acc = 0.0;
    while (acc < total) {
      final segLen = dash < total - acc ? dash : total - acc;
      canvas.drawLine(
        a + unit * acc,
        a + unit * (acc + segLen),
        corePaint,
      );
      acc += segLen + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RutePainter oldDelegate) => true;
}

// Painter peta: jalan chip & blok kota (tanpa SDK map).
class _PetaLandasanPainter extends CustomPainter {
  const _PetaLandasanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.surfaceContainerLow;
    canvas.drawRect(Offset.zero & size, bg);

    final jalan = Paint()
      ..color = const Color(0xFFFFFD74)
      ..strokeCap = StrokeCap.round;
    final blok = Paint()..color = const Color(0xFFE7E9E6);

    final rand = _PetaRand(size.width * 7, size.height * 13);
    for (int i = 0; i < 7; i++) {
      final horizontal = rand.f() > 0.5;
      final sw = 10.0 + rand.f() * 14;
      canvas.drawLine(
        Offset(
          rand.f() * size.width,
          horizontal ? rand.f() * size.height : 0,
        ),
        Offset(
          horizontal ? 0 : rand.f() * size.width,
          horizontal ? rand.f() * size.height : size.height,
        ),
        jalan..strokeWidth = sw,
      );
    }
    for (int i = 0; i < 26; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          rand.f() * size.width,
          rand.f() * size.height,
          14 + rand.f() * 26,
          10 + rand.f() * 18,
        ),
        blok,
      );
    }
    final hijau = Paint()..color = const Color(0xFFDDF3E3);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.55, 90, 70),
      hijau,
    );
  }

  @override
  bool shouldRepaint(covariant _PetaLandasanPainter oldDelegate) => false;
}

class _PetaRand {
  int _s;
  _PetaRand(double a, double b) : _s = (a.toInt() ^ b.toInt());
  double f() {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return _s / 0x7fffffff;
  }
}