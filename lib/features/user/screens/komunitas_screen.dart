import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../controllers/listing_controller.dart';

class KomunitasScreen extends ConsumerStatefulWidget {
  const KomunitasScreen({super.key});

  @override
  ConsumerState<KomunitasScreen> createState() => _KomunitasScreenState();
}

class _KomunitasScreenState extends ConsumerState<KomunitasScreen> {
  int _segment = 0;
  List<CommunityPostCardModel> _posts = [];
  List<EmergencyAlertModel> _alerts = [];
  bool _loading = true;
  String? _error;
  String? _claimingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pull());
  }

  Future<void> _pull() async {
    setState(() {
      _loading = _posts.isEmpty && _alerts.isEmpty;
      _error = null;
    });
    final repo = ref.read(listingRepositoryProvider);
    List<CommunityPostCardModel> posts = [];
    List<EmergencyAlertModel> alerts = [];
    String? err;
    try {
      posts = await repo.getCommunityPosts();
    } catch (e) {
      err ??= e.toString();
    }
    try {
      alerts = await repo.getEmergencyAlerts();
    } catch (e) {
      err ??= e.toString();
    }
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _alerts = alerts;
      _error = posts.isEmpty && alerts.isEmpty ? err : null;
      _loading = false;
    });
  }

  Future<void> _claim(CommunityPostCardModel post) async {
    if (_claimingId != null) return;
    setState(() => _claimingId = post.id);
    try {
      await ref.read(listingRepositoryProvider).claimCommunityPost(post.id);
      if (!mounted) return;
      setState(() => _claimingId = null);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Penyaluran ${post.listingName} berhasil diklaim.'),
          ),
        );
      await _pull();
    } catch (e) {
      if (!mounted) return;
      setState(() => _claimingId = null);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 12),
          _segments(),
          const SizedBox(height: 12),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KOMUNITAS',
                  style: AppTheme.labelCaps(
                    color: AppColors.tertiary,
                  ).copyWith(letterSpacing: 2),
                ),
                Text('Komunitas & Penyaluran', style: AppTheme.headlineMd()),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Jakarta · 3km',
                  style: AppTheme.labelMd().copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segments() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          children: [
            _segmentItem('Kanal Siaga', 0),
            const SizedBox(width: 4),
            _segmentItem('Penyaluran Aktif', 1),
          ],
        ),
      ),
    );
  }

  Widget _segmentItem(String label, int index) {
    final active = _segment == index;
    return Expanded(
      child: Material(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          onTap: () => setState(() => _segment = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.labelMd(
                color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null && _posts.isEmpty && _alerts.isEmpty) {
      return AppErrorView(message: _error!, onRetry: _pull);
    }
    return RefreshIndicator(
      onRefresh: _pull,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: _segment == 0 ? _siagaChildren() : _postChildren(),
      ),
    );
  }

  List<Widget> _siagaChildren() {
    final list = <Widget>[
      _metricStrip(),
      const SizedBox(height: 14),
      if (_alerts.isEmpty)
        const AppEmptyState(
          icon: Icons.crisis_alert,
          message:
              'Belum ada siaga darurat aktif.\nAlgoritma Food Rescue tetap siaga 24/7.',
        )
      else
        ..._alerts.map(_alertCard),
    ];
    return list;
  }

  Widget _metricStrip() {
    return Row(
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
                Text(
                  'JALUR KOMUNITAS',
                  style: AppTheme.labelCaps(color: AppColors.primaryFixed),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${(_posts.fold<int>(0, (s, p) => s + 1))} Aktif',
                    style: AppTheme.metricSm(color: AppColors.primaryFixed),
                  ),
                ),
                Text(
                  'penyaluran tersedia hari ini',
                  style: AppTheme.bodySm(color: AppColors.primaryFixedDim),
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
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIAGA DARURAT',
                  style: AppTheme.labelCaps(color: AppColors.secondary),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${_alerts.length}',
                    style: AppTheme.metricSm(color: AppColors.secondary),
                  ),
                ),
                Text(
                  'kanal NGO sedang aktif',
                  style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _alertCard(EmergencyAlertModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.secondaryFixed.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
                child: Text(
                  a.needType.toUpperCase(),
                  style: AppTheme.labelCaps(color: AppColors.onSecondary),
                ),
              ),
              const Spacer(),
              Text(
                Fmt.toTitleCase(a.urgencyLevel),
                style: AppTheme.labelCaps(color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            a.targetArea.isEmpty ? 'Butuh Donasi Pangan' : a.targetArea,
            style: AppTheme.bodyLg().copyWith(fontWeight: FontWeight.w700),
          ),
          if (a.description != null && a.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              a.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Hanya admin NGO terverifikasi yang menerbitkan kanal ini.',
            style: AppTheme.labelCaps(color: AppColors.outline),
          ),
        ],
      ),
    );
  }

  List<Widget> _postChildren() {
    if (_posts.isEmpty) {
      return const [
        SizedBox(height: 80),
        AppEmptyState(
          icon: Icons.volunteer_activism,
          message:
              'Belum ada penyaluran komunitas aktif.\nPantau lagi, stok surplus sering muncul sore hari.',
        ),
      ];
    }
    return [
      ..._posts.map((p) => _postCard(p)),
    ];
  }

  Widget _postCard(CommunityPostCardModel p) {
    final photo = p.listingPhoto;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo != null && photo.isNotEmpty)
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Image.network(
                photo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _photoFallback(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                      ),
                      child: Text(
                        Fmt.toTitleCase(p.targetCategory),
                        style: AppTheme.labelCaps(color: AppColors.primary),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      p.transportFee > 0
                          ? 'Angkut ${Fmt.money(p.transportFee)}'
                          : 'Angkut Gratis',
                      style: AppTheme.labelCaps(color: AppColors.secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  p.listingName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyLg().copyWith(fontWeight: FontWeight.w700),
                ),
                if (p.listingDescription != null &&
                    p.listingDescription!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    p.listingDescription!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Siap diklaim oleh relawan/panti',
                        style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 42,
                      child: FilledButton(
                        onPressed:
                            _claimingId == p.id ? null : () => _claim(p),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          minimumSize: Size.zero,
                        ),
                        child: _claimingId == p.id
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Klaim'),
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

  Widget _photoFallback() {
    return Container(
      height: 150,
      width: double.infinity,
      color: AppColors.primaryFixed.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 40),
    );
  }
}