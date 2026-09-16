import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../data/listing_repository.dart';
import 'listing_controller.dart';

final orderStateProvider = StateNotifierProvider<OrderController, OrderState>(
  (ref) => OrderController(ref.watch(listingRepositoryProvider)),
);

class OrderState {
  final bool isCreating;
  final String? error;
  final OrderModel? createdOrder;
  final bool isPaying;

  OrderState({
    this.isCreating = false,
    this.error,
    this.createdOrder,
    this.isPaying = false,
  });

  OrderState copyWith({
    bool? isCreating,
    String? error,
    OrderModel? createdOrder,
    bool? isPaying,
    bool clearError = false,
  }) {
    return OrderState(
      isCreating: isCreating ?? this.isCreating,
      error: clearError ? null : (error ?? this.error),
      createdOrder: createdOrder ?? this.createdOrder,
      isPaying: isPaying ?? this.isPaying,
    );
  }
}

class OrderController extends StateNotifier<OrderState> {
  final ListingRepository _repo;

  OrderController(this._repo) : super(OrderState());

  /// Membuat order baru. Mengembalikan `true` bila sukses.
  Future<bool> createOrder({
    required FoodListingModel listing,
    required int quantity,
    required String fulfillmentMethod,
  }) async {
    state = state.copyWith(isCreating: true, clearError: true);
    try {
      final res = await _repo.createOrder(
        listingId: listing.id,
        quantity: quantity,
        fulfillmentMethod: fulfillmentMethod,
      );
      final order = OrderModel.fromJson({
        'id': res['order_id'] ?? '',
        'listing_id': listing.id,
        'user_id': '',
        'quantity': quantity,
        'price_at_purchase': listing.currentPrice,
        'total_amount': res['total_amount'] ?? listing.currentPrice * quantity,
        'fulfillment_method': fulfillmentMethod,
        'payment_method': '',
        'payment_status': 'unpaid',
        'order_status': 'menunggu_pickup',
        'confirmation_code': res['confirmation_code'] ?? '',
        'listing': listing,
      });
      state = state.copyWith(
        isCreating: false,
        createdOrder: order,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isCreating: false, error: e.toString());
      return false;
    }
  }

  /// Konfirmasi pembayaran manual. Mengembalikan `true` bila sukses.
  Future<bool> pay(String orderId, {String paymentMethod = 'qris'}) async {
    state = state.copyWith(isPaying: true, clearError: true);
    try {
      await _repo.confirmPayment(
        orderId: orderId,
        paymentMethod: paymentMethod,
      );
      final order = state.createdOrder;
      state = state.copyWith(
        isPaying: false,
        createdOrder: order?.copyWithRawPayment('paid'),
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isPaying: false, error: e.toString());
      return false;
    }
  }

  void setOrder(OrderModel order) {
    state = state.copyWith(createdOrder: order, clearError: true);
  }

  Future<List<OrderModel>> fetchMyOrders() => _repo.getMyOrders();

  /// Membuat Qris Charge (Midtrans). Mengembalikan map respons mentah.
  Future<Map<String, dynamic>> qrisCreate(String orderId) =>
      _repo.createQris(orderId: orderId);

  /// Menyegarkan status order (polling pembayaran).
  Future<void> refreshOrder(String orderId) async {
    final order = await _repo.refreshOrder(orderId);
    state = state.copyWith(createdOrder: order, clearError: true);
  }

  void clear() => state = OrderState();
}

extension _OrderHelpers on OrderModel {
  OrderModel copyWithRawPayment(String paymentStatus) {
    final raw2 = Map<String, dynamic>.from(raw)
      ..['payment_status'] = paymentStatus;
    return OrderModel(
      id: id,
      listingId: listingId,
      userId: userId,
      quantity: quantity,
      priceAtPurchase: priceAtPurchase,
      totalAmount: totalAmount,
      fulfillmentMethod: fulfillmentMethod,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      orderStatus: orderStatus,
      confirmationCode: confirmationCode,
      completedAt: completedAt,
      listing: listing,
      pickupAddress: pickupAddress,
      raw: raw2,
    );
  }
}