import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../controllers/listing_controller.dart';
import 'detail_listing_screen.dart';
import 'pesanan_detail_screen.dart';
import 'user_layout.dart';

enum _NotifCat { pesanan, flash, komunitas, sistem }

class _NotifItem {
  final _NotifCat cat;
  final String timeLabel;
  final String title;
  final String body;
  final String? actionLabel;
  final String? orderId;
  final String? listingId;

  const _NotifItem({
    required this.cat,
    required this.timeLabel,
    required this.title,
    required this.body,
    this.actionLabel,
    this.orderId,
    this.listingId,
  });
}

class NotifikasiScreen extends ConsumerStatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  ConsumerState<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends ConsumerState<NotifikasiScreen> {
  List<_NotifItem> _items = [];
  bool _loading = true;
  String? _error;
  _NotifCat? _filter;
  final Set<String> _read = {};
  static const _readKey = 'notif_read_titles';

  @override
  void initState() {
    super.initState();
    _restoreRead();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _restoreRead() async {
    try {
      final p = await SharedPreferences.getInstance();
      final saved = p.getStringList(_readKey) ?? const [];
      if (mounted && saved.isNotEmpty) setState(() => _read.addAll(saved));
    } catch (_) {}
  }

  Future<void> _saveUnread(bool unread) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('notif_unread_local', unread);
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    setState(() => _read
      ..clear()
      ..addAll(_items.map((i) => i.title)));
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_readKey, _read.toList());
    } catch (_) {}
    await _saveUnread(false);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(listingRepositoryProvider);
    List<OrderModel> orders = [];
    List<FoodListingModel> listings = [];
    List<CommunityPostCardModel> posts = [];
    ImpactSummaryModel impact = const ImpactSummaryModel();

    Future<void> safe<T>(Future<T> Function() fn, void Function(T) assign) async {
      try {
        assign(await fn());
      } catch (_) {}
    }

    await Future.wait([
      safe(() => repo.getMyOrders(), (v) => orders = v),
      safe(
          () => repo.getListings(page: 1, limit: 5),
          (v) => listings = v.data),
      safe(() => repo.getCommunityPosts(), (v) => posts = v),
      safe(() => repo.getMyImpact(), (v) => impact = v),
    ]);
    if (!mounted) return;

    final items = <_NotifItem>[];

      for (final o in orders) {
        if (o.paymentStatus == 'paid' &&
            o.fulfillmentMethod == 'diantar_kurir' &&
            o.orderStatus != 'selesai') {
          items.add(_NotifItem(
            cat: _NotifCat.pesanan,
            timeLabel: '10 mnt lalu',
            title: 'Kurir Menuju Lokasimu',
            body:
                'Kurir mengantar ${o.listing?.name ?? 'pesananmu'} dari mitra. Est. tiba beberapa menit lagi.',
            actionLabel: 'Lacak Kurir',
            orderId: o.id,
          ));
          break;
        }
      }

      if (listings.isNotEmpty) {
        final l = listings.first;
        final discount = l.initialPrice > 0
            ? ((1 - l.currentPrice / l.initialPrice) * 100).round()
            : 0;
        items.add(_NotifItem(
          cat: _NotifCat.flash,
          timeLabel: '45 mnt lalu',
          title: 'Flash Drop Aktif (-$discount%)',
          body:
              '${l.name} turun jadi harga hemat. Sisa ${l.stockQuantity} porsi terdekat, amankan sebelum habis!',
          actionLabel: 'Amankan Sekarang',
          listingId: l.id,
        ));
      }

      if (posts.isNotEmpty) {
        items.add(_NotifItem(
          cat: _NotifCat.komunitas,
          timeLabel: '2 jam lalu',
          title: 'Penyaluran Komunitas Aktif',
          body:
              '${posts.length} alokasi surplus tersedia untuk relawan & panti. Cek dan klaim lewat komunitas.',
          actionLabel: 'Buka Komunitas',
        ));
      }

      items.add(_NotifItem(
        cat: _NotifCat.sistem,
        timeLabel: 'Kemarin',
        title: 'Pencapaian Dampak Baru',
        body:
            'Total ${(impact.totalFoodSavedKg).toStringAsFixed(1)} kg makanan terselamatkan, '
            'setara ${impact.estimatedCo2SavedKg.toStringAsFixed(1)} kg CO2e terhindar. '
            'Laporan Dampak kamu sudah diperbarui.',
        actionLabel: 'Lihat Laporan',
      ));

      setState(() {
        _items = items;
        _loading = false;
      });
      _saveUnread(items.any((i) => !_read.contains(i.title)));
  }

  void _runAction(_NotifItem item) {
    switch (item.actionLabel) {
      case 'Lacak Kurir':
        if (item.orderId == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PesananDetailScreen(
              order: OrderModel.fromJson({'id': item.orderId}),
            ),
          ),
        );
        return;
      case 'Amankan Sekarang':
        if (item.listingId == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetailListingScreen(listingId: item.listingId!),
          ),
        );
        return;
      case 'Buka Komunitas':
        AppNav.tabIndex.value = AppNav.komunitas;
        return;
      case 'Lihat Laporan':
        AppNav.tabIndex.value = AppNav.dampak;
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pusat Notifikasi'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Tandai Dibaca'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _filterChips(),
            const SizedBox(height: 8),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _filterChips() {
    final cats = <String, _NotifCat?>{
      'Semua': null,
      'Pesanan': _NotifCat.pesanan,
      'Flash Drop': _NotifCat.flash,
      'Komunitas & NGO': _NotifCat.komunitas,
      'Sistem & Dompet': _NotifCat.sistem,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: cats.entries.map((e) {
            final active = _filter == e.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: active
                    ? AppColors.primary
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  onTap: () => setState(() => _filter = e.value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Text(
                      e.key,
                      style: AppTheme.labelMd(
                        color: active
                            ? AppColors.onPrimary
                            : AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null && _items.isEmpty) {
      return AppErrorView(message: _error!, onRetry: _load);
    }
    final items = _filter == null
        ? _items
        : _items.where((i) => i.cat == _filter).toList();
    if (items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.notifications_off_outlined,
        message: 'Belum ada notifikasi kategori ini.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
        itemCount: items.length,
        itemBuilder: (_, i) => _card(items[i]),
      ),
    );
  }

  Widget _card(_NotifItem item) {
    final isNew = !_read.contains(item.title);
    final colors = switch (item.cat) {
      _NotifCat.pesanan => AppColors.primaryContainer,
      _NotifCat.flash => AppColors.secondaryContainer,
      _NotifCat.komunitas => AppColors.tertiaryContainer,
      _NotifCat.sistem => AppColors.outline,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelMd(),
                ),
              ),
              if (isNew)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Text(
                    'BARU',
                    style: AppTheme.labelCaps(color: AppColors.onSecondary),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                item.timeLabel,
                style: AppTheme.labelCaps(color: AppColors.outline),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.body, style: AppTheme.bodySm(color: AppColors.onSurfaceVariant)),
          if (item.actionLabel != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: () => _runAction(item),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  item.actionLabel!,
                  style: AppTheme.labelMd(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}