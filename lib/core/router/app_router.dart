import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/verify_pending_screen.dart';
import '../../features/kurir/screens/kurir_layout.dart';
import '../../features/toko/screens/toko_layout.dart';
import '../../features/user/screens/user_layout.dart';
import '../../features/auth/screens/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loggedIn = auth.isAuthenticated;
      final role = auth.user?.role;
      final path = state.uri.path;

      // Splash selalu bebas
      if (path == '/splash') return null;

      final isAuthPage = path == '/login' || path == '/register';
      final isHome = path == '/' || path.startsWith('/user') || path.startsWith('/toko') || path.startsWith('/kurir');

      if (!loggedIn && isHome) return '/login';
      if (loggedIn && isAuthPage) return _homeForRole(role);

      // Pastikan user yang sudah login tidak mengakses role lain
      if (loggedIn) {
        if (path.startsWith('/user') && role != 'user') return _homeForRole(role);
        if (path.startsWith('/toko') && !['toko', 'admin'].contains(role)) return _homeForRole(role);
        if (path.startsWith('/kurir') && role != 'kurir') return _homeForRole(role);
      }

      // Root saat login → role home
      if (loggedIn && path == '/') return _homeForRole(role);

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/verify-pending',
        builder: (context, state) => const VerifyPendingScreen(),
      ),
      GoRoute(
        path: '/user',
        builder: (context, state) => const UserLayout(),
      ),
      GoRoute(
        path: '/toko',
        builder: (context, state) => const TokoLayout(),
      ),
      GoRoute(
        path: '/kurir',
        builder: (context, state) => const KurirLayout(),
      ),
    ],
  );
});

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

/// Listen auth state changes untuk refresh redirect
class _RouterRefresh extends ChangeNotifier {
  final Ref ref;
  _RouterRefresh(this.ref) {
    ref.listen<AuthState>(authControllerProvider, (_, __) => notifyListeners());
  }
}