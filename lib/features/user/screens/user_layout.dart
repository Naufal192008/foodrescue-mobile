import 'package:flutter/material.dart';

import '../../../core/utils/app_theme.dart';
import 'ai_nutrisi_screen.dart';
import 'dampak_screen.dart';
import 'jelajah_screen.dart';
import 'komunitas_screen.dart';
import 'pesanan_screen.dart';
import 'profil_screen.dart';

/// Navigasi global antar-tab (dipakai layar lain, mis. sukses pembayaran).
class AppNav {
  static final ValueNotifier<int> tabIndex = ValueNotifier(0);

  static const int pesanan = 1;
  static const int jelajah = 0;
  static const int komunitas = 2;
  static const int dampak = 3;
  static const int profil = 4;
}

class UserLayout extends StatefulWidget {
  const UserLayout({super.key});

  @override
  State<UserLayout> createState() => _UserLayoutState();
}

class _UserLayoutState extends State<UserLayout> {
  int _index = 0;

  static const _tabs = <Widget>[
    JelajahScreen(),
    PesananScreen(),
    KomunitasScreen(),
    DampakScreen(),
    ProfilScreen(),
  ];

  void _openAi() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AiNutrisiScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    AppNav.tabIndex.addListener(_onNavChanged);
  }

  void _onNavChanged() {
    if (!mounted) return;
    setState(() => _index = AppNav.tabIndex.value);
  }

  @override
  void dispose() {
    AppNav.tabIndex.removeListener(_onNavChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: _FabAi(onTap: _openAi),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _PillNav(
        index: _index,
        onTap: (i) => AppNav.tabIndex.value = i,
      ),
    );
  }
}

class _FabAi extends StatelessWidget {
  final VoidCallback onTap;
  const _FabAi({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        onPressed: onTap,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 8,
        shape: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.auto_awesome, size: 24),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _PillNav({required this.index, required this.onTap});

  static const _items = <_NavItem>[
    _NavItem(Icons.explore, 'Jelajah'),
    _NavItem(Icons.receipt_long, 'Pesanan'),
    _NavItem(Icons.groups, 'Komunitas'),
    _NavItem(Icons.eco, 'Dampak'),
    _NavItem(Icons.person, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F005321),
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
            BoxShadow(
              color: Color(0x14FD651E),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final selected = i == index;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: selected
                          ? AppColors.primaryContainer
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: AppTheme.labelCaps(
                        color: selected
                            ? AppColors.primaryContainer
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}