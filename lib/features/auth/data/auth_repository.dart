import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient _api = ApiClient.instance;
  static const _localPmKey = 'saved_payment_methods';

  Future<AuthResponse> login({required String email, required String password}) async {
    final data = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return AuthResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phoneNumber,
  }) async {
    final data = await _api.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'role': role,
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
    });
    return AuthResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<AuthResponse> googleLogin({required String idToken}) async {
    final data = await _api.post('/auth/google', data: {
      'id_token': idToken,
    });
    return AuthResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<UserModel> getProfile() async {
    final data = await _api.get('/auth/profile');
    // Profil bisa langsung atau nested { data: {...} }
    Map<String, dynamic> o = data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return UserModel.fromJson(o);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> payload) async {
    final data = await _api.put('/users/me/profile', data: payload);
    Map<String, dynamic> o = data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return UserModel.fromJson(o);
  }

  Future<TokoProfileModel> getMyTokoProfile() async {
    final data = await _api.get('/tokos/me/profile');
    Map<String, dynamic> o = data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return TokoProfileModel.fromJson(o);
  }

  Future<TokoProfileModel> createTokoProfile(Map<String, dynamic> payload) async {
    final data = await _api.post('/tokos', data: payload);
    Map<String, dynamic> o = data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return TokoProfileModel.fromJson(o);
  }

  Future<TokoProfileModel> updateTokoProfile(Map<String, dynamic> payload) async {
    final data = await _api.put('/tokos/me/profile', data: payload);
    Map<String, dynamic> o = data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return TokoProfileModel.fromJson(o);
  }

  Future<CourierProfileModel> getMyCourierProfile() async {
    final data = await _api.get('/kurirs/me/profile');
    Map<String, dynamic> o = data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return CourierProfileModel.fromJson(o);
  }

  Future<CourierProfileModel> createCourierProfile(Map<String, dynamic> payload) async {
    final data = await _api.post('/kurirs/me/profile', data: payload);
    Map<String, dynamic> o = data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return CourierProfileModel.fromJson(o);
  }

  Future<List<PaymentMethodModel>> getMyPaymentMethods() async {
    try {
      final data = await _api.get('/users/payment-methods');
      final list = data is Map<String, dynamic> && data['payment_methods'] is List
          ? data['payment_methods'] as List
          : data is List
              ? data
              : <dynamic>[];
      final methods = list
          .whereType<Map<String, dynamic>>()
          .map(PaymentMethodModel.fromJson)
          .toList();
      await _cacheMethodsLocal(methods);
      return methods;
    } catch (_) {
      return _localMethods();
    }
  }

  Future<PaymentMethodModel> addPaymentMethod({
    required String provider,
    required String accountReference,
  }) async {
    try {
      final data = await _api.post('/users/payment-methods', data: {
        'provider': provider,
        'account_reference': accountReference,
      });
      final id = data is Map<String, dynamic>
          ? (data['payment_method_id'] as String? ?? '')
          : '';
      final list = await _localMethods();
      final m = PaymentMethodModel(
        id: id,
        provider: provider,
        accountReference: accountReference,
        isDefault: list.isEmpty,
        createdAt: DateTime.now(),
      );
      list.add(m);
      await _saveLocal(list);
      return m;
    } catch (_) {
      final list = await _localMethods();
      final m = PaymentMethodModel(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        provider: provider,
        accountReference: accountReference,
        isDefault: list.isEmpty,
        createdAt: DateTime.now(),
      );
      list.add(m);
      await _saveLocal(list);
      return m;
    }
  }

  Future<List<PaymentMethodModel>> _localMethods() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getStringList(_localPmKey) ?? const [];
      return raw
          .map((s) {
            try {
              return PaymentMethodModel.fromJson(
                jsonDecode(s) as Map<String, dynamic>,
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<PaymentMethodModel>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheMethodsLocal(List<PaymentMethodModel> methods) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(
        _localPmKey,
        methods.map((m) => jsonEncode(m.toJson())).toList(),
      );
    } catch (_) {}
  }

  Future<void> _saveLocal(List<PaymentMethodModel> methods) =>
      _cacheMethodsLocal(methods);
}