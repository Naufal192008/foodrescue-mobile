import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_theme.dart';

/// Layar verifikasi email untuk akun yang masih pending verifikasi.
class VerifyPendingScreen extends StatelessWidget {
  const VerifyPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 44,
                  color: AppColors.onPrimary,
                ),
              ),
              const SizedBox(height: 32),
              Text('Periksa Email Kamu', style: AppTheme.headlineLg(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Kami udah kirim tautan verifikasi ke email kamu. '
                'Setelah diverifikasi, kamu bisa masuk lagi ke aplikasi.',
                style: AppTheme.bodyLg(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Kembali ke Masuk'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}