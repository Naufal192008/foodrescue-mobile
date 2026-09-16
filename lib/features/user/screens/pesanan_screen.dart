import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../controllers/order_controller.dart';
import 'pesanan_detail_screen.dart';
import 'rating_screen.dart';
import 'user_layout.dart';

enum OrderFilter { all, unpaid, active, completed }
enum OrderTimeFilter { all, today, week, month }

List<OrderModel> applyOrderFilter(List<OrderModel> items, OrderFilter filter) {
  switch (filter) {
    case OrderFilter.unpaid:
      return items.where((order) {
        final unpaid = order.paymentStatus != 'paid' || order.confirmationCode.isEmpty;
        return unpaid;
      }).toList();
    case OrderFilter.active:
      return items.where((order) {
        final paid = order.paymentStatus == 'paid';
        final active = order.orderStatus != 'selesai' && order.orderStatus != 'dibatalkan';
        return paid && active;
      }).toList();
    case OrderFilter.completed:
      return items.where((order) {
        final done = order.orderStatus == 'selesai';
        return done;
      }).toList();
    case OrderFilter.all:
      return items;
  }
}

List<OrderModel> applyOrderTimeFilter(
  List<OrderModel> items,
  OrderTimeFilter filter, {
  DateTime? now,
}) {
  if (filter == OrderTimeFilter.all) return items;
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  return items.where((order) {
    final createdAt = order.createdAt?.toLocal();
    if (createdAt == null) return false;
    switch (filter) {
      case OrderTimeFilter.today:
        return !createdAt.isBefore(today);
      case OrderTimeFilter.week:
        return !createdAt.isBefore(today.subtract(const Duration(days: 6)));
      case OrderTimeFilter.month:
        return createdAt.year == today.year && createdAt.month == today.month;
      case OrderTimeFilter.all:
        return true;
    }
  }).toList();
}

class PesananScreen extends ConsumerStatefulWidget {
  const PesananScreen({super.key});

  @override
  ConsumerState<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends ConsumerState<PesananScreen> {
  List<OrderModel>? _orders;
  bool _loading = true;
  String? _error;
  OrderFilter _filter = OrderFilter.all;
  OrderTimeFilter _timeFilter = OrderTimeFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
    AppNav.tabIndex.addListener(_onTab);
  }

  void _onTab() {
    if (AppNav.tabIndex.value == AppNav.pesanan) _fetch();
  }

  @override
  void dispose() {
    AppNav.tabIndex.removeListener(_onTab);
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = _orders == null;
      _error = null;
    });
    try {
      final list = await ref.read(orderStateProvider.notifier).fetchMyOrders();
      if (!mounted) return;
      setState(() {
        _orders = list;
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

  @override
  Widget build(BuildContext context) {
    final orders = _orders ?? [];
    final filtered = applyOrderTimeFilter(
      applyOrderFilter(orders, _filter),
      _timeFilter,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Text('Pesanan', style: AppTheme.headlineMd()),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Muat ulang',
                    onPressed: _fetch,
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14005321),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total aktif', style: AppTheme.labelCaps(color: AppColors.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(
                            '${applyOrderFilter(orders, OrderFilter.active).length}',
                            style: AppTheme.headlineMd().copyWith(fontSize: 28),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Belum bayar', style: AppTheme.labelCaps(color: AppColors.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(
                            '${applyOrderFilter(orders, OrderFilter.unpaid).length}',
                            style: AppTheme.headlineMd().copyWith(fontSize: 28, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: OrderFilter.values.map((filter) {
                    final selected = filter == _filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_labelFilter(filter)),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = filter),
                        selectedColor: AppColors.primaryContainer,
                        backgroundColor: AppColors.surfaceContainerLowest,
                        labelStyle: AppTheme.labelMd(
                          color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                        ),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: OrderTimeFilter.values.map((filter) {
                    final selected = filter == _timeFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: const Icon(Icons.schedule, size: 16),
                        label: Text(_labelTimeFilter(filter)),
                        selected: selected,
                        onSelected: (_) => setState(() => _timeFilter = filter),
                        selectedColor: AppColors.secondaryContainer,
                        backgroundColor: AppColors.surfaceContainerLowest,
                        labelStyle: AppTheme.labelMd(
                          color: selected ? AppColors.onSecondary : AppColors.onSurfaceVariant,
                        ),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: _buildBody(filtered),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFilter(OrderFilter filter) {
    switch (filter) {
      case OrderFilter.unpaid:
        return 'Belum bayar';
      case OrderFilter.active:
        return 'Aktif';
      case OrderFilter.completed:
        return 'Selesai';
      case OrderFilter.all:
        return 'Semua';
    }
  }

  String _labelTimeFilter(OrderTimeFilter filter) {
    switch (filter) {
      case OrderTimeFilter.today:
        return 'Hari ini';
      case OrderTimeFilter.week:
        return '7 hari';
      case OrderTimeFilter.month:
        return 'Bulan ini';
      case OrderTimeFilter.all:
        return 'Semua waktu';
    }
  }

  Widget _buildBody(List<OrderModel> filteredOrders) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }
    if (_error != null && (_orders == null || _orders!.isEmpty)) {
      return AppErrorView(message: _error!, onRetry: _fetch);
    }
    final orders = filteredOrders;
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            AppEmptyState(
              icon: Icons.receipt_long,
              message: _filter == OrderFilter.all
                  ? 'Belum ada pesanan.\nYuk amankan makanan sebelum terbuang!'
                  : 'Belum ada pesanan di kategori ini.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
        itemCount: orders.length,
        itemBuilder: (_, i) {
          final order = orders[i];
          return InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PesananDetailScreen(order: order),
              ),
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: _OrderCard(
              order: order,
              onRate: _rateable(order)
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RatingScreen(order: order),
                        ),
                      )
                  : null,
            ),
          );
        },
      ),
    );
  }

  bool _rateable(OrderModel o) {
    if (o.orderStatus == 'selesai') return true;
    if (o.orderStatus == 'dibatalkan') return false;
    if (o.fulfillmentMethod == 'pickup_mandiri' &&
        o.paymentStatus == 'paid' &&
        o.isPickupWindowOver) {
      return true;
    }
    return false;
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onRate;

  const _OrderCard({required this.order, this.onRate});

  (String, Color) get _status {
    final paid = order.paymentStatus == 'paid';
    if (order.confirmationCode.isEmpty) {
      return ('Menunggu Pembayaran', AppColors.secondary);
    }
    if (!paid) {
      return ('Menunggu Pembayaran', AppColors.secondary);
    }
    return ('Menunggu Pickup', AppColors.primary);
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = _status;
    final kurir = order.fulfillmentMethod == 'diantar_kurir';
    final name = order.listing?.name ?? 'Makanan terselamatkan';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: AppColors.onPrimary,
                  size: 22,
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
                      style: AppTheme.bodyMd().copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.quantity} porsi • '
                      '${kurir ? 'Kurir' : 'Self Pick-up'}',
                      style: AppTheme.labelCaps(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (order.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Dipesan ${Fmt.dateTime(order.createdAt!)}',
                        style: AppTheme.labelCaps(color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
                child: Text(
                  label,
                  style: AppTheme.labelCaps(
                    color: AppColors.onPrimary,
                  ).copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('KODE', style: AppTheme.labelCaps(color: AppColors.outline)),
              const SizedBox(width: 8),
              Text(
                order.confirmationCode.isEmpty ? '••••••' : order.confirmationCode,
                style: AppTheme.labelMd(color: AppColors.primary)
                    .copyWith(fontWeight: FontWeight.w700, letterSpacing: 2),
              ),
              const Spacer(),
              Text(
                Fmt.money(order.totalAmount),
                style: AppTheme.metricSm().copyWith(fontSize: 18),
              ),
            ],
          ),
          if (onRate != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: onRate,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  minimumSize: Size.zero,
                ),
                child: const Text('Beri Ulasan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}