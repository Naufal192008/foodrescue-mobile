import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/listing_controller.dart';
import 'user_layout.dart';

class DampakScreen extends ConsumerStatefulWidget {
  const DampakScreen({super.key});

  @override
  ConsumerState<DampakScreen> createState() => _DampakScreenState();
}

class _DampakScreenState extends ConsumerState<DampakScreen> {
  ImpactSummaryModel? _impact;
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pull());
    AppNav.tabIndex.addListener(_onTab);
  }

  void _onTab() {
    if (AppNav.tabIndex.value == AppNav.dampak && _orders.isNotEmpty) _pull();
  }

  @override
  void dispose() {
    AppNav.tabIndex.removeListener(_onTab);
    super.dispose();
  }

  Future<void> _pull() async {
    setState(() {
      _loading = _impact == null;
      _error = null;
    });
    try {
      final repo = ref.read(listingRepositoryProvider);
      final results = await Future.wait<Object>([
        repo.getMyImpact(),
        repo.getMyOrders(),
      ]);
      if (!mounted) return;
      setState(() {
        _impact = results[0] as ImpactSummaryModel;
        _orders = (results[1] as List).cast<OrderModel>();
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

  double get _spent =>
      _orders.fold(0, (sum, o) => sum + o.totalAmount);

  double get _value {
    double v = 0;
    for (final o in _orders) {
      final p = o.listing?.initialPrice ?? o.priceAtPurchase;
      v += p * o.quantity;
    }
    return v;
  }

  double get _efficiency {
    if (_value <= 0) return 0;
    return ((1 - _spent / _value) * 100).clamp(0, 99);
  }

  int get _proteinG => ((_impact?.totalFoodSavedKg ?? 0) * 80).round();

  String get _tier {
    final kg = _impact?.totalFoodSavedKg ?? 0;
    if (kg >= 40) return 'Titanium';
    if (kg >= 20) return 'Gold';
    if (kg >= 8) return 'Silver';
    return 'Bronze';
  }

  Map<String, int> get _composition {
    final map = <String, int>{};
    for (final o in _orders) {
      final c = o.listing?.category ?? 'Lainnya';
      map[c] = (map[c] ?? 0) + o.quantity;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _pull,
        child: _content(),
      ),
    );
  }

  Widget _content() {
    if (_loading && _impact == null) {
      return const SizedBox(
        height: 360,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_error != null && _impact == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 160),
          AppErrorView(message: _error!, onRetry: _pull),
        ],
      );
    }
    final impact = _impact!;
    final kg = impact.totalFoodSavedKg;
    final co2 = impact.estimatedCo2SavedKg;
    final composition = _composition.entries.toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        _header(),
        const SizedBox(height: 12),
        _periodChips(),
        const SizedBox(height: 16),
        _heroCard(kg: kg, co2: co2),
        const SizedBox(height: 14),
        _arbitraseCard(),
        const SizedBox(height: 14),
        _nutrisiCard(),
        if (composition.isNotEmpty) ...[
          const SizedBox(height: 14),
          _komposisiCard(composition),
        ],
        const SizedBox(height: 14),
        _heroShareCard(),
      ],
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DAMPAK',
                style: AppTheme.labelCaps(
                  color: AppColors.tertiary,
                ).copyWith(letterSpacing: 2),
              ),
              Text('Laporan Dampak', style: AppTheme.headlineMd()),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Muat ulang',
          onPressed: _pull,
          icon: const Icon(Icons.refresh, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _periodChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('September 2026', true),
          const SizedBox(width: 8),
          _chip('3 Bulan Terakhir', false),
          const SizedBox(width: 8),
          _chip('Sepanjang Tahun', false),
        ],
      ),
    );
  }

  Widget _chip(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Text(
        text,
        style: AppTheme.labelMd(
          color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _heroCard({required double kg, required double co2}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.tertiaryContainer],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F005321),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEKILAS DAMPAK KAMU',
            style: AppTheme.labelCaps(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Makanan Terselamatkan',
                      style: AppTheme.bodySm(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${kg.toStringAsFixed(1)} kg',
                        style: AppTheme.metricLg(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 52, color: Colors.white24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nilai Hemat',
                      style: AppTheme.bodySm(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '+${_efficiency.toStringAsFixed(1)}%',
                        style: AppTheme.metricLg(
                          color: AppColors.primaryFixed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Menghindari ${co2.toStringAsFixed(1)} kg CO2e, '
            'setara ${(co2 / 21.3).toStringAsFixed(0)} pohon mangrove.',
            style: AppTheme.bodySm(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _arbitraseCard() {
    final savings = _impact?.totalMoneySaved ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KEUNTUNGAN KAMU',
            style: AppTheme.labelCaps(color: AppColors.secondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricCell('Nilai Aslinya', Fmt.money(_value)),
              const SizedBox(width: 12),
              _metricCell('Kamu Bayar', Fmt.money(_spent)),
              const SizedBox(width: 12),
              _metricCell('Kamu Hemat', '+${Fmt.money(savings)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCell(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: AppTheme.metricSm(color: AppColors.primary)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.labelCaps(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutrisiCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NUTRISI YANG DAPAT',
            style: AppTheme.labelCaps(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _pctBar('Efisiensi Belanja', _efficiency / 100),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$_proteinG g protein · ${_impact?.totalOrders ?? 0} pesanan · nol terbuang',
            style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _pctBar(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyMd(),
              ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(1)}%',
              style: AppTheme.labelMd(color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            backgroundColor: AppColors.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.secondaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _komposisiCard(List<MapEntry<String, int>> entries) {
    final total = entries.fold(0, (s, e) => s + e.value);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ISI KERANJANG KAMU',
            style: AppTheme.labelCaps(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          ...entries.take(4).map((e) {
            final pct = total > 0 ? (e.value / total * 100) : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      Fmt.toTitleCase(e.key),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyMd(),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 7,
                        backgroundColor: AppColors.surfaceContainerHighest,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 42,
                    child: Text(
                      '${pct.round()}%',
                      textAlign: TextAlign.right,
                      style: AppTheme.labelMd(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _heroShareCard() {
    final co2 = _impact?.estimatedCo2SavedKg ?? 0;
    final name = ref.read(authControllerProvider).user?.fullName ?? 'Rescuer';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.onPrimaryFixedVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: AppColors.primaryFixed, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'FOOD RESCUE HERO • LEVEL $_tier',
                  style: AppTheme.labelCaps(color: AppColors.primaryFixed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '“Aku udah nyelamatin ${co2.toStringAsFixed(1)} kg CO2e. Mau ikut?”',
            style: AppTheme.bodyMd(color: AppColors.primaryFixed),
          ),
          const SizedBox(height: 6),
          Text(
            '$name · ${_impact?.totalOrders ?? 0} pesanan',
            style: AppTheme.bodySm(color: AppColors.primaryFixedDim),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton(
              onPressed: () async {
                final kg = _impact?.totalFoodSavedKg ?? 0;
                final co2Str = (_impact?.estimatedCo2SavedKg ?? 0).toStringAsFixed(1);
                final pesanan = _impact?.totalOrders ?? 0;
                try {
                  await Share.share(
                    'Aku udah nyelamatin ${kg.toStringAsFixed(1)} kg makanan, '
                    '$co2Str kg emisi CO2e terhindar, '
                    'dan $pesanan pesanan bareng Food Rescue.\n\n'
                    '#FoodRescue #ZeroFoodWaste #ZeroWaste',
                  );
                } catch (_) {
                  _nag('Gagal membuka menu berbagi.');
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Bagikan ke Sosmed'),
            ),
          ),
        ],
      ),
    );
  }

  void _nag(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}