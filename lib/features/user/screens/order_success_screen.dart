import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/order_controller.dart';
import 'pembayaran_qris_screen.dart';
import 'user_layout.dart';

class OrderSuccessScreen extends ConsumerStatefulWidget {
  final String orderId;
  final OrderModel order;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.order,
  });

  @override
  ConsumerState<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderStateProvider.notifier).setOrder(widget.order);
    });
  }

  Future<void> _openQris() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PembayaranQrisScreen(
          orderId: widget.orderId,
          order: widget.order,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  void _goPesanan() {
    AppNav.tabIndex.value = AppNav.pesanan;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderStateProvider);
    final order = state.createdOrder ?? widget.order;
    final paid = order.paymentStatus == 'paid';
    final kurir = order.fulfillmentMethod == 'diantar_kurir';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: paid
                      ? AppColors.primary
                      : AppColors.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33005321),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  paid ? Icons.check_circle : Icons.lock_clock,
                  size: 44,
                  color: AppColors.onPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                paid ? 'Pembayaran Lunas' : 'Slot Berhasil Dikunci',
                style: AppTheme.headlineLg(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                paid
                    ? 'Pesananmu sudah terbayar dan sedang diproses.'
                    : 'Harga sudah terkunci buat kamu. Selesaikan pembayaran biar pesanan segera diproses.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMd(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              _InfoCard(
                order: order,
                kurir: kurir,
                paid: paid,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: paid ? _goPesanan : _openQris,
                  child: state.isPaying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          paid
                              ? 'Lihat Pesanan'
                              : 'Bayar Sekarang',
                          style: AppTheme.labelMd(color: AppColors.onPrimary)
                              .copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              if (!paid)
                TextButton(
                  onPressed: _goPesanan,
                  child: const Text('Nanti saja'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final OrderModel order;
  final bool kurir;
  final bool paid;

  const _InfoCard({required this.order, required this.kurir, required this.paid});

  @override
  Widget build(BuildContext context) {
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
          if (order.listing != null) ...[
            _row(
              label: 'Makanan',
              value: order.listing!.name,
            ),
            const SizedBox(height: 10),
          ],
          _row(
            label: 'Jumlah',
            value: '${order.quantity} porsi',
          ),
          const SizedBox(height: 10),
          _row(
            label: 'Metode',
            value: kurir ? 'Diantar Kurir (+Rp 8.000)' : 'Self Pick-up',
          ),
          const SizedBox(height: 10),
          _row(
            label: 'Total',
            value: Fmt.money(order.totalAmount),
            emphasize: true,
          ),
          const Divider(height: 20),
          _row(
            label: 'Status',
            value: paid ? 'Lunas' : 'Menunggu Pembayaran',
            valueColor: paid ? AppColors.primary : AppColors.secondary,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('KODE KONFIRMASI', style: AppTheme.labelCaps()),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order.confirmationCode.isEmpty
                      ? '••••••'
                      : order.confirmationCode,
                  style: AppTheme.labelMd(color: AppColors.primary)
                      .copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row({
    required String label,
    required String value,
    bool emphasize = false,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: AppTheme.labelCaps()),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: emphasize
                ? AppTheme.metricSm().copyWith(fontSize: 20)
                : AppTheme.bodyMd(
                    color: valueColor ?? AppColors.onSurface,
                  ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}