import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/listing_controller.dart';
import 'ai_nutrisi_screen.dart';
import 'bantuan_screen.dart';
import 'metode_pembayaran_screen.dart';
import 'user_layout.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  UserModel? _user;
  ImpactSummaryModel? _impact;
  List<TokoProfileModel> _tokos = [];
  bool _loading = true;
  String? _error;
  String _avatar = '';
  String _avatarImg = '';
  String _nameOverride = '';

  static const _avatars = [
    '🧑‍🚀', '🦸', '🐼', '🐱', '🦊', '🐶', '🍕', '🥑', '🌱', '⭐',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pull());
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      final p = await SharedPreferences.getInstance();
      final a = p.getString('profile_avatar') ?? '';
      final img = p.getString('profile_avatar_path') ?? '';
      final n = p.getString('profile_name') ?? '';
      if (!mounted) return;
      setState(() {
        _avatar = a;
        _avatarImg = img;
        if (n.isNotEmpty) _nameOverride = n;
      });
    } catch (_) {}
  }

  Future<void> _pull() async {
    setState(() {
      _loading = _user == null;
      _error = null;
    });
    try {
      final repo = ref.read(listingRepositoryProvider);
      final results = await Future.wait<Object>([
        repo.getMyProfile(),
        repo.getMyImpact(),
        repo.getApprovedTokos(),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as UserModel;
        _impact = results[1] as ImpactSummaryModel;
        _tokos = (results[2] as List).cast<TokoProfileModel>();
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

  int get _level {
    final orders = _impact?.totalOrders ?? 0;
    if (orders >= 30) return 4;
    if (orders >= 15) return 3;
    if (orders >= 5) return 2;
    return 1;
  }

  int get _ecoPoin =>
      ((_impact?.estimatedCo2SavedKg ?? 0) * 20).round();

  String get _shortId {
    final id = _user?.id ?? '';
    return id.length >= 6 ? id.substring(0, 6) : id;
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text('Yakin ingin keluar dari FoodRescue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        GoRouter.of(context).go('/login');
      }
    }
  }

  Future<void> _editProfile() async {
    final user = _user;
    final nameCtrl = TextEditingController(
      text: _nameOverride.isNotEmpty ? _nameOverride : (user?.fullName ?? ''),
    );
    String picked = _avatar;
    String pickedImg = _avatarImg;
    String tmpImg = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSt) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ubah Profil', style: AppTheme.headlineMd()),
                const SizedBox(height: 16),
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        alignment: Alignment.center,
                        clipBehavior: Clip.antiAlias,
                        child: _sheetAvatar(
                        img: pickedImg,
                        emoji: picked,
                        user: user,
                        size: 80,
                      ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () async {
                        try {
                          final img = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 600,
                            maxHeight: 600,
                            imageQuality: 85,
                          );
                          if (img == null) return;
                          final name =
                              'avatar_${DateTime.now().millisecondsSinceEpoch}'
                              '.${img.name.contains('.') ? img.name.split('.').last : 'jpg'}';
                          final dir = await getApplicationDocumentsDirectory();
                          final dest = '${dir.path}/$name';
                          await img.saveTo(dest);
                          tmpImg = dest;
                          setSt(() => pickedImg = tmpImg);
                        } catch (_) {
                          _nag('Gagal memilih foto. Coba lagi, ya.');
                        }
                      },
                      child: const Text('Ganti Foto dari Galeri'),
                    ),
                    if (pickedImg.isNotEmpty)
                      TextButton(
                        onPressed: () => setSt(() {
                          pickedImg = '';
                          picked = '';
                        }),
                        child: const Text('Hapus Foto'),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'atau pilih avatar lucu',
                  style: AppTheme.labelCaps(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _avatars.map((a) {
                      final sel = picked == a;
                      return GestureDetector(
                        onTap: () => setSt(() {
                          picked = a;
                          pickedImg = '';
                          tmpImg = '';
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primaryContainer
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(22),
                            border: sel
                                ? Border.all(color: AppColors.primary, width: 2)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(a, style: const TextStyle(fontSize: 22)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: () async {
                      final newName = nameCtrl.text.trim();
                      await _saveProfile(
                        newName: newName.isEmpty
                            ? (user?.fullName ?? 'Rescuer')
                            : newName,
                        avatar: picked,
                        avatarImg: pickedImg,
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    nameCtrl.dispose();
  }

  Widget _sheetAvatar({
    required String img,
    required String emoji,
    required UserModel? user,
    required double size,
  }) {
    if (img.isNotEmpty && File(img).existsSync()) {
      return Image.file(File(img), width: size, height: size, fit: BoxFit.cover);
    }
    if (emoji.isNotEmpty) return Text(emoji, style: AppTheme.headlineLg());
    final initials = user?.fullName
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join() ??
        '';
    return Text(
      initials.isEmpty ? 'R' : initials,
      style: AppTheme.headlineLg(color: AppColors.onPrimary),
    );
  }

  Widget _avatarContent({
    required double size,
    required double radius,
    required String initials,
    required TextStyle style,
  }) {
    if (_avatarImg.isNotEmpty && File(_avatarImg).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(
          File(_avatarImg),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text(
            initials.isEmpty ? 'R' : initials,
            style: style,
          ),
        ),
      );
    }
    return Text(
      _avatar.isNotEmpty ? _avatar : (initials.isEmpty ? 'R' : initials),
      style: style,
    );
  }

  Future<void> _saveProfile({
    required String newName,
    required String avatar,
    required String avatarImg,
  }) async {
    final existing = _user;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('profile_avatar', avatar);
      await p.setString('profile_avatar_path', avatarImg);
      await p.setString('profile_name', newName);
    } catch (_) {}
    try {
      if (existing != null && newName != existing.fullName) {
        final updated = UserModel(
          id: existing.id,
          email: existing.email,
          fullName: newName,
          photoUrl: existing.photoUrl,
          phoneNumber: existing.phoneNumber,
          authProvider: existing.authProvider,
          role: existing.role,
          isNgoVerified: existing.isNgoVerified,
          trustScore: existing.trustScore,
          latitude: existing.latitude,
          longitude: existing.longitude,
          addressText: existing.addressText,
          accountStatus: existing.accountStatus,
        );
        await ref.read(authControllerProvider.notifier).updateUser(updated);
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _avatar = avatar;
        _avatarImg = avatarImg;
        _nameOverride = newName;
        if (existing != null) {
          _user = UserModel(
            id: existing.id,
            email: existing.email,
            fullName: newName,
            photoUrl: existing.photoUrl,
            phoneNumber: existing.phoneNumber,
            authProvider: existing.authProvider,
            role: existing.role,
            isNgoVerified: existing.isNgoVerified,
            trustScore: existing.trustScore,
            latitude: existing.latitude,
            longitude: existing.longitude,
            addressText: existing.addressText,
            accountStatus: existing.accountStatus,
          );
        }
      });
    }
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
    if (_loading && _user == null) {
      return const SizedBox(
        height: 360,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_error != null && _user == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 160),
          AppErrorView(message: _error!, onRetry: _pull),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        _header(),
        const SizedBox(height: 14),
        _walletCard(),
        const SizedBox(height: 14),
        _impactCard(),
        const SizedBox(height: 22),
        _sectionTitle('Mitra Kuliner Favorit'),
        if (_tokos.isNotEmpty) _tokosStrip(),
        const SizedBox(height: 22),
        _sectionTitle('Aktivitas & Pengaturan'),
        _settingsList(),
      ],
    );
  }

  Widget _header() {
    final name = _nameOverride.isNotEmpty
        ? _nameOverride
        : (_user?.fullName ?? 'Rescuer');
    final email = _user?.email ?? '';
    final initials = name.split(' ').where((w) => w.isNotEmpty).take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Row(
      children: [
        GestureDetector(
          onTap: _editProfile,
          child: Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: _avatarContent(
                  size: 56,
                  radius: 18,
                  initials: initials,
                  style: AppTheme.headlineMd(color: AppColors.onPrimary),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 11, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headlineMd().copyWith(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Tooltip(
                    message: 'Akun terverifikasi',
                    child: Icon(Icons.verified, size: 18, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '#ID-${_shortId.toUpperCase()} · ${email.isEmpty ? _levelLabel() : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _levelLabel() {
    switch (_level) {
      case 4:
        return 'Guardian';
      case 3:
        return 'Rescuer';
      case 2:
        return 'Advocate';
      default:
        return 'Beginner';
    }
  }

  Widget _walletCard() {
    final savings = _impact?.totalMoneySaved ?? 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryContainer],
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'TOTAL HEMAT KAMU',
                  style: AppTheme.labelCaps(color: Colors.white70),
                ),
              ),
              Text(
                'Level $_level ${_levelLabel()}',
                style: AppTheme.labelCaps(color: AppColors.primaryFixed),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              Fmt.money(savings),
              style: AppTheme.metricLg(color: Colors.white),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Hemat yang udah beneran masuk kantong',
            style: AppTheme.bodySm(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _walletChip(
                label: 'Eco-Poin',
                value: '$_ecoPoin',
                onTap: () => _nag('Eco-Poin, tukar voucher ongkir segera hadir.'),
              ),
              const SizedBox(width: 10),
              _walletChip(
                label: 'Isi Saldo',
                value: '→',
                onTap: () => _nag('Dompet Rescue, fitur isi saldo segera hadir.'),
              ),
              const SizedBox(width: 10),
              _walletChip(
                label: 'Tarik Dana',
                value: '→',
                onTap: () => _nag('Dompet Rescue, penarikan dana segera hadir.'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _walletChip({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelCaps(color: Colors.white),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: AppTheme.metricSm(color: AppColors.primaryFixed),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _impactCard() {
    final kg = _impact?.totalFoodSavedKg ?? 0;
    final co2 = _impact?.estimatedCo2SavedKg ?? 0;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SEKILAS DAMPAK KAMU',
                  style: AppTheme.labelCaps(color: AppColors.outline),
                ),
              ),
              Text(
                'Update otomatis',
                style: AppTheme.labelCaps(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _impactMetric(kg.toStringAsFixed(1), 'Makanan (kg)'),
              const SizedBox(width: 12),
              _impactMetric(co2.toStringAsFixed(1), 'Emisi CO2 (kg)'),
              const SizedBox(width: 12),
              _impactMetric(Fmt.money(_impact?.totalMoneySaved ?? 0), 'Total Hemat'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: () => AppNav.tabIndex.value = AppNav.dampak,
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: const BorderSide(color: AppColors.outlineVariant),
              ),
              child: const Text('Lihat Laporan Lengkap'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _impactMetric(String value, String label) {
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
              child: Text(
                value,
                style: AppTheme.metricSm(color: AppColors.primary),
              ),
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: AppTheme.headlineSm().copyWith(fontSize: 17)),
    );
  }

  Widget _tokosStrip() {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tokos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final t = _tokos[i];
          return Container(
            width: 170,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t.businessName.isEmpty ? 'Mitra Toko' : t.businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelMd(),
                ),
                const SizedBox(height: 2),
                Text(
                  t.businessCategory.isEmpty
                      ? 'Kuliner'
                      : Fmt.toTitleCase(t.businessCategory),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _settingsList() {
    final rows = <(IconData, String, String, VoidCallback)>[
      (
        Icons.face,
        'Ubah Profil',
        'Ganti nama & avatar kamu',
        _editProfile,
      ),
      (
        Icons.receipt_long,
        'Riwayat Transaksi & Nota Digital',
        '$_level pesanan terselamatkan bulan ini',
        () => AppNav.tabIndex.value = AppNav.pesanan,
      ),
      (
        Icons.psychology,
        'Preferensi Diet & Alergi',
        'AI otomatis seleksi & filter katalog',
        () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AiNutrisiScreen()),
        ),
      ),
      (
        Icons.credit_card,
        'Metode Pembayaran Tersimpan',
        'QRIS sebagai metode utama',
        () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MetodePembayaranScreen()),
        ),
      ),
      (
        Icons.help_center,
        'Bantuan Penyelamatan & CS 24/7',
        'Hubungi CS, FAQ, dan pusat resolusi pesanan',
        () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BantuanScreen()),
        ),
      ),
      (
        Icons.sync_alt,
        'Mode Multi-Role (Mitra/Kurir)',
        'Beralih ke konsol toko atau armada',
        () => _nag('Mode multi-role, segera hadir.'),
      ),
      (
        Icons.logout,
        'Keluar dari Akun',
        'Aman & terlindungi',
        _logout,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(rows.length, (i) {
          final (icon, title, subtitle, onTap) = rows[i];
          return Column(
            children: [
              if (i > 0) const Divider(height: 1, indent: 56),
              InkWell(
                onTap: onTap,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Icon(icon, size: 22, color: i == rows.length - 1
                          ? AppColors.secondary
                          : AppColors.primary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: AppTheme.bodyMd().copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.bodySm(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppColors.outline,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _nag(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}