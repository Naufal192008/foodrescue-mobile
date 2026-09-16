import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

class ListingRepository {
  final ApiClient _api = ApiClient.instance;

  Future<PaginatedResult<FoodListingModel>> getListings({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  }) async {
    final data = await _api.get(
      '/listings',
      query: {
        'page': page,
        'limit': limit,
        if (category != null && category.isNotEmpty) 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return PaginatedResult<FoodListingModel>.fromJson(
      data as Map<String, dynamic>,
      FoodListingModel.fromJson,
    );
  }

  Future<FoodListingModel> getListing(String id) async {
    final data = await _api.get('/listings/$id');
    Map<String, dynamic> o = data is Map<String, dynamic> && data['listing'] is Map<String, dynamic>
        ? data['listing'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return FoodListingModel.fromJson(o);
  }

  /// Membuat pesanan baru (role user).
  /// - [fulfillmentMethod]: `pickup_mandiri` | `diantar_kurir`
  Future<Map<String, dynamic>> createOrder({
    required String listingId,
    required int quantity,
    required String fulfillmentMethod,
    String? paymentMethod,
  }) async {
    final data = await _api.post('/orders', data: {
      'listing_id': listingId,
      'quantity': quantity,
      'fulfillment_method': fulfillmentMethod,
      if (paymentMethod != null && paymentMethod.isNotEmpty)
        'payment_method': paymentMethod,
    });
    return (data as Map<String, dynamic>).cast<String, dynamic>();
  }

  /// Konfirmasi pembayaran (manual fallback karena gateway belum dikonfigurasi).
  Future<void> confirmPayment({
    required String orderId,
    required String paymentMethod,
  }) async {
    await _api.post('/orders/$orderId/confirm-payment', data: {
      'payment_method': paymentMethod,
    });
  }

  /// Membuat Qris Charge via Midtrans (v4/charge, payment_type=qris).
  /// Bila server key belum diset, backend mengembalikan status "manual".
  Future<Map<String, dynamic>> createQris({required String orderId}) async {
    final data = await _api.post('/payments/qris', data: {
      'order_id': orderId,
    });
    return (data as Map<String, dynamic>).cast<String, dynamic>();
  }

  /// Ambil status order terkini (dipakai untuk polling pembayaran).
  Future<OrderModel> refreshOrder(String orderId) => getOrder(orderId);

  /// Daftar pesanan milik user.
  Future<List<OrderModel>> getMyOrders() async {
    final data = await _api.get('/orders/me');
    final raw = data is Map<String, dynamic> ? data['orders'] : null;
    final list = raw is List ? raw : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
  }

  Future<OrderModel> getOrder(String orderId) async {
    final data = await _api.get('/orders/$orderId');
    Map<String, dynamic> o = data is Map<String, dynamic> && data['order'] is Map<String, dynamic>
        ? data['order'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return OrderModel.fromJson(o);
  }

  /// Data delivery untuk order (role user). Kembalikan null bila 404 / bukan kurir.
  Future<DeliveryModel?> getDeliveryForOrder(String orderId) async {
    try {
      final data = await _api.get('/deliveries/order/$orderId');
      Map<String, dynamic>? d;
      if (data is Map<String, dynamic>) {
        d = data['delivery'] is Map<String, dynamic>
            ? data['delivery'] as Map<String, dynamic>
            : data;
      }
      return d == null ? null : DeliveryModel.fromJson(d);
    } catch (_) {
      return null;
    }
  }

  /// Profil user saat ini (role user).
  Future<UserModel> getMyProfile() async {
    final data = await _api.get('/auth/profile');
    final o = data is Map<String, dynamic> && data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return UserModel.fromJson(o);
  }

  /// Ringkasan dampak ekologis & finansial user.
  Future<ImpactSummaryModel> getMyImpact() async {
    final data = await _api.get('/users/me/impact');
    final o = data is Map<String, dynamic> && data['impact'] is Map<String, dynamic>
        ? data['impact'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return ImpactSummaryModel.fromJson(o);
  }

  /// Daftar post komunitas yang tersedia untuk diklaim.
  Future<List<CommunityPostCardModel>> getCommunityPosts() async {
    final data = await _api.get('/community');
    final raw = data is Map<String, dynamic> ? data['community_posts'] : null;
    return (raw is List ? raw : <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(CommunityPostCardModel.fromJson)
        .toList();
  }

  /// Klaim post komunitas (role user).
  Future<void> claimCommunityPost(String postId) async {
    await _api.post('/community/claim', data: {
      'community_post_id': postId,
    });
  }

  /// Siaga darurat NGO yang sedang aktif.
  Future<List<EmergencyAlertModel>> getEmergencyAlerts() async {
    final data = await _api.get('/emergency/alerts');
    final raw = data is Map<String, dynamic> ? data['alerts'] : null;
    return (raw is List ? raw : <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(EmergencyAlertModel.fromJson)
        .toList();
  }

  /// Daftar toko terverifikasi (untuk mitra favorit di profil).
  Future<List<TokoProfileModel>> getApprovedTokos() async {
    final data = await _api.get('/tokos');
    final raw = data is Map<String, dynamic> ? data['tokos'] : null;
    return (raw is List ? raw : <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(TokoProfileModel.fromJson)
        .toList();
  }

  /// Profil toko (untuk cari `user_id` pemilik saat rating).
  Future<TokoProfileModel> getTokoProfile(String tokoId) async {
    final data = await _api.get('/tokos/$tokoId');
    final o = data is Map<String, dynamic> &&
            data['toko_profile'] is Map<String, dynamic>
        ? data['toko_profile'] as Map<String, dynamic>
        : data is Map<String, dynamic> && data['toko'] is Map<String, dynamic>
            ? data['toko'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
    return TokoProfileModel.fromJson(o);
  }

  /// Chat yang terhubung ke order user.
  Future<List<ChatModel>> getMyChats() async {
    final data = await _api.get('/chats/me');
    final raw = data is Map<String, dynamic> ? data['chats'] : null;
    return (raw is List ? raw : <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ChatModel.fromJson)
        .toList();
  }

  /// Pastikan chat untuk order tersedia; kembalikan chat_id.
  Future<String> ensureChatForOrder(String orderId) async {
    final data = await _api.post('/chats', data: {'order_id': orderId});
    final o = data as Map<String, dynamic>;
    return o['chat_id'] as String? ?? '';
  }

  /// Riwayat pesan sebuah chat (urutan kronologis).
  Future<List<ChatMessageModel>> getMessages(String chatId) async {
    final data = await _api.get('/chats/$chatId/messages');
    final raw = data is Map<String, dynamic> ? data['messages'] : null;
    return (raw is List ? raw : <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ChatMessageModel.fromJson)
        .toList();
  }

  /// Kirim pesan ke chat.
  Future<void> sendMessage(String chatId, String text) async {
    await _api.post('/chats/$chatId/messages', data: {'message_text': text});
  }

  /// Kirim rating untuk toko/kurir (role user).
  Future<void> submitRating({
    required String orderId,
    required String rateeUserId,
    required String ratingTarget,
    required int score,
    String? reviewText,
  }) async {
    await _api.post('/ratings', data: {
      'order_id': orderId,
      'ratee_user_id': rateeUserId,
      'rating_target': ratingTarget,
      'score': score,
      if (reviewText != null && reviewText.isNotEmpty)
        'review_text': reviewText,
    });
  }

  /// Rating yang sudah diberikan user.
  Future<List<RatingModel>> getMyGivenRatings() async {
    final data = await _api.get('/ratings/me/given');
    final raw = data is Map<String, dynamic> ? data['ratings'] : null;
    return (raw is List ? raw : <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(RatingModel.fromJson)
        .toList();
  }

  /// Tanya AI nutrisi tentang sebuah listing.
  Future<AiChatResult> aiChat({
    required String listingId,
    required String message,
  }) async {
    final data = await _api.post('/ai/chat', data: {
      'listing_id': listingId,
      'message': message,
    });
    return AiChatResult.fromJson((data as Map<String, dynamic>).cast());
  }

  /// Lanjutkan percakapan AI.
  Future<String> aiContinue({
    required String conversationId,
    required String message,
  }) async {
    final data = await _api.post(
      '/ai/conversations/$conversationId/messages',
      data: {'message': message},
    );
    return (data as Map<String, dynamic>)['reply'] as String? ?? '';
  }
}