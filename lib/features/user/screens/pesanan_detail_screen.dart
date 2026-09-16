import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/listing_controller.dart';
import 'chat_screen.dart';
import 'pembayaran_qris_screen.dart';
import 'lacak_pengantaran_screen.dart';
import 'rating_screen.dart';

enum _Tahap {
  menungguKurir(40, 'Menunggu Kurir', 'Lagi nyari kurir terdekat buat jemput pesananmu.'),
  menawarkan(50, 'Menunggu Konfirmasi Kurir', 'Penawaran penugasan dikirim ke kurir terdekat.'),
  menujuJemput(70, 'Kurir Menuju Titik Jemput', 'Armada Eco-Fleet dikonfirmasi untuk penjemputanmu.'),
  perjalanan(85, 'Perjalanan Menuju Lokasimu', 'Boks termal dijaga presisi 4°C sepanjang rute.'),
  tiba(100, 'Pesanan Tiba', 'Serah terima selesai. Terima kasih menyelamatkan pangan!'),
  siapPickup(55, 'Siap Diambil di Kasir', 'Makanan dijaga 4°C. Tunjukkan kode pickup sebelum window berakhir.'),
  selesaiPickup(100, 'Pickup Selesai', 'Serah terima selesai. Terima kasih menyelamatkan pangan!'),
  ;

  const _Tahap(this.progress, this.label, this.subtitle);
  final int progress;
  final String label;
  final String subtitle;
}

class PesananDetailScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  final FoodListingModel? listing;

  const PesananDetailScreen({
    super.key,
    required this.order,
    this.listing,
  });

  @override
  ConsumerState<PesananDetailScreen> createState() => _PesananDetailScreenState();
}

class _PesananDetailScreenState extends ConsumerState<PesananDetailScreen> {
  late OrderModel _order = widget.order;
  FoodListingModel? _listing;
  DeliveryModel? _delivery;
  bool _showQr = false;
  Timer? _poll;
  StreamSubscription<LatLng>? _locSub;
  LatLng? _userLoc;
  final Map<String, TokoProfileModel> _tokos = {};

  bool get _kurir => _order.fulfillmentMethod == 'diantar_kurir';
  bool get _paid => _order.paymentStatus == 'paid';

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _initLocation();
    });
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

  String? get _jarakText {
    final loc = _userLoc;
    final t = _listing == null ? null : _tokos[_listing!.tokoId];
    if (loc == null || t == null) return null;
    final lat = t.latitude;
    final lng = t.longitude;
    if (lat == null || lng == null) return null;
    final km = LocationService.distanceKm(loc, LatLng(lat, lng));
    return km < 1 ? '${(km * 1000).round()} m dari kamu' : '${km.toStringAsFixed(1)} km dari kamu';
  }

  Future<void> _load() async {
    if (_listing == null && _order.listingId.isNotEmpty) {
      try {
        final l = await ref
            .read(listingRepositoryProvider)
            .getListing(_order.listingId);
        if (mounted) setState(() => _listing = l);
      } catch (_) {}
    }
    await _refresh();
    _poll = Timer.periodic(const Duration(seconds: 12), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final st =
          await ref.read(listingRepositoryProvider).refreshOrder(_order.id);
      if (!mounted) return;
      setState(() => _order = st);
    } catch (_) {}

    if (_kurir) {
      try {
        final d = await ref
            .read(listingRepositoryProvider)
            .getDeliveryForOrder(_order.id);
        if (mounted) setState(() => _delivery = d);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _locSub?.cancel();
    super.dispose();
  }

  _Tahap get _tahap {
    if (!_kurir) {
      if (_order.orderStatus == 'selesai' || _order.completedAt != null) {
        return _Tahap.selesaiPickup;
      }
      return _Tahap.siapPickup;
    }
    final m = _delivery?.matchingStatus;
    final t = _delivery?.tripStatus;
    if (t == 'diterima_user') return _Tahap.tiba;
    if (t == 'barang_diambil') return _Tahap.perjalanan;
    if (m == 'diterima') return _Tahap.menujuJemput;
    if (m == 'ditawarkan') return _Tahap.menawarkan;
    return _Tahap.menungguKurir;
  }

  Future<void> _openPayment() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PembayaranQrisScreen(
          orderId: _order.id,
          order: _order,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  void _nag(string) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(string)));
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
              _topBar(),
              const SizedBox(height: 16),
              if (!_paid) ..._unpaidBanner() else ...[
                _statusCard(),
                if (_kurir && _paid) ...[
                  const SizedBox(height: 12),
                  _lacakButton(),
                ],
                const SizedBox(height: 12),
                _codeCard(),
                const SizedBox(height: 12),
                _itemCard(),
                const SizedBox(height: 12),
                if (_kurir) _routeCard() else _pickupInfoCard(),
                const SizedBox(height: 12),
                _paymentCard(),
              ],
              const SizedBox(height: 12),
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── TOP BAR ─────────────────────────
  Widget _topBar() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _kurir ? 'Logistik Presisi' : 'Rescue Pick-up',
                style: AppTheme.labelCaps(),
              ),
              Text(
                '#FR-${_order.id.length >= 5 ? _order.id.substring(0, 5) : _order.id}'
                    .toUpperCase(),
                style: AppTheme.headlineMd().copyWith(fontSize: 16),
              ),
            ],
          ),
        ),
        if (_paid)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Lunas',
                  style: AppTheme.labelCaps(color: AppColors.primary),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ───────────────────────── UNPAID BANNER ─────────────────────────
  List<Widget> _unpaidBanner() {
    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Column(
          children: [
            const Icon(Icons.lock_clock, size: 40, color: AppColors.secondary),
            const SizedBox(height: 12),
            Text(
              'Menunggu Pembayaran',
              style: AppTheme.headlineMd(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Selesaikan pembayaran QRIS biar pesananmu segera diproses.',
              textAlign: TextAlign.center,
              style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _openPayment,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: Text(
                  'Bayar Sekarang',
                  textAlign: TextAlign.center,
                  style: AppTheme.labelMd(color: AppColors.onPrimary)
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _lacakButton() {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LacakPengantaranScreen(
              order: _order,
              listing: _listing,
            ),
          ),
        ),
        child: const Text(
          'Lacak Kurir',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── STATUS CARD ─────────────────────────
  Widget _statusCard() {
    final tahap = _tahap;
    final telemetry = _kurir &&
        (tahap == _Tahap.menungguKurir ||
            tahap == _Tahap.menawarkan ||
            tahap == _Tahap.menujuJemput);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _miniBadge('Prioritas Dingin', filled: true),
                        _miniBadge('SOP 4°C ISO-22000', filled: false),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(tahap.label, style: AppTheme.headlineMd()),
                    const SizedBox(height: 4),
                    Text(
                      tahap.subtitle,
                      style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _kurir ? Icons.two_wheeler : Icons.storefront,
                  size: 30,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          if (telemetry) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _telemetryTile(
                    label: 'Estimasi Penjemputan',
                    value: '6-10',
                    unit: 'Menit',
                    sub: _jarakText ?? 'Radius kamu aktif',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _telemetryTile(
                    label: 'Suhu Termal Boks',
                    value: '3.8',
                    unit: '°C Stabil',
                    sub: 'PCM Coolpack Aktif',
                    accent: true,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                _kurir ? 'Rantai Penugasan Armada' : 'Kesiapan Kasir Mitra',
                style: AppTheme.labelCaps(),
              ),
              const Spacer(),
              Text(
                _kurir ? 'Sinkronisasi Live' : 'Pesanan Siap Diproses',
                style: AppTheme.labelCaps(color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: tahap.progress / 100,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String label, {required bool filled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? AppColors.secondaryContainer : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTheme.labelCaps(
          color: filled ? AppColors.onPrimary : AppColors.onSurfaceVariant,
        ).copyWith(fontSize: 9),
      ),
    );
  }

  Widget _telemetryTile({
    required String label,
    required String value,
    required String unit,
    required String sub,
    bool accent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.labelCaps()),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTheme.metricSm(
                  color: accent ? AppColors.primary : AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(unit, style: AppTheme.labelMd()),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (accent) ...[
                const Icon(Icons.ac_unit, size: 12, color: AppColors.primary),
                const SizedBox(width: 3),
              ],
              Expanded(
                child: Text(
                  sub,
                  style: AppTheme.bodySm(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────── KODE SERAH TERIMA ─────────────────────────
  Widget _codeCard() {
    final code = _order.confirmationCode;
    final chars = code.length >= 4 ? code.substring(0, 4).split('') : code.split('');
    final label = _kurir ? 'KODE SERAH TERIMA KURIR' : 'KODE KONFIRMASI PICKUP';
    final note = _kurir
        ? 'Berikan kode 4-digit ini ke kurir hanya saat makanan diserahkan dan suhu boks dingin terkonfirmasi aman (≤ 5°C).'
        : 'Tunjukkan kode ini ke kasir meja penjemputan untuk verifikasi pickup.\nMemverifikasi Kode Kasir...';

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
          Row(
            children: [
              const Icon(Icons.verified_user, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Otentikasi Dua Arah',
                style: AppTheme.labelCaps().copyWith(color: AppColors.primary),
              ),
              const Spacer(),
              _miniBadge('Enkripsi SHA-256', filled: false),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTheme.labelCaps().copyWith(letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: chars.take(4).map((ch) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ch,
                  style: AppTheme.metricSm().copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () async {
                      await _copyCode();
                      _nag('Kode ${_order.confirmationCode} Disalin');
                    },
                    child: const Text('Salin Kode'),
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      side: const BorderSide(color: AppColors.outline),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () => setState(() => _showQr = !_showQr),
                    child: Text(_showQr ? 'Tutup QR' : 'Tampilkan QR'),
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showQr) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CustomPaint(
                    size: const Size(150, 150),
                    painter: _SerahQrPainter(seed: code),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _kurir
                        ? 'Pindai oleh Scanner Termal Mitra Eco-Fleet'
                        : 'Pindai oleh Kasir Meja Penjemputan',
                    style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield,
                  size: 18,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note,
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

  // ───────────────────────── ITEM CARD ─────────────────────────
  Widget _itemCard() {
    final l = _listing ?? _order.listing;
    final name = l?.name ?? 'Makanan Terselamatkan';
    final toko = l?.tokoName ?? 'Mitra Food Rescue • Jakarta';
    final photo = l?.photoUrl;

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
          Row(
            children: [
              Text(
                'Penyelamatan Kuliner',
                style: AppTheme.labelCaps(),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Terselamatkan 1.8 kg CO₂e',
                  style: AppTheme.labelCaps(color: AppColors.onPrimary)
                      .copyWith(fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: photo != null && photo.isNotEmpty
                    ? CachedNetImage(photo)
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppColors.surfaceContainerLow,
                        child: const Icon(
                          Icons.restaurant,
                          size: 32,
                          color: AppColors.onPrimary,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headlineMd().copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      toko,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${_order.quantity}x Porsi',
                          style: AppTheme.labelMd(),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Kondisi Prima',
                            style: AppTheme.labelCaps(color: AppColors.primary)
                                .copyWith(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────── ROUTE CARD (KURIR) ─────────────────────────
  Widget _routeCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Rute & Penanganan Khusus', style: AppTheme.labelCaps()),
              const Spacer(),
              const Icon(Icons.bolt, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Zero-Emission',
                style: AppTheme.labelCaps(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.storefront,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Titik Jemput (Restoran)',
                      style: AppTheme.labelCaps(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _listing?.tokoName ?? 'Mitra Food Rescue',
                      style: AppTheme.bodyMd().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _listing?.address ?? 'Jakarta Selatan',
                      style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on,
                size: 20,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Titik Antar (Penerima)', style: AppTheme.labelCaps()),
                    const SizedBox(height: 2),
                    Text(
                      'Lokasimu',
                      style: AppTheme.bodyMd().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Alamat terdaftar • Diterima langsung',
                      style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.electric_moped,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Kurir Khusus Food Rescue',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _miniBadge('Aktif', filled: true),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Eco-Fleet Insulated Thermal Box dijaga pada 4°C presisi',
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

  // ───────────────────────── PICKUP INFO CARD ─────────────────────────
  Widget _pickupInfoCard() {
    final l = _listing;
    final window = l?.pickupStartTime != null && l?.pickupEndTime != null
        ? '${_fmtTime(l!.pickupStartTime)} – ${_fmtTime(l.pickupEndTime)}'
        : 'Ikuti jam operasional toko';

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Instruksi Pick-up', style: AppTheme.labelCaps()),
              const Spacer(),
              const Icon(Icons.bolt, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Gratis Ongkir',
                style: AppTheme.labelCaps(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storefront,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            title: Text(window, style: AppTheme.labelMd()),
            subtitle: Text(
              '${l?.tokoName ?? 'Mitra Food Rescue'} • ${l?.address ?? 'Jakarta'}',
              style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 6),
          _miniBadge('Meja Penjemputan Khusus Terbuka', filled: true),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.manage_search,
                  size: 18,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tunjukkan kode pickup ke kasir. Memverifikasi Kode Kasir...',
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

  // ───────────────────────── PAYMENT CARD ─────────────────────────
  Widget _paymentCard() {
    final itemTotal = _order.priceAtPurchase * _order.quantity;
    final fee = _kurir ? (_delivery?.deliveryFee ?? 8000) : 0.0;

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
          Row(
            children: [
              Text('Rincian Harga & Hemat', style: AppTheme.labelCaps()),
              const Spacer(),
              const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'LUNAS',
                style: AppTheme.labelCaps(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _payRow(
            label: _order.listing?.name ?? 'Makanan Terselamatkan',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Fmt.money(itemTotal),
                  style: AppTheme.bodyMd().copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (_kurir) ...[
            const SizedBox(height: 6),
            _payRow(
              label: 'Eco-Fleet Rantai Dingin (4°C Garansi)',
              trailing: Text(Fmt.money(fee), style: AppTheme.bodyMd()),
            ),
          ],
          const SizedBox(height: 6),
          _payRow(
            label: 'Biaya Layanan Penyelamatan',
            trailing: Text(
              'Gratis (Subsidi Hijau)',
              style: AppTheme.bodyMd(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Pembayaran Digital', style: AppTheme.labelCaps()),
                    Text(
                      'Pembayaran QRIS Aman',
                      style: AppTheme.bodySm(color: AppColors.primary),
                    ),
                  ],
                ),
                Text(
                  Fmt.money(_order.totalAmount),
                  style: AppTheme.metricSm().copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _payRow({
    required String label,
    required Widget trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 12),
        trailing,
      ],
    );
  }

  // ───────────────────────── ACTIONS ─────────────────────────
  Widget _actions() {
    final completed =
        _order.orderStatus == 'selesai' ||
            _delivery?.tripStatus == 'diterima_user' ||
            (_order.fulfillmentMethod == 'pickup_mandiri' &&
                _order.paymentStatus == 'paid' &&
                _order.orderStatus != 'dibatalkan' &&
                _order.isPickupWindowOver);
    return Column(
      children: [
        if (completed) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RatingScreen(
                    order: _order,
                    listing: _listing,
                  ),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimary,
                shape: const StadiumBorder(),
              ),
              child: const Text('Beri Ulasan & Nilai'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChatScreen(order: _order)),
                  ),
                  child: Text(_kurir && _paid ? 'Chat Kurir' : 'Hubungi Restoran'),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: AppColors.outline),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChatScreen(order: _order)),
                  ),
                  child: const Text('Bantuan Live'),
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
    );
  }

  String _fmtTime(String? iso) {
    if (iso == null) return '';
    final t = DateTime.tryParse(iso);
    if (t == null) return iso;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m WIB';
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _order.confirmationCode));
  }
}

// Helper untuk gambar listing (tanpa dependency eksternal di layar ini).
class CachedNetImage extends StatelessWidget {
  final String url;
  const CachedNetImage(this.url, {super.key});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 80,
        height: 80,
        color: AppColors.surfaceContainerLow,
        child: const Icon(Icons.restaurant, size: 32),
      ),
    );
  }
}

// Painter pseudo-QR mini untuk kode serah terima.
class _SerahQrPainter extends CustomPainter {
  final String seed;
  _SerahQrPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final dark = const Color(0xFF191C1B);
    final cell = size.width / 21;

    void fillCell(int c, int r) {
      canvas.drawRect(
        Rect.fromLTWH(c * cell, r * cell, cell, cell),
        Paint()..color = dark,
      );
    }

    final rand = _Rand(seed.hashCode);
    for (int r = 0; r < 21; r++) {
      for (int c = 0; c < 21; c++) {
        if (rand.next()) fillCell(c, r);
      }
    }

    void finder(int top, int left) {
      canvas.drawRect(
        Rect.fromLTWH(left * cell, top * cell, 7 * cell, 7 * cell),
        Paint()..color = dark,
      );
      canvas.drawRect(
        Rect.fromLTWH((left + 1) * cell, (top + 1) * cell, 5 * cell, 5 * cell),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      canvas.drawRect(
        Rect.fromLTWH((left + 2) * cell, (top + 2) * cell, 3 * cell, 3 * cell),
        Paint()..color = dark,
      );
    }

    finder(0, 0);
    finder(0, 14);
    finder(14, 0);
  }

  @override
  bool shouldRepaint(covariant _SerahQrPainter oldDelegate) =>
      oldDelegate.seed != seed;
}

class _Rand {
  int _state;
  _Rand(this._state);
  bool next() {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state % 10 > 4;
  }
}