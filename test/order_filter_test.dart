import 'package:flutter_test/flutter_test.dart';
import 'package:food_rescue_mobile/core/models/models.dart';
import 'package:food_rescue_mobile/features/user/screens/pesanan_screen.dart';

void main() {
  final orders = [
    OrderModel(
      id: '1',
      listingId: 'l1',
      userId: 'u1',
      quantity: 1,
      priceAtPurchase: 15000,
      totalAmount: 15000,
      fulfillmentMethod: 'diantar_kurir',
      paymentMethod: 'qris',
      paymentStatus: 'paid',
      orderStatus: 'pending',
      confirmationCode: 'ABC123',
      raw: {},
    ),
    OrderModel(
      id: '2',
      listingId: 'l2',
      userId: 'u1',
      quantity: 2,
      priceAtPurchase: 22000,
      totalAmount: 22000,
      fulfillmentMethod: 'pickup_mandiri',
      paymentMethod: 'qris',
      paymentStatus: 'unpaid',
      orderStatus: 'pending',
      confirmationCode: '',
      raw: {},
    ),
    OrderModel(
      id: '3',
      listingId: 'l3',
      userId: 'u1',
      quantity: 3,
      priceAtPurchase: 30000,
      totalAmount: 30000,
      fulfillmentMethod: 'diantar_kurir',
      paymentMethod: 'qris',
      paymentStatus: 'paid',
      orderStatus: 'selesai',
      confirmationCode: 'XYZ999',
      raw: {},
    ),
  ];

  test('filter pesanan memisahkan status unpaid dan selesai', () {
    expect(applyOrderFilter(orders, OrderFilter.all).length, 3);
    expect(applyOrderFilter(orders, OrderFilter.unpaid).length, 1);
    expect(applyOrderFilter(orders, OrderFilter.completed).length, 1);
    expect(applyOrderFilter(orders, OrderFilter.active).length, 1);
  });

  test('filter waktu membaca created_at dari respons API', () {
    final datedOrders = [
      OrderModel.fromJson({
        'id': 'today',
        'created_at': '2026-09-16T09:00:00Z',
      }),
      OrderModel.fromJson({
        'id': 'last-week',
        'created_at': '2026-09-10T09:00:00Z',
      }),
      OrderModel.fromJson({
        'id': 'last-month',
        'created_at': '2026-08-31T09:00:00Z',
      }),
    ];
    final now = DateTime.parse('2026-09-16T12:00:00Z');

    expect(applyOrderTimeFilter(datedOrders, OrderTimeFilter.today, now: now)
        .map((order) => order.id), ['today']);
    expect(applyOrderTimeFilter(datedOrders, OrderTimeFilter.week, now: now)
        .map((order) => order.id), ['today', 'last-week']);
    expect(applyOrderTimeFilter(datedOrders, OrderTimeFilter.month, now: now)
        .map((order) => order.id), ['today', 'last-week']);
  });
}
