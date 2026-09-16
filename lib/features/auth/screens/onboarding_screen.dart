import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = const [
    _OnboardData(
      icon: Icons.eco,
      title: 'Selamatkan Makanan',
      description: 'Temukan surplus makanan berkualitas dari toko dan restoran terdekat dengan harga hingga 70% lebih hemat.',
    ),
    _OnboardData(
      icon: Icons.delivery_dining,
      title: 'Kurir Khusus',
      description: 'Makanan dikirim oleh kurir bersertifikat dengan cold chain terjaga menggunakan armada Eco-Fleet listrik.',
    ),
    _OnboardData(
      icon: Icons.leaderboard,
      title: 'Lihat Dampakmu',
      description: 'Pantau berapa kilogram makanan yang sudah kamu selamatkan dan dampak karbon positifmu.',
    ),
  ];

  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text('Lewati', style: AppTheme.labelMd(color: AppColors.outline)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (ctx, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(p.icon, size: 48, color: AppColors.primaryContainer),
                        ),
                        const SizedBox(height: 36),
                        Text(p.title, style: AppTheme.headlineLg()),
                        const SizedBox(height: 12),
                        Text(
                          p.description,
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyLg(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _current == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _current == i
                              ? AppColors.primaryContainer
                              : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _next,
                      icon: Icon(
                        _current == _pages.length - 1
                            ? Icons.arrow_forward
                            : Icons.arrow_forward,
                        size: 18,
                      ),
                      label: Text(
                        _current == _pages.length - 1 ? 'Mulai Sekarang' : 'Lanjut',
                      ),
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
}

class _OnboardData {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardData({
    required this.icon,
    required this.title,
    required this.description,
  });
}