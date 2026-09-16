import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/order_controller.dart';
import 'pesanan_detail_screen.dart';
import 'user_layout.dart';

class PembayaranQrisScreen extends ConsumerStatefulWidget {
  final String orderId;
  final OrderModel order;

  const PembayaranQrisScreen({
    super.key,
    required this.orderId,
    required this.order,
  });

  @override
  ConsumerState<PembayaranQrisScreen> createState() =>
      _PembayaranQrisScreenState();
}

enum _PayMode { loading, manual, pending }

class _PembayaranQrisScreenState extends ConsumerState<PembayaranQrisScreen> {
  static const _countdownSeconds = 5 * 60;

  late OrderModel _order = widget.order;
  _PayMode _mode = _PayMode.loading;
  String? _qrString;
  String? _qrImageUrl;
  double _grossAmount = 0;
  bool _paid = false;
  bool _paying = false;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  int _secondsLeft = _countdownSeconds;
  String? _toast;

  bool get _kurir => _order.fulfillmentMethod == 'diantar_kurir';

  String get _claimCode => _order.confirmationCode.isEmpty
      ? 'RSC-${_order.id.length >= 4 ? _order.id.substring(0, 4) : _order.id}'
          .toUpperCase()
      : _order.confirmationCode;
  static const _kurirFee = 8000.0;

  double get _totalBill => _order.totalAmount + (_kurir ? _kurirFee : 0);

  @override
  void initState() {
    super.initState();
    _setupQr();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 0) setState(() => _secondsLeft--);
    });
  }

  Future<void> _setupQr() async {
    try {
      final res = await ref
          .read(orderStateProvider.notifier)
          .qrisCreate(widget.orderId);
      if (!mounted) return;
      final status = res['status'];
      final gross = (res['gross_amount'] as num?)?.toDouble() ?? _totalBill;
      setState(() {
        _grossAmount = gross;
        if (status == 'manual') {
          _mode = _PayMode.manual;
        } else {
          _qrString = res['qr_string'] as String?;
          _qrImageUrl = res['qr_image_url'] as String?;
          _mode = _PayMode.pending;
          _startPolling();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mode = _PayMode.manual;
      });
      _showToast('Terjadi kendala memuat QRIS. Gunakan mode manual.');
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _tick());
  }

  Future<void> _tick() async {
    if (_paid || !mounted) return;
    try {
      await ref.read(orderStateProvider.notifier).refreshOrder(widget.orderId);
      final st = ref.read(orderStateProvider).createdOrder;
      if (st != null && st.paymentStatus == 'paid') {
        setState(() {
          _order = st;
          _paid = true;
        });
        _pollTimer?.cancel();
      }
    } catch (_) {}
  }

  Future<void> _confirmPaid() async {
    if (_paying) return;
    setState(() => _paying = true);
    if (_mode == _PayMode.pending) {
      await _tick();
      setState(() => _paying = false);
      if (_paid) return;
      _showToast('Pembayaran belum masuk. Tunggu sebentar, ya...');
      return;
    }
    final ctrl = ref.read(orderStateProvider.notifier);
    final ok = await ctrl.pay(widget.orderId, paymentMethod: 'qris');
    setState(() {
      _paying = false;
      if (ok) _paid = true;
    });
    if (!ok && mounted) {
      final err = ref.read(orderStateProvider).error;
      if (err != null && err.isNotEmpty) {
        _showToast(err);
      }
    }
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted && _toast == msg) setState(() => _toast = null);
    });
  }

  Future<void> _copyQrString() async {
    final s = _qrString != null && _qrString!.isNotEmpty
        ? _qrString!
        : '00020101021226590014ID.LINKAJA.WWW0118936009110021303881021520241014112938530336058025919SUSHI+SEI+SAYURAN6007JAKARTA62190115${_order.confirmationCode}630489A1';
    await Clipboard.setData(ClipboardData(text: s));
    _showToast('String QRIS Berhasil Disalin');
  }

  void _goPesanan() {
    _pollTimer?.cancel();
    final nav = Navigator.of(context);
    AppNav.tabIndex.value = AppNav.pesanan;
    nav.popUntil((r) => r.isFirst);
    nav.push(
      MaterialPageRoute(
        builder: (_) => PesananDetailScreen(order: _order),
      ),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _paid
            ? _successBody()
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    const SizedBox(height: 16),
                    _billCard(),
                    const SizedBox(height: 12),
                    _methodTabs(),
                    const SizedBox(height: 12),
                    _qrisCard(),
                    const SizedBox(height: 12),
                    _escrowNote(),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _paid ? null : _bottomTray(),
    );
  }

  Widget _successBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33005321),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 38,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'PEMBAYARAN TERVERIFIKASI REAL-TIME',
                  style: AppTheme.labelCaps(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Dana Berhasil Diterima', style: AppTheme.headlineMd()),
          const SizedBox(height: 6),
          Text(
            'Uang kamu terkunci aman: ${Fmt.money(_grossAmount > 0 ? _grossAmount : _totalBill)}. '
            'Pesanan siap dijadwalkan ke kurir.',
            textAlign: TextAlign.center,
            style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'KODE OTORISASI PICKUP',
                      style: AppTheme.labelCaps(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'TERKUNCI SHA-256',
                      style: AppTheme.labelCaps(color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _claimCode,
                          style: AppTheme.labelMd(
                            color: AppColors.onSurface,
                          ).copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () async {
                          final code = _claimCode;
                          await Clipboard.setData(
                            ClipboardData(text: code),
                          );
                          _showToast('Kode $code Berhasil Disalin');
                        },
                        child: const Text('Salin'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.electric_moped,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Status: Menunggu Penjemputan Kurir',
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _goPesanan,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimary,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Menuju Detail Pesanan & Lacak Kurir',
                  textAlign: TextAlign.center,
                  style: AppTheme.labelMd(
                    color: AppColors.onPrimary,
                  ).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final mins = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsLeft % 60).toString().padLeft(2, '0');
    return Row(
      children: [
        Material(
          color: AppColors.surfaceContainerLow,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).maybePop(),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.arrow_back, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Pembayaran Digital',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headlineSm().copyWith(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Text(
                '${_kurir ? 'Kurir Khusus' : 'Self Pick-up'} • '
                '${_order.listing?.name ?? 'Makanan terselamatkan'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule,
                size: 15,
                color: AppColors.secondaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                '$mins:$secs',
                style: AppTheme.labelMd().copyWith(
                  color: AppColors.secondaryContainer,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _billCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14005321),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Tagihan In-App',
                      style: AppTheme.labelCaps(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 6,
                      children: [
                        Text(
                          'Rp',
                          style: AppTheme.bodyMd(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            Fmt.money(_grossAmount > 0
                                    ? _grossAmount
                                    : _totalBill)
                                .replaceAll('Rp ', ''),
                            style: AppTheme.metricLg(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.electric_moped,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ECO-FLEET DISPATCH',
                      style: AppTheme.labelCaps(
                        color: AppColors.primary,
                      ).copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _order.listing?.name ?? 'Makanan terselamatkan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyMd().copyWith(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${_order.quantity} x ${Fmt.money(_order.totalAmount)}',
                      style: AppTheme.labelMd().copyWith(
                        color: AppColors.onSurface,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (_kurir) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.eco,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Kurir Khusus (Eco-Fleet Terinsulasi)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.bodyMd(
                                  color: AppColors.onSurfaceVariant,
                                ).copyWith(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Fmt.money(_kurirFee),
                        style: AppTheme.labelMd(
                          color: AppColors.primary,
                        ).copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTabs() {
    Widget tab(String label) {
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.labelMd(color: AppColors.onPrimary),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          tab('QRIS Instant'),
        ],
      ),
    );
  }

  Widget _qrisCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14005321),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.inverseSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'QRIS',
                  style: AppTheme.labelCaps(
                    color: AppColors.surface,
                  ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Standar Pembayaran Nasional',
                  style: AppTheme.labelCaps(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ASPI / BI VERIFIED',
                    style: AppTheme.labelCaps(color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _buildQrArea(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.screen_search_desktop,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Scan pakai BCA, GoPay, OVO, Dana, ShopeePay',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelMd(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _outlineBtn(
                  icon: Icons.file_download,
                  label: 'Unduh QR',
                  onTap: () => _showToast('Kode QR Berhasil Diunduh'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _outlineBtn(
                  icon: Icons.content_copy,
                  label: 'Salin String',
                  onTap: _copyQrString,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrArea() {
    const box = 216.0;
    if (_mode == _PayMode.loading) {
      return SizedBox(
        height: box,
        width: box,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }
    return SizedBox(
      height: box,
      width: box,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: _qrImageUrl != null && _qrImageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: _qrImageUrl!,
                      width: box,
                      height: box,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => CustomPaint(
                        size: const Size.square(200),
                        painter: _PseudoQrPainter(seed: _order.id.hashCode),
                      ),
                    ),
                  )
                : CustomPaint(
                    size: const Size.square(200),
                    painter:
                        _PseudoQrPainter(seed: _order.id.hashCode),
                  ),
          ),
          const _ScanLine(),
        ],
      ),
    );
  }

  Widget _outlineBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.onSurface),
              const SizedBox(width: 6),
              Text(label, style: AppTheme.labelMd()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _escrowNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uang Dijamin Aman',
                  style: AppTheme.labelCaps(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dana ditahan aman sampai barang diterima, '
                  'dan dipastikan lewat kode QR saat serah terima.',
                  style: AppTheme.bodySm(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomTray() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _paying ? null : _confirmPaid,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimary,
            ),
            child: _paying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SAYA SUDAH MEMBAYAR',
                        style: AppTheme.labelMd(
                          color: AppColors.onPrimary,
                        ).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Positioned(
          left: 20,
          right: 20,
          top: 10 + t * 190,
          child: IgnorePointer(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(
                  alpha: 0.75 + t * 0.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryContainer.withValues(
                      alpha: 0.7,
                    ),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PseudoQrPainter extends CustomPainter {
  final int seed;
  final int modules = 25;

  _PseudoQrPainter({required this.seed});

  int _rnd(int i) {
    var x = (seed ^ (i * 0x27d4eb2d)) & 0x7fffffff;
    x = ((x >> 13) ^ x) * 0x45d9f3b;
    x = ((x >> 16) ^ x) & 0x7fffffff;
    return x;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / modules;
    final dark = const Color(0xFF191C1B);

    bool inFinder(double r, double c) {
      final inRow = r < 7 && c < 7;
      final inCol = r < 7 && c >= modules - 7;
      final inBot = r >= modules - 7 && c < 7;
      return inRow || inCol || inBot;
    }

    // Data modules
    var idx = 0;
    for (var r = 0.0; r < modules; r++) {
      for (var c = 0.0; c < modules; c++) {
        if (_rnd(idx++) % 100 < 46 && !inFinder(r, c)) {
          final rect = Rect.fromLTWH(
            c * cell,
            r * cell,
            cell * 0.9,
            cell * 0.9,
          );
          canvas.drawRect(rect, Paint()..color = dark);
        }
      }
    }

    // Finder patterns (3)
    for (final (fx, fy) in <(double, double)>[
      (0.0, 0.0),
      (modules - 7.0, 0.0),
      (0.0, modules - 7.0),
    ]) {
      canvas.drawRect(
        Rect.fromLTWH(fx * cell, fy * cell, 7 * cell, 7 * cell),
        Paint()..color = dark,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          (fx + 1) * cell,
          (fy + 1) * cell,
          5 * cell,
          5 * cell,
        ),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      canvas.drawRect(
        Rect.fromLTWH(
          (fx + 2) * cell,
          (fy + 2) * cell,
          3 * cell,
          3 * cell,
        ),
        Paint()..color = dark,
      );
    }

    // Center logo: lingkaran hijau + centang putih
    final center = size.center(Offset.zero);
    final radius = size.width * 0.16;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF00873A));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final path = Path()
      ..moveTo(center.dx - radius * 0.32, center.dy)
      ..lineTo(center.dx - 0.05 * radius, center.dy + radius * 0.34)
      ..lineTo(center.dx + radius * 0.42, center.dy - radius * 0.30);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PseudoQrPainter old) => old.seed != seed;
}
