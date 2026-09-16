import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_theme.dart';

class LogoHeader extends StatelessWidget {
  final double size;
  const LogoHeader({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset(
            'assets/images/Foodrescue.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'FoodRescue',
          style: TextStyle(
            fontSize: size * 0.28,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const Text(
          'Selamatkan Makanan, Bagikan Kebaikan',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );
  }
}

class NetworkImageOrPlaceholder extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final BoxFit fit;

  const NetworkImageOrPlaceholder({
    super.key,
    this.url,
    this.width = double.infinity,
    this.height = 160,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final valid = url != null && url!.isNotEmpty;
    if (!valid) {
      return Container(
        width: width,
        height: height,
        color: AppColors.primaryFixed.withOpacity(0.15),
        child: const Icon(
          Icons.restaurant_menu,
          size: 48,
          color: AppColors.primary,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (c, _) => Container(
        width: width,
        height: height,
        color: AppColors.primaryFixed.withOpacity(0.1),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (c, _, __) => Container(
        width: width,
        height: height,
        color: AppColors.primaryFixed.withOpacity(0.15),
        child: const Icon(
          Icons.broken_image_outlined,
          size: 40,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AppColors.primaryFixedDim),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 15),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 68, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 15),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Coba lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const SectionTitle({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(
                trailing!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SafeAreaScaffold extends ConsumerWidget {
  final String? title;
  final Widget body;
  final Widget? bottomNavigationBar;
  final FloatingActionButton? fab;
  final bool showBack;
  final List<Widget>? actions;

  const SafeAreaScaffold({
    super.key,
    this.title,
    required this.body,
    this.bottomNavigationBar,
    this.fab,
    this.showBack = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              leading: showBack ? BackButton() : const SizedBox.shrink(),
              actions: actions,
            ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: fab,
    );
  }
}

enum LoadingOverlay { onPage }