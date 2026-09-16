import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/controllers/auth_controller.dart';

class TokoLayout extends ConsumerStatefulWidget {
  const TokoLayout({super.key});

  @override
  ConsumerState<TokoLayout> createState() => _TokoLayoutState();
}

class _TokoLayoutState extends ConsumerState<TokoLayout> {
  int _index = 0;

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.dashboard_rounded, label: 'Analisis'),
    _NavItem(icon: Icons.add_box_rounded, label: 'Tambah'),
    _NavItem(icon: Icons.recycling_rounded, label: 'Limbah'),
    _NavItem(icon: Icons.groups_rounded, label: 'Komunitas'),
    _NavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  static const _tabs = <Widget>[
    _DashboardTokoScreen(),
    _TambahTokoScreen(),
    _LimbahTokoScreen(),
    _KomunitasTokoScreen(),
    _ProfilTokoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 72,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == _index;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _index = i),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: selected ? const Color(0xFF008C3A) : const Color(0xFF17231A),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: AppTheme.labelCaps(
                            color: selected ? const Color(0xFF008C3A) : const Color(0xFF17231A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DashboardTokoScreen extends StatelessWidget {
  const _DashboardTokoScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
        children: [
          const _MitraHeader(title: 'Profil Dan Rating'),
          const SizedBox(height: 14),
          _StatusGeraiCard(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MetricTile(label: 'PESANAN MASUK', value: '16 Pesanan', badge: '+4 Verifikasi')),
              const SizedBox(width: 10),
              Expanded(child: _MetricTile(label: 'LISTING AKTIF', value: '8 Porsi', badge: '3 Batas Waktu')),
            ],
          ),
          const SizedBox(height: 10),
          _RevenueCard(),
          const SizedBox(height: 14),
          _UrgencyCard(),
          const SizedBox(height: 16),
          Text('Pesanan Masuk  2', style: AppTheme.headlineMd().copyWith(fontSize: 22)),
          const SizedBox(height: 10),
          _OrderSummaryCard(order: '#FR-9021', name: 'Siti Rahmawati', item: '2x Salmon Teriyaki Bento', amount: 'Rp 116.000', status: 'Siap di Kasir'),
          const SizedBox(height: 10),
          _OrderSummaryCard(order: '#FR-9024', name: 'Budi Santoso', item: '1x Spicy Salmon Roll', amount: 'Rp 45.000', status: 'Tiba dlm 5 mnt'),
          const SizedBox(height: 16),
          Text('Notifikasi & Peringatan Terkini', style: AppTheme.headlineMd().copyWith(fontSize: 21)),
          const SizedBox(height: 10),
          _NotificationPanel(),
        ],
      ),
    );
  }
}

class _MitraHeader extends StatelessWidget {
  final String title;
  const _MitraHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Image.asset('assets/icons/Foodrescue.png', width: 32, height: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  Text(title, style: AppTheme.headlineSm().copyWith(fontSize: 19)),
                  const SizedBox(width: 6),
                  _Tag('MITRA', const Color(0xFFFFE1D8), const Color(0xFFE84B24)),
                ]),
                Text('Sushi Sei • Plaza Senayan ⌄', style: AppTheme.bodySm(color: const Color(0xFF58635B))),
              ],
            ),
          ),
          const Icon(Icons.notifications_none_rounded, size: 28, color: Color(0xFF17231A)),
          const SizedBox(width: 12),
          const CircleAvatar(radius: 17, backgroundColor: Color(0xFFD9E7DC), child: Icon(Icons.person, color: Color(0xFF008C3A))),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  const _Tag(this.text, this.background, this.foreground);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(4)),
        child: Text(text, style: TextStyle(color: foreground, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .5)),
      );
}

class _StatusGeraiCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF008C3A), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('STATUS GERAI', style: AppTheme.labelCaps(color: const Color(0xFF17231A))),
            Text('BUKA PENERIMAAN', style: AppTheme.labelMd(color: const Color(0xFF008C3A))),
          ])),
          Switch(value: true, onChanged: (_) {}, activeThumbColor: const Color(0xFF008C3A)),
        ]),
      );
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String badge;
  const _MetricTile({required this.label, required this.value, required this.badge});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTheme.labelCaps(color: const Color(0xFF58635B))),
          const SizedBox(height: 12),
          Text(value, style: AppTheme.headlineMd().copyWith(fontSize: 24)),
          const SizedBox(height: 7),
          _Tag(badge, const Color(0xFFFFE4D9), const Color(0xFFDE542E)),
        ]),
      );
}

class _RevenueCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TOTAL PENDAPATAN\nTERVERIFIKASI', style: AppTheme.labelCaps(color: const Color(0xFF58635B))),
            const SizedBox(height: 8),
            Text('Rp 842.000', style: AppTheme.headlineMd().copyWith(fontSize: 25)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _Tag('+24.8% vs kemarin', const Color(0xFFB9F4C5), const Color(0xFF087832)),
            const SizedBox(height: 12),
            Text('Target 92%', style: AppTheme.bodySm(color: const Color(0xFF58635B))),
          ]),
        ]),
      );
}

class _UrgencyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFFF5A1F), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Tag('⏱  URGENSI PENYELAMATAN', const Color(0x33FFFFFF), Colors.white),
            const Spacer(),
            Text('00:44:18', style: AppTheme.headlineMd().copyWith(color: Colors.white, fontSize: 22)),
          ]),
          const SizedBox(height: 10),
          Text('Menjelang Jam Tutup (Sisa 44 Menit)', style: AppTheme.headlineMd().copyWith(color: Colors.white, fontSize: 21)),
          const SizedBox(height: 7),
          Text('4 porsi Salmon & Bento butuh penyesuaian harga dinamis atau dorong ke donasi sebelum batas konsumsi malam.', style: AppTheme.bodySm(color: Colors.white)),
          const SizedBox(height: 14),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: const LinearProgressIndicator(value: .72, minHeight: 7, backgroundColor: Color(0x55FFFFFF), valueColor: AlwaysStoppedAnimation(Colors.white))),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Text('#Batch: Evening Rush\n#PlazaSenayan', style: AppTheme.labelCaps(color: Colors.white))),
            SizedBox(
              width: 146,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFFF5A1F),
                ),
                child: const Text('Kelola Listing  →'),
              ),
            ),
          ]),
        ]),
      );
}

class _OrderSummaryCard extends StatelessWidget {
  final String order;
  final String name;
  final String item;
  final String amount;
  final String status;
  const _OrderSummaryCard({required this.order, required this.name, required this.item, required this.amount, required this.status});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text(order, style: AppTheme.labelMd(color: const Color(0xFF008C3A))), const SizedBox(width: 8), Expanded(child: Text('•  $name', style: AppTheme.bodySm())), _Tag(status, const Color(0xFFB9F4C5), const Color(0xFF087832))]),
          const SizedBox(height: 10),
          Text(item, style: AppTheme.bodyMd().copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Row(children: [Text(amount, style: AppTheme.bodySm(color: const Color(0xFF58635B))), const SizedBox(width: 8), Text('•  LUNAS QRIS', style: AppTheme.labelCaps(color: const Color(0xFF008C3A)))]),
        ]),
      );
}

class _NotificationPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(children: const [
          _NotificationRow(icon: Icons.notifications_active_outlined, text: 'Pesanan Baru Masuk #FR-9025 dari Dimas A. (Chuka Wakame Salad)', time: '3 menit lalu'),
          _NotificationRow(icon: Icons.sell_outlined, text: 'Dynamic Price Aktif: Spicy Salmon Roll otomatis turun 25%', time: '15 menit lalu'),
          _NotificationRow(icon: Icons.volunteer_activism_outlined, text: 'Dapur Sosial Jaksel mengonfirmasi jadwal jemput 18 Box Roti', time: '32 menit lalu'),
        ]),
      );
}

class _NotificationRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String time;
  const _NotificationRow({required this.icon, required this.text, required this.time});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: const Color(0xFF008C3A), size: 22),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(text, style: AppTheme.bodySm()), const SizedBox(height: 3), Text(time, style: AppTheme.labelCaps(color: const Color(0xFF79847B)))])),
        ]),
      );
}

class _TambahTokoScreen extends StatefulWidget {
  const _TambahTokoScreen();

  @override
  State<_TambahTokoScreen> createState() => _TambahTokoScreenState();
}

class _TambahTokoScreenState extends State<_TambahTokoScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  TimeOfDay _pickupStart = const TimeOfDay(hour: 19, minute: 30);
  TimeOfDay _pickupEnd = const TimeOfDay(hour: 21, minute: 30);

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool start) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start ? _pickupStart : _pickupEnd,
    );
    if (value == null || !mounted) return;
    setState(() {
      if (start) {
        _pickupStart = value;
      } else {
        _pickupEnd = value;
      }
    });
  }

  void _publish() {
    if (_nameController.text.trim().isEmpty ||
        int.tryParse(_quantityController.text) == null ||
        double.tryParse(_priceController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi nama, stok, dan harga terlebih dahulu.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_nameController.text.trim()} siap diterbitkan sebagai flash rescue.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
        children: [
          const _MitraHeader(title: 'Tambah Makanan'),
          const SizedBox(height: 10),
          Text('BATCH RESCUE BARU', style: AppTheme.labelCaps(color: const Color(0xFF008C3A))),
          Text('Katalog Porsi\nSurplus', style: AppTheme.headlineMd().copyWith(fontSize: 23)),
          const SizedBox(height: 16),
          _ScanCard(),
          const SizedBox(height: 12),
          PanelCard(title: 'DOKUMENTASI VISUAL PORSI', child: Row(children: [
            Container(width: 94, height: 88, color: const Color(0xFFE4E9E4), child: const Icon(Icons.photo_camera_outlined, color: Color(0xFF008C3A))),
            const SizedBox(width: 12),
            Expanded(child: Text('Foto porsi siap kemas\n\nTampilkan kebersihan tray, mica/kraft dan stempel jam untuk kepercayaan kurir & pembeli.', style: AppTheme.bodySm())),
          ])),
          const SizedBox(height: 12),
          PanelCard(title: 'NAMA MAKANAN / PRODUK SURPLUS', child: _field('', _nameController, 'Salmon Teriyaki Bento & Miso')),
          const SizedBox(height: 12),
          PanelCard(title: 'KATEGORI PRODUK', child: Wrap(spacing: 8, runSpacing: 8, children: [
            _Tag('Bento & Rice Box', const Color(0xFF008C3A), Colors.white),
            _Tag('Bakery & Pastry', const Color(0xFFE7ECE8), const Color(0xFF17231A)),
            _Tag('Fresh Produce', const Color(0xFFE7ECE8), const Color(0xFF17231A)),
            _Tag('Minuman', const Color(0xFFE7ECE8), const Color(0xFF17231A)),
          ])),
          const SizedBox(height: 12),
          _PricingCard(controller: _priceController),
          const SizedBox(height: 12),
          _field('Stok siap diambil', _quantityController, '3', keyboard: TextInputType.number),
          const SizedBox(height: 12),
          PanelCard(title: 'JAM PENGAMBILAN (PICKUP WINDOW)', child: Row(children: [
            Expanded(child: _timeButton('Mulai', _pickupStart, () => _pickTime(true))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
            Expanded(child: _timeButton('Selesai', _pickupEnd, () => _pickTime(false))),
          ])),
          const SizedBox(height: 12),
          PanelCard(title: 'KEAMANAN PANGAN & STANDAR KONSUMSI', child: Row(children: [
            Expanded(child: _InfoBox(label: 'SUHU SIMPAN', value: 'Chiller\n4°C')),
            const SizedBox(width: 6),
            Expanded(child: _InfoBox(label: 'STANDAR MUTU', value: 'HACCP\nGr. A')),
            const SizedBox(width: 6),
            Expanded(child: _InfoBox(label: 'KONSUMSI MAX', value: '23:00\nWIB')),
          ])),
          const SizedBox(height: 14),
          PanelCard(
            title: '',
            child: FilledButton.icon(
            onPressed: _publish,
            icon: const Icon(Icons.flash_on_rounded),
            label: const Text('Terbitkan Flash Rescue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, String hint, {TextInputType? keyboard}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _timeButton(String label, TimeOfDay time, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      child: Column(children: [Text(label), Text(time.format(context))]),
    );
  }
}

class _ScanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFE9F0EA), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF007D32), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.document_scanner_outlined, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Text('Pindai Struk /\nBarcode', style: AppTheme.headlineSm().copyWith(fontSize: 19))),
            _Tag('99% AKURAT', const Color(0xFFD2E9D7), const Color(0xFF087832)),
          ]),
          const SizedBox(height: 8),
          Text('Scan cepat label dapur POS atau kemasan bento untuk ekstraksi nama, batch gramatur, & jam masak instan.', style: AppTheme.bodySm(color: const Color(0xFF58635B))),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.camera_alt_outlined), label: const Text('Scan OCR Auto-fill Otomatis  →')),
        ]),
      );
}

class _PricingCard extends StatelessWidget {
  final TextEditingController controller;
  const _PricingCard({required this.controller});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Skema Kurva Harga Dinamis', style: AppTheme.headlineSm().copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _InfoBox(label: 'HARGA NORMAL', value: '465k')),
            const SizedBox(width: 6),
            Expanded(child: _InfoBox(label: 'AWAL SURPLUS', value: '110k')),
            const SizedBox(width: 6),
            Expanded(child: _InfoBox(label: 'FLOOR MINIMAL', value: '35k')),
          ]),
          const SizedBox(height: 12),
          TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga flash rescue (Rp)', hintText: '35000')),
        ]),
      );
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFE9F0EA), borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTheme.labelCaps(color: const Color(0xFF58635B))),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.bodyMd().copyWith(fontWeight: FontWeight.w700)),
        ]),
      );
}

class _WasteActionCard extends StatelessWidget {
  final String title;
  final String detail;
  final String action;
  final IconData icon;
  const _WasteActionCard({required this.title, required this.detail, required this.action, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFE7ECE8), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF008C3A))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTheme.bodyMd().copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(detail, style: AppTheme.bodySm(color: const Color(0xFF58635B)))])),
          ]),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () {}, icon: Icon(icon, size: 17), label: Text(action), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(42))),
        ]),
      );
}

class _KomunitasTokoScreen extends StatefulWidget {
  const _KomunitasTokoScreen();

  @override
  State<_KomunitasTokoScreen> createState() => _KomunitasTokoScreenState();
}

class _KomunitasTokoScreenState extends State<_KomunitasTokoScreen> {
  final _posts = <String>['18 Box Roti & Pastry', '10 Porsi Nasi Bento', '25 kg Sayuran & Kulit Buah'];

  void _markDistributed(String post) {
    setState(() => _posts.remove(post));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$post dipindahkan ke riwayat penyaluran.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
        children: [
          const _MitraHeader(title: 'Komunitas'),
          const SizedBox(height: 6),
          Text('PENYALURAN KOMUNITAS TOKO', style: AppTheme.labelCaps(color: const Color(0xFF008C3A))),
          Text('420 Porsi', style: AppTheme.headlineMd().copyWith(fontSize: 42, color: const Color(0xFF007D32))),
          Text('Didonasikan langsung ke Dapur Sosial mitra & pusat pengolahan kompos urban.', style: AppTheme.bodySm(color: const Color(0xFF58635B))),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: _MetricTile(label: 'CO₂ DICEGAH', value: '862 kg', badge: '')),
            const SizedBox(width: 8), Expanded(child: _MetricTile(label: 'MITRA DAPUR', value: '7 Lembaga', badge: '')),
            const SizedBox(width: 8), Expanded(child: _MetricTile(label: 'LAJU ALIH', value: '94.8%', badge: ''))]),
          const SizedBox(height: 14),
          if (_posts.isEmpty)
            const AppEmptyState(icon: Icons.check_circle_outline, message: 'Semua penyaluran sudah selesai diproses.')
          else
            ..._posts.map((post) => PanelCard(
              title: post,
              child: Row(
                children: [
                  const Expanded(child: Text('Menunggu pickup relawan / mitra komunitas')),
                  IconButton(onPressed: () => _markDistributed(post), icon: const Icon(Icons.check_circle, color: AppColors.primary)),
                ],
              ),
            )),
        ],
      ),
    );
  }
}

class _LimbahTokoScreen extends StatelessWidget {
  const _LimbahTokoScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
        children: [
          const _MitraHeader(title: 'Olah Limbah'),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFE9F0EA), borderRadius: BorderRadius.circular(16)), child: Row(children: [
            const Icon(Icons.timer_outlined, color: Color(0xFFFF5A1F), size: 34),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('PROTOKOL NOL TPA', style: AppTheme.labelCaps(color: const Color(0xFFDE542E))), Text('3 Item Membutuhkan Tindakan', style: AppTheme.headlineSm().copyWith(fontSize: 20))])),
            Text('44:54', style: AppTheme.headlineMd().copyWith(color: const Color(0xFFFF5A1F), fontSize: 22)),
          ])),
          const SizedBox(height: 18),
          Text('Surplus Melebihi Jam\nPajang', style: AppTheme.headlineMd().copyWith(fontSize: 21)),
          const SizedBox(height: 10),
          _WasteActionCard(title: 'Salmon Sashimi Trimmings', detail: 'Suhu inti: 3.4°C • Grade A Sah', action: 'DORONG KE KOMUNITAS / NGO', icon: Icons.volunteer_activism_outlined),
          const SizedBox(height: 10),
          _WasteActionCard(title: 'Nasi Sushi & Tamaquaki', detail: '4 Porsi • Matang Siang 14:00', action: 'KIRIM KE MITRA KOMPOS AGRO', icon: Icons.local_shipping_outlined),
          const SizedBox(height: 10),
          _WasteActionCard(title: 'Edamame Rebus Batch Sore', detail: 'Batch #EDS-170 • Siap Daur', action: 'ALIHKAN KE PAKAN TERNAK', icon: Icons.pedal_bike_outlined),
          const SizedBox(height: 16),
          Text('Audit & Jejak Daur Ulang', style: AppTheme.headlineMd().copyWith(fontSize: 21)),
          const SizedBox(height: 10),
          MetricCard(title: 'TOTAL TEREDUKSI MINGGU INI', value: '14.2 kg', trend: '100% dialihkan ke Kompos & Peternakan Maggot', accent: const Color(0xFF008C3A)),
          const SizedBox(height: 10),
          PanelCard(
            title: 'Riwayat Serah Terima Terakhir',
            child: Column(
              children: const [
                _ListRow(label: 'Sushi Rice Trim', value: 'Selesai'),
                _ListRow(label: 'Unagi Bento Surplus', value: 'Terdistribusi'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilTokoScreen extends ConsumerWidget {
  const _ProfilTokoScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
        children: [
          const _MitraHeader(title: 'Profil Dan Rating'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName.isNotEmpty == true ? user!.fullName : 'Mitra FoodRescue', style: AppTheme.bodyMd().copyWith(fontWeight: FontWeight.w700)),
                      Text(user?.email ?? 'Mitra aktif', style: AppTheme.bodySm(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PanelCard(
            title: 'Informasi',
            child: Column(
              children: const [
                _ListRow(label: 'Kontak', value: '081234567890'),
                _ListRow(label: 'Lokasi', value: 'Plaza Senayan'),
                _ListRow(label: 'Status', value: 'Terverifikasi'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Keluar dari akun'),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final Color accent;

  const MetricCard({super.key, 
    required this.title,
    required this.value,
    required this.trend,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.labelMd(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.metricSm(color: accent)),
          const SizedBox(height: 6),
          Text(trend, style: AppTheme.bodySm(color: AppColors.primary)),
        ],
      ),
    );
  }
}

class MiniStat extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const MiniStat(this.title, this.value, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.labelMd(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.metricSm(color: color)),
        ],
      ),
    );
  }
}

class PanelCard extends StatelessWidget {
  final String title;
  final Widget child;

  const PanelCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headlineSm().copyWith(fontSize: 17)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  final String label;
  final String value;

  const _ListRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTheme.bodyMd(color: AppColors.onSurfaceVariant))),
          Text(value, style: AppTheme.bodyMd().copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}