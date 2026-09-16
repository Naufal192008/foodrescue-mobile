import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/app_theme.dart';
import '../controllers/listing_controller.dart';

/// Rating & ulasan pasca serah terima (role user → mitra toko).
class RatingScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  final FoodListingModel? listing;

  const RatingScreen({super.key, required this.order, this.listing});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  static const _tags = [
    'Kemasan Rapi & Higienis',
    'Rasa & Kualitas Baik',
    'Porsi Sesuai Deskripsi',
    'Pelayanan Cepat',
  ];

  final _reviewCtrl = TextEditingController();
  int _score = 5;
  final Set<String> _selectedTags = {};
  bool _anonymous = false;
  bool _submitting = false;

  String get _listingName =>
      widget.order.listing?.name ?? widget.listing?.name ?? 'Penyelamatan';

  String get _tokoName =>
      widget.order.listing?.tokoName ?? widget.listing?.tokoName ?? 'Mitra Toko';

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(listingRepositoryProvider);
      final tokoId =
          widget.order.listing?.tokoId ?? widget.listing?.tokoId ?? '';
      if (tokoId.isEmpty) throw Exception('Toko tidak ditemukan.');
      final toko = await repo.getTokoProfile(tokoId);
      final extra = _selectedTags.join(', ');
      final review = [
        if (_reviewCtrl.text.trim().isNotEmpty) _reviewCtrl.text.trim(),
        if (extra.isNotEmpty) extra,
      ].join('\n');
      await repo.submitRating(
        orderId: widget.order.id,
        rateeUserId: toko.userId,
        ratingTarget: 'toko',
        score: _score,
        reviewText: extra.isNotEmpty || _reviewCtrl.text.trim().isNotEmpty
            ? review
            : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Ulasan terkirim. Terima kasih berbagi!')),
        );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rating & Ulasan'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _batchCard(),
            const SizedBox(height: 14),
            _foodCard(),
            const SizedBox(height: 14),
            _section('Kualitas Makanan & Pengemasan'),
            const SizedBox(height: 8),
            _scoreRow(),
            const SizedBox(height: 14),
            _section('Kelebihan Batch Ini'),
            const SizedBox(height: 8),
            _tagChips(),
            const SizedBox(height: 14),
            _section('Catatan Penyelamat'),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewCtrl,
              maxLines: 4,
              maxLength: 240,
              decoration: const InputDecoration(
                hintText: 'Ceritakan pengalaman menyelamatkanmu…',
              ),
            ),
            const SizedBox(height: 10),
            _anonymousRow(),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kirim Ulasan'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Nanti Saja'),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '+50 poin dampak untuk setiap ulasan terverifikasi.',
                style: AppTheme.labelCaps(color: AppColors.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _batchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F005321),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.verified, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batch #${(widget.order.id.length >= 5 ? widget.order.id.substring(0, 5) : widget.order.id).toUpperCase()}',
                  style: AppTheme.labelMd(color: AppColors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  'Aman! Pesanan berhasil diterima',
                  style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Text(
              'Selesai',
              style: AppTheme.labelCaps(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _foodCard() {
    final url = widget.order.listing?.photoUrl ?? widget.listing?.photoUrl;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 72,
              height: 72,
              child: url != null && url.isNotEmpty
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _FoodPlaceholder(),
                    )
                  : const _FoodPlaceholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _listingName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyLg().copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_tokoName · ${widget.order.quantity} porsi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Text(title, style: AppTheme.labelMd());
  }

  Widget _scoreRow() {
    return Row(
      children: List.generate(5, (i) {
        final val = i + 1;
        final active = val <= _score;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: active
                ? AppColors.primary
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              onTap: () => setState(() => _score = val),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Text(
                  '$val',
                  style: AppTheme.labelMd(
                    color: active ? AppColors.onPrimary : AppColors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _tagChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tags.map((t) {
        final active = _selectedTags.contains(t);
        return Material(
          color: active
              ? AppColors.secondaryFixed
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            onTap: () => setState(() {
              if (active) {
                _selectedTags.remove(t);
              } else {
                _selectedTags.add(t);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                t,
                style: AppTheme.bodySm(
                  color: active
                      ? AppColors.onSecondaryFixed
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _anonymousRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tampilkan Ulasan secara Anonim', style: AppTheme.bodyMd()),
              Text(
                'Sembunyikan nama profil di feed publik',
                style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Switch(
          value: _anonymous,
          onChanged: (v) => setState(() => _anonymous = v),
        ),
      ],
    );
  }
}

class _FoodPlaceholder extends StatelessWidget {
  const _FoodPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryFixed.withValues(alpha: 0.15),
      child: const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 30),
    );
  }
}