import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';

class MetodePembayaranScreen extends ConsumerStatefulWidget {
  const MetodePembayaranScreen({super.key});

  @override
  ConsumerState<MetodePembayaranScreen> createState() =>
      _MetodePembayaranScreenState();
}

class _MetodePembayaranScreenState
    extends ConsumerState<MetodePembayaranScreen> {
  List<PaymentMethodModel> _methods = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final list = await ref
          .read(authRepositoryProvider)
          .getMyPaymentMethods();
      if (mounted) {
        setState(() {
          _methods = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _add() async {
    final provider = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _pickerSheet(ctx, const <String>[
        'QRIS',
      ]),
    );
    if (provider == null || !mounted) return;

    final acct = _acctController.text.trim();
    if (acct.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Isi nomor/akun dulu ya.')));
      return;
    }
    try {
      await ref.read(authRepositoryProvider).addPaymentMethod(
            provider: provider,
            accountReference: acct,
          );
      _acctController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Metode berhasil disimpan')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        _error = e.toString();
        setState(() {});
      }
    }
  }

  final TextEditingController _acctController = TextEditingController();

  @override
  void dispose() {
    _acctController.dispose();
    super.dispose();
  }

  IconData _iconFor(String provider) {
    final p = provider.toLowerCase();
    if (p.contains('qris')) return Icons.qr_code_2;
    if (p.contains('gopay') || p.contains('ovo') || p.contains('dana')) {
      return Icons.account_balance_wallet;
    }
    if (p.contains('shopeepay')) return Icons.shopping_bag;
    return Icons.credit_card;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text('Metode Pembayaran', style: AppTheme.headlineSm()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _acctController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'ID akun/e-wallet atau nomor (cth: 0812xxxx)',
                        filled: true,
                        fillColor: AppColors.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _loading ? null : _add,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('Tambah'),
                  ),
                ],
              ),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: InkWell(
                  onTap: _load,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Gagal memuat: $_error. Ketuk untuk coba lagi',
                            style: AppTheme.bodySm(
                              color: AppColors.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _methods.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            const Icon(
                              Icons.credit_card_off,
                              size: 56,
                              color: AppColors.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada metode pembayaran.',
                              textAlign: TextAlign.center,
                              style: AppTheme.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Isi nomor/akun di atas, lalu ketuk Tambah.',
                              textAlign: TextAlign.center,
                              style: AppTheme.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: _methods.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final m = _methods[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: m.isDefault
                                      ? AppColors.primary
                                      : AppColors.hairline,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _iconFor(m.provider),
                                      size: 22,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.provider,
                                          style: AppTheme.labelMd().copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          m.accountReference,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTheme.bodySm(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (m.isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Utama',
                                        style: AppTheme.labelCaps(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerSheet(BuildContext ctx, List<String> options) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Pilih Provider', style: AppTheme.labelMd()),
          ),
          ...options.map(
            (o) => ListTile(
              title: Text(o),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => Navigator.of(ctx).pop(o),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}