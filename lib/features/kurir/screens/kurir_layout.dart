import 'package:flutter/material.dart';

import '../../../core/utils/app_theme.dart';

class KurirLayout extends StatelessWidget {
  const KurirLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Kurir', style: AppTheme.headlineSm()),
      ),
      body: const Center(
        child: Text(
          'Dashboard Kurir, segera hadir.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}