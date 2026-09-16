import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/listing_controller.dart';

/// Thread chat pengantaran untuk satu order (user ↔ kurir / mitra toko).
class ChatScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const ChatScreen({super.key, required this.order});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String? _chatId;
  List<ChatMessageModel> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  String _myId = '';

  @override
  void initState() {
    super.initState();
    _myId = ref.read(authControllerProvider).user?.id ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(listingRepositoryProvider);
      final chatId = await repo.ensureChatForOrder(widget.order.id);
      final messages = await repo.getMessages(chatId);
      if (!mounted) return;
      setState(() {
        _chatId = chatId;
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom(animate: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending || _chatId == null) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(listingRepositoryProvider)
          .sendMessage(_chatId!, text);
      _input.clear();
      final list = await ref
          .read(listingRepositoryProvider)
          .getMessages(_chatId!);
      if (!mounted) return;
      setState(() {
        _messages = list;
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat Pengantaran', style: AppTheme.headlineSm().copyWith(fontSize: 16)),
            Text(
              '#${(widget.order.id.length >= 5 ? widget.order.id.substring(0, 5) : widget.order.id).toUpperCase()} · ${widget.order.listing?.name ?? 'pesanan'}',
              style: AppTheme.bodySm(color: AppColors.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _notice(),
          Expanded(child: _buildBody()),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _notice() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Pesan penyaluran & koordinasi serah terima. Relawan moderasi aktif di jam operasional 08.00–20.00.',
        style: AppTheme.bodySm(color: AppColors.onPrimaryFixedVariant),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return AppErrorView(
        message: '$_error\nKirim tetap tersedia setelah chat terbentuk.',
        onRetry: _init,
      );
    }
    if (_messages.isEmpty) {
      return const AppEmptyState(
        icon: Icons.forum_outlined,
        message: 'Belum ada pesan.\nMulai koordinasi serah terima pesananmu.',
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _bubble(_messages[i]),
    );
  }

  Widget _bubble(ChatMessageModel m) {
    final mine = m.senderId == _myId;
    final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color =
        mine ? AppColors.primaryContainer : AppColors.surfaceContainerLowest;
    final fg = mine ? AppColors.onPrimary : AppColors.onSurface;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A005321),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: align,
          children: [
            if (!mine) ...[
              Text(
                m.senderId.isEmpty ? 'Mitra' : 'Mitra',
                style: AppTheme.labelCaps(color: AppColors.primary),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              m.text,
              style: AppTheme.bodyMd(color: fg),
            ),
            const SizedBox(height: 4),
            Text(
              m.createdAt != null ? Fmt.time(m.createdAt!) : '',
              style: AppTheme.labelCaps(
                color: mine ? Colors.white70 : AppColors.outline,
              ).copyWith(fontSize: 9),
            ),
          ],
        ),
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
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Tulis pesan…',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _sending ? null : _send,
              style: FilledButton.styleFrom(
                minimumSize: const Size(88, 48),
              ),
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