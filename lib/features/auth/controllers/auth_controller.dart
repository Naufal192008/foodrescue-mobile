import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/auth_storage.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthState {
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final String? token;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.token,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
    String? token,
    bool? isAuthenticated,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      user: user ?? this.user,
      token: token ?? this.token,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(AuthState());

  /// Restore session dari secure storage saat app start
  Future<void> restoreSession() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        return;
      }
      final storedJson = await AuthStorage.getUserJson();
      if (storedJson != null && storedJson.isNotEmpty) {
        final user = UserModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(storedJson) as Map),
        );
        state = state.copyWith(
          user: user,
          token: token,
          isAuthenticated: true,
          clearError: true,
        );
      } else {
        final user = await _repo.getProfile();
        state = state.copyWith(
          user: user,
          token: token,
          isAuthenticated: true,
          clearError: true,
        );
        await AuthStorage.saveSession(
          token: token,
          role: user.role,
          userJson: jsonEncode(user.toJson()),
        );
      }
    } catch (e) {
      // Token invalid → bersihkan
      await logout();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.login(email: email, password: password);
      await AuthStorage.saveSession(
        token: res.token,
        role: res.user.role,
        userJson: jsonEncode(res.user.toJson()),
      );
      state = state.copyWith(
        user: res.user,
        token: res.token,
        isAuthenticated: true,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phoneNumber: phoneNumber,
      );
      await AuthStorage.saveSession(
        token: res.token,
        role: res.user.role,
        userJson: jsonEncode(res.user.toJson()),
      );
      state = state.copyWith(
        user: res.user,
        token: res.token,
        isAuthenticated: true,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> googleSignIn(String idToken) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.googleLogin(idToken: idToken);
      await AuthStorage.saveSession(
        token: res.token,
        role: res.user.role,
        userJson: jsonEncode(res.user.toJson()),
      );
      state = state.copyWith(
        user: res.user,
        token: res.token,
        isAuthenticated: true,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateUser(UserModel user) async {
    await AuthStorage.saveSession(
      token: state.token ?? '',
      role: user.role,
      userJson: jsonEncode(user.toJson()),
    );
    state = state.copyWith(user: user, clearError: true);
  }

  Future<void> logout() async {
    await AuthStorage.clear();
    state = AuthState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authControllerProvider);
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isAuthenticated;
});
