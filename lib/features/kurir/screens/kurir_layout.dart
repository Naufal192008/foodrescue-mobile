import 'package:flutter/material.dart';

import '../../../core/utils/app_theme.dart';

class KurirLayout extends StatefulWidget {
  const KurirLayout({super.key});

  @override
  State<KurirLayout> createState() => _KurirLayoutState();
}

class _KurirLayoutState extends State<KurirLayout> {
  int _index = 0;

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.dashboard_rounded, label: 'Analisis'),
    _NavItem(icon: Icons.assignment_turned_in_rounded, label: 'Masuk'),
    _NavItem(icon: Icons.delivery_dining_rounded, label: 'Aktif'),
    _NavItem(icon: Icons.history_rounded, label: 'Riwayat'),
    _NavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  static const _tabs = <Widget>[
    _DashboardKurirScreen(),
    _PesananMasukScreen(),
    _PesananAktifScreen(),
    _RiwayatKurirScreen(),
    _ProfilKurirScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F005321),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == _index;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _index = i),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: selected ? AppColors.onPrimary : AppColors.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: AppTheme.labelCaps(
                            color: selected ? AppColors.onPrimary : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DashboardKurirScreen extends StatelessWidget {
  const _DashboardKurirScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Row(
            children: [
              Expanded(child: Text('Dashboard Kurir', style: AppTheme.headlineMd())),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Online', style: AppTheme.labelMd(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _metricCard(title: 'Pengantaran hari ini', value: '14', trend: '+3 vs kemarin', accent: AppColors.primary),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniStat('Pendapatan', 'Rp 1,2 jt', AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _miniStat('Waktu rata-rata', '32 menit', AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 18),
          _panelCard(
            title: 'Jadwal aktif',
            child: const Column(
              children: [
                _ListRow(label: 'Pickup berikutnya', value: '16:30'),
                _ListRow(label: 'Lokasi fokus', value: 'Plaza Senayan'),
                _ListRow(label: 'Rute hari ini', value: '4 titik'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PesananMasukScreen extends StatelessWidget {
  const _PesananMasukScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Text('Pesanan Masuk', style: AppTheme.headlineMd()),
          const SizedBox(height: 16),
          _panelCard(
            title: 'Antrean pickup',
            child: const Column(
              children: [
                _ListRow(label: 'Salmon Teriyaki', value: 'Ambil 15.40'),
                _ListRow(label: 'Nasi Bento', value: 'Ambil 16.10'),
                _ListRow(label: 'Roti & Pastry', value: 'Ambil 17.00'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Konfirmasi jadwal'),
          ),
        ],
      ),
    );
  }
}

class _PesananAktifScreen extends StatelessWidget {
  const _PesananAktifScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Text('Pesanan Aktif', style: AppTheme.headlineMd()),
          const SizedBox(height: 16),
          _panelCard(
            title: 'Sedang diantar',
            child: const Column(
              children: [
                _ListRow(label: 'Nasi Box Jaya', value: '5.2 km'),
                _ListRow(label: 'Roti & Pastry', value: '2.8 km'),
                _ListRow(label: 'Komposisi akhir', value: 'Estimasi 20 min'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiwayatKurirScreen extends StatelessWidget {
  const _RiwayatKurirScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Text('Riwayat Pengantaran', style: AppTheme.headlineMd()),
          const SizedBox(height: 16),
          _panelCard(
            title: 'Minggu ini',
            child: const Column(
              children: [
                _ListRow(label: 'Total pengantaran', value: '46'),
                _ListRow(label: 'Rating pelanggan', value: '4.9'),
                _ListRow(label: 'Target bulan', value: '92%'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilKurirScreen extends StatelessWidget {
  const _ProfilKurirScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Text('Profil Kurir', style: AppTheme.headlineMd()),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.electric_moped_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kurir Food Rescue', style: AppTheme.bodyMd().copyWith(fontWeight: FontWeight.w700)),
                      Text('Siap antar & pickup', style: AppTheme.bodySm(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _panelCard(
            title: 'Status',
            child: const Column(
              children: [
                _ListRow(label: 'Kendaraan', value: 'Motor listrik'),
                _ListRow(label: 'Zona', value: 'Plaza Senayan'),
                _ListRow(label: 'Sertifikasi', value: 'Aktif'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _metricCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final Color accent;

  const _metricCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.labelMd(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.metricSm(color: accent)),
          const SizedBox(height: 6),
          Text(trend, style: AppTheme.bodySm(color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _miniStat extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _miniStat(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.labelMd(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.metricSm(color: color)),
        ],
      ),
    );
  }
}

class _panelCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _panelCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headlineSm().copyWith(fontSize: 17)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  final String label;
  final String value;

  const _ListRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTheme.bodyMd(color: AppColors.onSurfaceVariant))),
          Text(value, style: AppTheme.bodyMd().copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}