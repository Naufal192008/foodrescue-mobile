import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_theme.dart';
import '../controllers/auth_controller.dart';

enum AuthMode { login, register }

/// Screen gabungan Login & Register (PRD 9.1) — segmented switcher
/// "Masuk" / "Daftar Akun Baru", dengan Google fast-pass dan pemilihan role.
class LoginScreen extends ConsumerStatefulWidget {
  final AuthMode initialMode;
  const LoginScreen({super.key, this.initialMode = AuthMode.login});

  @override
  ConsumerState<LoginScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<LoginScreen> {
  late AuthMode _mode;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _agree = false;
  late String _selectedRole;

  static const _roles = [
    (value: 'user', label: 'Rescuer (Konsumen)', desc: 'Beli & selamatkan surplus makanan lezat diskon s/d 70%.', icon: Icons.eco),
    (value: 'toko', label: 'Mitra Toko & Resto', desc: 'Jual kelebihan stok harian & tingkatkan efisiensi operasional.', icon: Icons.storefront),
    (value: 'kurir', label: 'Kurir Penyelamat', desc: 'Antar penyelamatan makanan tepat waktu & lacak rute live.', icon: Icons.electric_moped),
  ];

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _selectedRole = _roles.first.value;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mode == AuthMode.register && !_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setujui Ketentuan Layanan & Privasi terlebih dahulu.')),
      );
      return;
    }
    final auth = ref.read(authControllerProvider.notifier);
    if (_mode == AuthMode.login) {
      await auth.login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
    } else {
      await auth.register(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        fullName: _nameCtrl.text.trim(),
        role: _selectedRole,
      );
    }
    final state = ref.read(authControllerProvider);
    if (state.isAuthenticated && mounted) {
      context.go(_homeForRole(state.user?.role));
    } else if (state.error != null && state.error!.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  String _homeForRole(String? role) {
    switch (role) {
      case 'toko':
      case 'admin':
        return '/toko';
      case 'kurir':
        return '/kurir';
      default:
        return '/user';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _brandHeader(),
              const SizedBox(height: 20),
              _segmentedSwitcher(),
              const SizedBox(height: 20),
              _googleButton(state.isLoading),
              _divider('atau masuk dengan email'),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_mode == AuthMode.register) ...[
                      _label('Nama Lengkap'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Raden Fajar Pratama',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _label('Alamat Email'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'nama@email.com',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) =>
                          v == null || !v.contains('@') ? 'Email tidak valid' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _label('Kata Sandi')),
                        if (_mode == AuthMode.login)
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Lupa Kata Sandi?',
                              style: AppTheme.labelMd(color: AppColors.secondary),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: '••••••••••••',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.length < 6 ? 'Minimal 6 karakter' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_mode == AuthMode.register)
                      Row(
                        children: [
                          Checkbox(
                            value: _agree,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _agree = v ?? false),
                          ),
                          Expanded(
                            child: Text(
                              'Saya menyetujui Ketentuan Layanan & Privasi',
                              style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Checkbox(
                            value: _agree,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _agree = v ?? false),
                          ),
                          Expanded(
                            child: Text(
                              'Ingat Saya di Perangkat Ini',
                              style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    _roleSection(),
                    const SizedBox(height: 24),
                    _submitButton(state.isLoading),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Dilindungi enkripsi end-to-end • Food Rescue',
                  style: AppTheme.bodySm(color: AppColors.outline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
          ),
          child: Image.asset('assets/images/Foodrescue.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'FOOD RESCUE',
                  style: AppTheme.headlineSm().copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Text(
              'Taste Without Waste',
              style: AppTheme.bodySm(color: AppColors.outline),
            ),
          ],
        ),
      ],
    );
  }

  Widget _segmentedSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segment(
              label: 'Masuk',
              active: _mode == AuthMode.login,
              onTap: () => setState(() => _mode = AuthMode.login),
            ),
          ),
          Expanded(
            child: _segment(
              label: 'Daftar Akun Baru',
              active: _mode == AuthMode.register,
              onTap: () => setState(() => _mode = AuthMode.register),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment({required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.labelMd(
            color: active ? AppColors.primary : AppColors.outline,
          ),
        ),
      ),
    );
  }

  Widget _googleButton(bool isLoading) {
    return OutlinedButton.icon(
      onPressed: isLoading
          ? null
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Google Sign-In belum dikonfigurasi di perangkat ini. Gunakan email untuk demo.',
                  ),
                ),
              );
            },
      icon: const SizedBox(
        width: 20,
        height: 20,
        child: Icon(Icons.g_mobiledata, size: 26),
      ),
      label: const Text('Lanjutkan dengan Google'),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surfaceContainerLowest,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: AppColors.hairline),
      ),
    );
  }

  Widget _divider(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.surfaceContainerHighest)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(text, style: AppTheme.labelCaps(color: AppColors.outline)),
          ),
          const Expanded(child: Divider(color: AppColors.surfaceContainerHighest)),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: AppTheme.labelMd(color: AppColors.onSurface));
  }

  Widget _roleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Peran Ekosistem',
          style: AppTheme.labelMd(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Column(
          children: _roles.map((r) {
            final selected = _selectedRole == r.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _selectedRole = r.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryFixed
                              : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(r.icon, size: 22, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.label, style: AppTheme.bodyMd().copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(r.desc, style: AppTheme.bodySm(color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: selected
                            ? const Icon(Icons.check, size: 14, color: AppColors.onPrimary)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _submitButton(bool isLoading) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: isLoading ? null : _submit,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.onPrimary),
              )
            : const Icon(Icons.arrow_forward, size: 18),
        label: Text(
          isLoading
              ? 'Memproses...'
              : _mode == AuthMode.login
                  ? 'Masuk ke Akun'
                  : 'Daftar & Masuk Dashboard',
        ),
      ),
    );
  }
}