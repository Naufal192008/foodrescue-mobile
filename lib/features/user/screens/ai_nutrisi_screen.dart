import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../controllers/listing_controller.dart';

/// NutriRescue AI — tanya resep/nutrisi untuk listing surplus terpilih.
class AiNutrisiScreen extends ConsumerStatefulWidget {
  const AiNutrisiScreen({super.key});

  @override
  ConsumerState<AiNutrisiScreen> createState() => _AiNutrisiScreenState();
}

class _AiNutrisiScreenState extends ConsumerState<AiNutrisiScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<FoodListingModel> _listings = [];
  bool _loading = true;
  String? _error;
  FoodListingModel? _selected;
  String? _convId;
  final List<({String role, String text})> _messages = [];
  bool _sending = false;

  static const _quickPrompts = [
    'Ide resep olah ulang?',
    'Cara menyimpan yang aman?',
    'Berapa estimasi kalorinya?',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(listingRepositoryProvider)
          .getListings(page: 1, limit: 20);
      if (!mounted) return;
      setState(() {
        _listings = result.data;
        _loading = false;
        if (_selected == null && _listings.isNotEmpty) {
          _selected = _listings.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _select(FoodListingModel l) {
    if (l.id == _selected?.id) return;
    setState(() {
      _selected = l;
      _convId = null;
      _messages.clear();
    });
  }

  Future<void> _send([String? preset]) async {
    final text = preset ?? _input.text.trim();
    if (text.isEmpty || _sending) return;
    if (_selected == null) {
      _nag('Pilih makanan surplus dulu ya.');
      return;
    }
    if (preset == null) _input.clear();
    setState(() {
      _messages.add((role: 'user', text: text));
      _sending = true;
    });
    _scrollToBottom();
    try {
      final repo = ref.read(listingRepositoryProvider);
      String reply;
      if (_convId == null) {
        final res = await repo.aiChat(
          listingId: _selected!.id,
          message: text,
        );
        _convId = res.conversationId;
        reply = res.reply;
      } else {
        reply = await repo.aiContinue(
          conversationId: _convId!,
          message: text,
        );
      }
      if (!mounted) return;
      setState(() {
        _messages.add((role: 'ai', text: reply));
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _nag(e.toString());
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _nag(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NuTriRescue AI'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_error != null && _listings.isEmpty)
              Expanded(
                child: AppErrorView(message: _error!, onRetry: _load),
              )
            else ...[
              if (_listings.isNotEmpty) _picker(),
              Expanded(child: _chat()),
              _inputBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _picker() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ITEM DALAM ANALISIS',
            style: AppTheme.labelCaps(color: AppColors.outline),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _listings.map((l) {
                final active = l.id == _selected?.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: active
                        ? AppColors.primary
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                      onTap: () => _select(l),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Text(
                          l.name,
                          style: AppTheme.labelMd(
                            color: active
                                ? AppColors.onPrimary
                                : AppColors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chat() {
    final l = _selected;
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      children: [
        if (l != null) _analisisCard(l),
        const SizedBox(height: 14),
        if (_messages.isEmpty) ...[
          const AppEmptyState(
            icon: Icons.smart_toy_outlined,
            message: 'Mulai tanya resep olah ulang atau nutrisi makanan surplus ini.',
          ),
          const SizedBox(height: 12),
        ],
        ..._messages.map(_bubble),
        const SizedBox(height: 8),
        if (_messages.isEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickPrompts
                .map((p) => _promptChip(p))
                .toList(),
          ),
        const SizedBox(height: 8),
        Text(
          'Disclaimer: hasil AI adalah estimasi & informasi umum, bukan saran medis/gizi profesional.',
          style: AppTheme.bodySm(color: AppColors.outline),
        ),
      ],
    );
  }

  Widget _analisisCard(FoodListingModel l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.onPrimaryFixedVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyLg(
                    color: AppColors.primaryFixed,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
                child: Text(
                  'SEGAR',
                  style: AppTheme.labelCaps(color: AppColors.onPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${l.category} · ${l.stockQuantity} porsi · ${Fmt.money(l.currentPrice)}',
            style: AppTheme.bodySm(color: AppColors.primaryFixedDim),
          ),
          if (l.safeUntil != null)
            Text(
              'Aman konsumsi sebelum ${Fmt.time(Fmt.parse(l.safeUntil))} WIB',
              style: AppTheme.bodySm(color: AppColors.primaryFixedDim),
            ),
        ],
      ),
    );
  }

  Widget _promptChip(String p) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        onTap: () => _send(p),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(p, style: AppTheme.bodySm(color: AppColors.primary)),
        ),
      ),
    );
  }

  Widget _bubble(({String role, String text}) m) {
    final mine = m.role == 'user';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: mine
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: mine ? null : Border.all(color: AppColors.hairline),
        ),
        child: Text(m.text, style: AppTheme.bodyMd(color: AppColors.onSurface)),
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: 'Tanya resep atau nutrisi…',
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _sending ? null : _send,
              style: FilledButton.styleFrom(minimumSize: const Size(88, 48)),
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Kirim'),
            ),
          ),
        ],
      ),
    );
  }
}