import 'package:flutter/material.dart';

import '../../../core/utils/app_theme.dart';

class TokoLayout extends StatefulWidget {
  const TokoLayout({super.key});

  @override
  State<TokoLayout> createState() => _TokoLayoutState();
}

class _TokoLayoutState extends State<TokoLayout> {
  int _index = 0;

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.dashboard_rounded, label: 'Analisis'),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Barang'),
    _NavItem(icon: Icons.recycling_rounded, label: 'Limbah'),
    _NavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  static const _tabs = <Widget>[
    _DashboardTokoScreen(),
    _BarangTokoScreen(),
    _LimbahTokoScreen(),
    _ProfilTokoScreen(),
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

class _DashboardTokoScreen extends StatelessWidget {
  const _DashboardTokoScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Analisis Toko', style: AppTheme.headlineMd()),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Aktif', style: AppTheme.labelMd(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _metricCard(
            title: 'Total Surplus',
            value: '142 kg',
            trend: '+18% bulan ini',
            accent: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniStat('Penjualan', 'Rp 8,4 jt', AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _miniStat('Dibantu', '318 porsi', AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 18),
          _panelCard(
            title: 'Ringkasan hari ini',
            child: Column(
              children: const [
                _ListRow(label: 'Porsi terjual', value: '86'),
                _ListRow(label: 'Limbah terhindar', value: '12 kg'),
                _ListRow(label: 'Komunitas aktif', value: '243'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarangTokoScreen extends StatelessWidget {
  const _BarangTokoScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Text('Barang & Stok', style: AppTheme.headlineMd()),
          const SizedBox(height: 16),
          _panelCard(
            title: 'Daftar stok hari ini',
            child: Column(
              children: const [
                _ListRow(label: 'Salmon Teriyaki', value: '18 porsi'),
                _ListRow(label: 'Nasi Box', value: '26 box'),
                _ListRow(label: 'Roti & Pastry', value: '21 pack'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah barang baru'),
          ),
        ],
      ),
    );
  }
}

class _LimbahTokoScreen extends StatelessWidget {
  const _LimbahTokoScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Text('Pengolahan Limbah', style: AppTheme.headlineMd()),
          const SizedBox(height: 16),
          _metricCard(
            title: 'Kompos yang dibuat',
            value: '24 kg',
            trend: 'Bulan ini',
            accent: AppColors.tertiary,
          ),
          const SizedBox(height: 12),
          _panelCard(
            title: 'Aktivitas',
            child: Column(
              children: const [
                _ListRow(label: 'Pupuk siap pakai', value: '12 ember'),
                _ListRow(label: 'Diproses hari ini', value: '8 batch'),
                _ListRow(label: 'Waste log', value: 'Terkirim'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilTokoScreen extends StatelessWidget {
  const _ProfilTokoScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Text('Profil Mitra', style: AppTheme.headlineMd()),
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
                  child: const Icon(Icons.storefront_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resto & Toko', style: AppTheme.bodyMd().copyWith(fontWeight: FontWeight.w700)),
                      Text('Mitra aktif', style: AppTheme.bodySm(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _panelCard(
            title: 'Informasi',
            child: Column(
              children: const [
                _ListRow(label: 'Kontak', value: '081234567890'),
                _ListRow(label: 'Lokasi', value: 'Plaza Senayan'),
                _ListRow(label: 'Status', value: 'Terverifikasi'),
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