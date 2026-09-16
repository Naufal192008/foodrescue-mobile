class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? photoUrl;
  final String? phoneNumber;
  final String authProvider;
  final String role;
  final bool isNgoVerified;
  final double trustScore;
  final double? latitude;
  final double? longitude;
  final String? addressText;
  final String accountStatus;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.photoUrl,
    this.phoneNumber,
    required this.authProvider,
    required this.role,
    required this.isNgoVerified,
    required this.trustScore,
    this.latitude,
    this.longitude,
    this.addressText,
    required this.accountStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
      authProvider: json['auth_provider'] as String? ?? 'email_password',
      role: json['role'] as String? ?? 'user',
      isNgoVerified: json['is_ngo_verified'] as bool? ?? false,
      trustScore: (json['trust_score'] as num?)?.toDouble() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      addressText: json['address_text'] as String?,
      accountStatus: json['account_status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'photo_url': photoUrl,
        'phone_number': phoneNumber,
        'auth_provider': authProvider,
        'role': role,
        'is_ngo_verified': isNgoVerified,
        'trust_score': trustScore,
        'latitude': latitude,
        'longitude': longitude,
        'address_text': addressText,
        'account_status': accountStatus,
      };
}

class AuthResponse {
  final String token;
  final UserModel user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token'] as String? ?? '',
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      );
}

class TokoProfileModel {
  final String id;
  final String userId;
  final String businessName;
  final String businessCategory;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? legalDocumentUrl;
  final String? operationalHours;
  final String verificationStatus;
  final double averageRating;

  TokoProfileModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.businessCategory,
    required this.address,
    this.latitude,
    this.longitude,
    this.legalDocumentUrl,
    this.operationalHours,
    required this.verificationStatus,
    required this.averageRating,
  });

  factory TokoProfileModel.fromJson(Map<String, dynamic> json) =>
      TokoProfileModel(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        businessName: json['business_name'] as String? ?? '',
        businessCategory: json['business_category'] as String? ?? '',
        address: json['address'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        legalDocumentUrl: json['legal_document_url'] as String?,
        operationalHours: json['operational_hours'] as String?,
        verificationStatus: json['verification_status'] as String? ?? 'pending',
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      );
}

class CourierProfileModel {
  final String id;
  final String userId;
  final String vehicleType;
  final String verificationStatus;
  final bool isOnline;
  final double averageRating;
  final double totalEarnings;

  CourierProfileModel({
    required this.id,
    required this.userId,
    required this.vehicleType,
    required this.verificationStatus,
    required this.isOnline,
    required this.averageRating,
    required this.totalEarnings,
  });

  factory CourierProfileModel.fromJson(Map<String, dynamic> json) =>
      CourierProfileModel(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        vehicleType: json['vehicle_type'] as String? ?? '',
        verificationStatus: json['verification_status'] as String? ?? 'pending',
        isOnline: json['is_online'] as bool? ?? false,
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
        totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0,
      );
}

class FoodListingModel {
  final String id;
  final String tokoId;
  final String name;
  final String category;
  final String? description;
  final String? photoUrl;
  final double initialPrice;
  final double minimumPrice;
  final double currentPrice;
  final int stockQuantity;
  final String? foodSafetyNotes;
  final String? safeUntil;
  final String? pickupStartTime;
  final String? pickupEndTime;
  final String status;
  final String? tokoName;
  final String? address;
  final String? distanceKm;

  FoodListingModel({
    required this.id,
    required this.tokoId,
    required this.name,
    required this.category,
    this.description,
    this.photoUrl,
    required this.initialPrice,
    required this.minimumPrice,
    required this.currentPrice,
    required this.stockQuantity,
    this.foodSafetyNotes,
    this.safeUntil,
    this.pickupStartTime,
    this.pickupEndTime,
    required this.status,
    this.tokoName,
    this.address,
    this.distanceKm,
  });

  factory FoodListingModel.fromJson(Map<String, dynamic> json) {
    // Respon listing bisa dalam bentuk object langsung,
    // maupun nested di dalam object "listing" (mis. dari order).
    Map<String, dynamic> o = json['listing'] is Map<String, dynamic>
        ? json['listing'] as Map<String, dynamic>
        : json;

    // Distance bisa di level paling luar (hasil query spasial)
    double? dist = json['distance_km'] is num
        ? (json['distance_km'] as num).toDouble()
        : o['distance_km'] is num
            ? (o['distance_km'] as num).toDouble()
            : null;

    return FoodListingModel(
      id: o['id'] as String? ?? '',
      tokoId: o['toko_id'] as String? ?? '',
      name: o['name'] as String? ?? '',
      category: o['category'] as String? ?? '',
      description: o['description'] as String?,
      photoUrl: o['photo_url'] as String? ?? json['photo_url'] as String?,
      initialPrice: (o['initial_price'] as num?)?.toDouble() ??
          (json['initial_price'] as num?)?.toDouble() ??
          0,
      minimumPrice: (o['minimum_price'] as num?)?.toDouble() ??
          (json['minimum_price'] as num?)?.toDouble() ??
          0,
      currentPrice: (o['current_price'] as num?)?.toDouble() ??
          (json['current_price'] as num?)?.toDouble() ??
          0,
      stockQuantity: o['stock_quantity'] as int? ??
          (json['stock_quantity'] as num?)?.toInt() ??
          0,
      foodSafetyNotes: o['food_safety_notes'] as String?,
      safeUntil: o['safe_until'] as String? ?? json['safe_until'] as String?,
      pickupStartTime:
          o['pickup_start_time'] as String? ?? json['pickup_start_time'] as String?,
      pickupEndTime:
          o['pickup_end_time'] as String? ?? json['pickup_end_time'] as String?,
      status: o['status'] as String? ?? json['status'] as String? ?? 'active',
      tokoName: o['toko_name'] as String? ?? json['toko_name'] as String?,
      address: o['address'] as String? ?? json['address'] as String?,
      distanceKm: dist?.toStringAsFixed(1),
    );
  }
}

class OrderModel {
  final String id;
  final String listingId;
  final String userId;
  final int quantity;
  final double priceAtPurchase;
  final double totalAmount;
  final String fulfillmentMethod;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String confirmationCode;
  final DateTime? createdAt;
  final String? completedAt;
  final FoodListingModel? listing;
  final String? pickupAddress;
  final Map<String, dynamic> raw;

  OrderModel({
    required this.id,
    required this.listingId,
    required this.userId,
    required this.quantity,
    required this.priceAtPurchase,
    required this.totalAmount,
    required this.fulfillmentMethod,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.confirmationCode,
    this.createdAt,
    this.completedAt,
    this.listing,
    this.pickupAddress,
    required this.raw,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String? ?? '',
        listingId: json['listing_id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 1,
        priceAtPurchase: (json['price_at_purchase'] as num?)?.toDouble() ?? 0,
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        fulfillmentMethod: json['fulfillment_method'] as String? ?? '',
        paymentMethod: json['payment_method'] as String? ?? '',
        paymentStatus: json['payment_status'] as String? ?? 'unpaid',
        orderStatus: json['order_status'] as String? ?? 'pending',
        confirmationCode: json['confirmation_code'] as String? ?? '',
        createdAt: _parseDate(json['created_at'] ?? json['order_date'] ?? json['ordered_at']),
        completedAt: json['completed_at'] as String?,
        listing: json['listing'] is Map<String, dynamic>
            ? FoodListingModel.fromJson(json['listing'] as Map<String, dynamic>)
            : null,
        pickupAddress: json['pickup_address'] as String?,
        raw: json,
      );

  static DateTime? _parseDate(dynamic value) {
    return value is String ? DateTime.tryParse(value) : null;
  }

  bool get isPickupWindowOver {
    final endRaw = listing?.pickupEndTime;
    if (endRaw == null || endRaw.isEmpty) return false;
    final end = DateTime.tryParse(endRaw);
    if (end == null) return false;
    return DateTime.now().isAfter(end);
  }
}

class DeliveryModel {
  final String id;
  final String orderId;
  final String matchingStatus;
  final String? tripStatus;
  final double deliveryFee;

  DeliveryModel({
    required this.id,
    required this.orderId,
    required this.matchingStatus,
    this.tripStatus,
    required this.deliveryFee,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) => DeliveryModel(
        id: json['id'] as String? ?? '',
        orderId: json['order_id'] as String? ?? '',
        matchingStatus: json['matching_status'] as String? ?? '',
        tripStatus: json['trip_status'] as String?,
        deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      );
}

class PaginatedResult<T> {
  final List<T> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginatedResult({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parser,
  ) {
    final list = json['data'] as List<dynamic>? ?? [];
    return PaginatedResult(
      data: list
          .whereType<Map<String, dynamic>>()
          .map(parser)
          .toList(),
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }
}

class CommunityPostModel {
  final String id;
  final String listingId;
  final String tokoId;
  final String targetCategory;
  final double transportFee;
  final String claimStatus;

  CommunityPostModel({
    required this.id,
    required this.listingId,
    required this.tokoId,
    required this.targetCategory,
    required this.transportFee,
    required this.claimStatus,
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) =>
      CommunityPostModel(
        id: json['id'] as String? ?? '',
        listingId: json['listing_id'] as String? ?? '',
        tokoId: json['toko_id'] as String? ?? '',
        targetCategory: json['target_category'] as String? ?? '',
        transportFee: (json['transport_fee'] as num?)?.toDouble() ?? 0,
        claimStatus: json['claim_status'] as String? ?? 'available',
      );
}

class ImpactReportModel {
  final double totalFoodSavedKg;
  final double totalMoneyAmount;
  final double estimatedCo2SavedKg;

  ImpactReportModel({
    required this.totalFoodSavedKg,
    required this.totalMoneyAmount,
    required this.estimatedCo2SavedKg,
  });

  factory ImpactReportModel.fromJson(Map<String, dynamic> json) =>
      ImpactReportModel(
        totalFoodSavedKg:
            (json['total_food_saved_kg'] as num?)?.toDouble() ?? 0,
        totalMoneyAmount:
            (json['total_money_amount'] as num?)?.toDouble() ?? 0,
        estimatedCo2SavedKg:
            (json['estimated_co2_saved_kg'] as num?)?.toDouble() ?? 0,
      );
}

class AIConversationModel {
  final String id;
  final String sourceType;
  final String? detectedFoodName;
  final double? estimatedCalories;
  final double? estimatedProteinG;

  AIConversationModel({
    required this.id,
    required this.sourceType,
    this.detectedFoodName,
    this.estimatedCalories,
    this.estimatedProteinG,
  });

  factory AIConversationModel.fromJson(Map<String, dynamic> json) =>
      AIConversationModel(
        id: json['id'] as String? ?? '',
        sourceType: json['source_type'] as String? ?? '',
        detectedFoodName: json['detected_food_name'] as String?,
        estimatedCalories: (json['estimated_calories'] as num?)?.toDouble(),
        estimatedProteinG: (json['estimated_protein_g'] as num?)?.toDouble(),
      );
}

class RatingModel {
  final String id;
  final String rateeUserId;
  final String ratingTarget;
  final int score;
  final String reviewText;

  RatingModel({
    required this.id,
    required this.rateeUserId,
    required this.ratingTarget,
    required this.score,
    required this.reviewText,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) => RatingModel(
        id: json['id'] as String? ?? '',
        rateeUserId: json['ratee_user_id'] as String? ?? '',
        ratingTarget: json['rating_target'] as String? ?? '',
        score: json['score'] as int? ?? 0,
        reviewText: json['review_text'] as String? ?? '',
      );
}

class ImpactSummaryModel {
  final int totalOrders;
  final double totalFoodSavedKg;
  final double totalMoneySaved;
  final double estimatedCo2SavedKg;

  const ImpactSummaryModel({
    this.totalOrders = 0,
    this.totalFoodSavedKg = 0,
    this.totalMoneySaved = 0,
    this.estimatedCo2SavedKg = 0,
  });

  factory ImpactSummaryModel.fromJson(Map<String, dynamic> json) =>
      ImpactSummaryModel(
        totalOrders: json['total_orders'] as int? ?? 0,
        totalFoodSavedKg: (json['total_food_saved_kg'] as num?)?.toDouble() ?? 0,
        totalMoneySaved: (json['total_money_saved'] as num?)?.toDouble() ?? 0,
        estimatedCo2SavedKg:
            (json['estimated_co2_saved_kg'] as num?)?.toDouble() ?? 0,
      );
}

class CommunityPostCardModel {
  final String id;
  final String listingId;
  final String tokoId;
  final String targetCategory;
  final double transportFee;
  final String claimStatus;
  final String listingName;
  final String? listingPhoto;
  final String? listingDescription;
  final double? quantityKg;
  final int? beneficiaryCount;
  final String? targetLocation;
  final DateTime? createdAt;

  CommunityPostCardModel({
    required this.id,
    required this.listingId,
    required this.tokoId,
    required this.targetCategory,
    required this.transportFee,
    required this.claimStatus,
    required this.listingName,
    this.listingPhoto,
    this.listingDescription,
    this.quantityKg,
    this.beneficiaryCount,
    this.targetLocation,
    this.createdAt,
  });

  factory CommunityPostCardModel.fromJson(Map<String, dynamic> json) =>
      CommunityPostCardModel(
        id: json['id'] as String? ?? '',
        listingId: json['listing_id'] as String? ?? '',
        tokoId: json['toko_id'] as String? ?? '',
        targetCategory: json['target_category'] as String? ?? '',
        transportFee: (json['transport_fee'] as num?)?.toDouble() ?? 0,
        claimStatus: json['claim_status'] as String? ?? 'tersedia',
        listingName: json['listing_name'] as String? ?? '',
        listingPhoto: json['listing_photo'] as String?,
        listingDescription: json['listing_description'] as String?,
        quantityKg: (json['quantity_kg'] as num?)?.toDouble(),
        beneficiaryCount: (json['beneficiary_count'] as num?)?.toInt(),
        targetLocation: json['target_location'] as String? ??
          json['target_area'] as String?,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}

class ChatModel {
  final String id;
  final String orderId;
  final DateTime? createdAt;

  ChatModel({required this.id, required this.orderId, this.createdAt});

  factory ChatModel.fromJson(Map<String, dynamic> json) => ChatModel(
        id: json['id'] as String? ?? '',
        orderId: json['order_id'] as String? ?? '',
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}

class ChatMessageModel {
  final String id;
  final String senderId;
  final String text;
  final bool isRead;
  final DateTime? createdAt;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.isRead = false,
    this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] as String? ?? '',
        senderId: json['sender_id'] as String? ?? '',
        text: json['message_text'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? false,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}

class AiChatResult {
  final String conversationId;
  final String reply;
  final String? listing;

  AiChatResult({
    required this.conversationId,
    required this.reply,
    this.listing,
  });

  factory AiChatResult.fromJson(Map<String, dynamic> json) => AiChatResult(
        conversationId: json['conversation_id'] as String? ?? '',
        reply: json['reply'] as String? ?? '',
        listing: json['listing'] as String?,
      );
}

class EmergencyAlertModel {
  final String id;
  final String needType;
  final String targetArea;
  final String urgencyLevel;
  final String? description;
  final String status;
  final DateTime? createdAt;

  EmergencyAlertModel({
    required this.id,
    required this.needType,
    required this.targetArea,
    required this.urgencyLevel,
    this.description,
    required this.status,
    this.createdAt,
  });

  factory EmergencyAlertModel.fromJson(Map<String, dynamic> json) =>
      EmergencyAlertModel(
        id: json['id'] as String? ?? '',
        needType: json['need_type'] as String? ?? '',
        targetArea: json['target_area'] as String? ?? '',
        urgencyLevel: json['urgency_level'] as String? ?? 'sedang',
        description: json['description'] as String?,
        status: json['status'] as String? ?? 'aktif',
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}

class PaymentMethodModel {
  final String id;
  final String provider;
  final String accountReference;
  final bool isDefault;
  final DateTime? createdAt;

  const PaymentMethodModel({
    required this.id,
    required this.provider,
    required this.accountReference,
    required this.isDefault,
    this.createdAt,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) =>
      PaymentMethodModel(
        id: json['id'] as String? ?? '',
        provider: json['provider'] as String? ?? '',
        accountReference: json['account_reference'] as String? ?? '',
        isDefault: json['is_default'] as bool? ?? false,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'provider': provider,
        'account_reference': accountReference,
        'is_default': isDefault,
        'created_at': createdAt?.toIso8601String(),
      };
}