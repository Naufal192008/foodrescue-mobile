import 'package:flutter/material.dart';

import '../../../core/utils/app_theme.dart';

class TokoLayout extends StatelessWidget {
  const TokoLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mitra Toko', style: AppTheme.headlineSm()),
      ),
      body: const Center(
        child: Text(
          'Dashboard Toko, segera hadir.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}