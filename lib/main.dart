import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/utils/app_theme.dart';
import 'features/auth/controllers/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  //lah
  runApp(const ProviderScope(child: FoodRescueApp()));
}

class FoodRescueApp extends ConsumerStatefulWidget {
  const FoodRescueApp({super.key});

  @override
  ConsumerState<FoodRescueApp> createState() => _FoodRescueAppState();
}

class _FoodRescueAppState extends ConsumerState<FoodRescueApp> {
  @override
  void initState() {
    super.initState();
    // Restore session sebelum router siap redirect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Food Rescue',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}