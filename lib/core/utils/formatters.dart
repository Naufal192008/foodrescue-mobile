import 'package:intl/intl.dart';

class Fmt {
  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _date = DateFormat('dd MMM yyyy');
  static final _time = DateFormat('HH:mm');
  static final _dateTime = DateFormat('dd MMM yyyy, HH:mm');

  static String money(num value) => _rupiah.format(value);

  static String date(DateTime dt) => _date.format(dt.toLocal());

  static String time(DateTime dt) => _time.format(dt.toLocal());

  static String dateTime(DateTime dt) => _dateTime.format(dt.toLocal());

  static DateTime parse(String? iso) {
    if (iso == null || iso.isEmpty) return DateTime.now();
    return DateTime.tryParse(iso) ?? DateTime.now();
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'inactive':
        return 'Tidak Aktif';
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'sold_out':
        return 'Habis';
      case 'expired':
        return 'Kedaluwarsa';
      case 'pushed_to_community':
        return 'Dialihkan ke Komunitas';
      case 'discarded':
        return 'Dibuang';
      case 'paid':
        return 'Lunas';
      case 'unpaid':
        return 'Belum Bayar';
      case 'confirmed':
        return 'Konfirmasi Kode';
      case 'picked_up':
        return 'Ambil Selesai';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'online':
        return 'Online';
      case 'offline':
        return 'Offline';
      case 'menuju_toko':
        return 'Menuju Toko';
      case 'barang_diambil':
        return 'Barang Diambil';
      case 'menuju_user':
        return 'Menuju Penerima';
      case 'diterima_user':
        return 'Diterima';
      default:
        return status;
    }
  }

  static String toTitleCase(String s) {
    if (s.isEmpty) return s;
    return s.split('_').map((w) {
      return w.isEmpty ? w : w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}