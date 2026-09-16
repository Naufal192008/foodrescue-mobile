import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/app_theme.dart';

class BantuanScreen extends StatelessWidget {
  const BantuanScreen({super.key});

  static const _csPhone = '0812-3456-7890';
  static const _whatsApp = '6281234567890';
  static const _email = 'care@foodrescue.id';

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const faqs = <(String, String)>[
      (
        'Bagaimana cara mengamankan makanan?',
        'Pilih listing yang masih aktif, atur jumlah porsi, lalu ketuk Amankan Sekarang dan selesaikan pembayaran QRIS.',
      ),
      (
        'Pembayaran sudah tapi status belum berubah?',
        'Pastikan koneksi stabil lalu ketuk "SAYA SUDAH MEMBAYAR" sekali lagi. Token QRIS tersimpan otomatis di pesanan.',
      ),
      (
        'Bagaimana melacak kurir?',
        'Buka tab Pesanan, pilih pesanan aktif, lalu masuk ke Lacak Pengantaran. Posisi real-time dan ETA tersedia.',
      ),
      (
        'Pesanan tidak sampai sesuai estimasi?',
        'Gunakan tombol Bantuan Live di halaman pesanan atau hubungi CS 24/7 lewat kanal di bawah.',
      ),
      (
        'Bagaimana cara memberi rating?',
        'Setelah pesanan selesai, tombol "Beri Ulasan & Nilai" muncul di halaman detail pesanan.',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text('Bantuan & CS', style: AppTheme.headlineSm()),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.support_agent, size: 30, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'Layanan CS 24/7',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kami siap bantu pesanan penyelamatan kamu kapan pun.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _contactTile(
                    icon: Icons.call,
                    label: 'Telepon',
                    sub: _csPhone,
                    onTap: () => _launch('tel:$_csPhone'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _contactTile(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    sub: _csPhone,
                    onTap: () =>
                        _launch('https://wa.me/$_whatsApp?text=Halo%20CS%20Rescue'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _contactTile(
              icon: Icons.mail_outline,
              label: 'Email',
              sub: _email,
              onTap: () => _launch('mailto:$_email'),
            ),
            const SizedBox(height: 20),
            Text('Pertanyaan Umum', style: AppTheme.labelCaps()),
            const SizedBox(height: 8),
            ...faqs.map(
              (f) => ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                title: Text(f.$1, style: AppTheme.bodyMd().copyWith(fontWeight: FontWeight.w600)),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      f.$2,
                      style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactTile({
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTheme.labelMd()),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}