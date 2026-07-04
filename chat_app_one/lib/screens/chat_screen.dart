import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_layout.dart';
import '../models/connection_status.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/brand_footer.dart';
import '../widgets/connection_banner.dart';
import '../widgets/empty_chat_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_composer.dart';
import '../widgets/typing_indicator.dart';
import 'join_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _composerController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _composerController.addListener(_onComposerUpdated);
  }

  void _onComposerUpdated() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _composerController.removeListener(_onComposerUpdated);
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _leave() async {
    await context.read<ChatProvider>().leaveRoom();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const JoinScreen()),
    );
  }

  void _showSettings(ChatProvider chat) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer<ThemeProvider>(
          builder: (context, theme, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Profile & Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(chat.username),
                    subtitle: Text('Room: #${chat.roomId}'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark theme'),
                    value: theme.isDarkMode,
                    activeColor: AppColors.primary,
                    onChanged: (_) => theme.toggleTheme(),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.pop(context);
                      _leave();
                    },
                    child: const Text('Leave room'),
                  ),
                  const BrandFooter(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildMessageItems(ChatProvider chat) {
    final items = <Widget>[];
    DateTime? lastDate;

    for (final message in chat.messages) {
      final local = message.timestamp.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (lastDate == null || day != lastDate) {
        lastDate = day;
        items.add(_DateSeparator(date: day));
      }

      items.add(
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 220),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - value)),
                child: child,
              ),
            );
          },
          child: MessageBubble(
            message: message,
            isMine: message.sender == chat.username && !message.isSystem,
          ),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (chat.messages.isNotEmpty) {
      _scrollToBottom();
    }

    if (chat.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || chat.errorMessage == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(chat.errorMessage!)),
        );
        chat.clearError();
      });
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${chat.roomId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: chat.connectionStatus.isOnline
                        ? AppColors.success
                        : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${chat.connectionStatus.label} · ${chat.onlineCount} online',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _showSettings(chat),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.contentMaxWidth(context),
          ),
          child: Column(
            children: [
              ConnectionBanner(status: chat.connectionStatus),
              Expanded(
                child: chat.messages.isEmpty
                    ? EmptyChatState(roomId: chat.roomId)
                    : ListView(
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                        children: _buildMessageItems(chat),
                      ),
              ),
              TypingIndicator(label: chat.typingLabel),
              MessageComposer(
                controller: _composerController,
                enabled: chat.connectionStatus.isOnline,
                onChanged: chat.onComposerChanged,
                onSend: () {
                  chat.sendMessage(_composerController.text);
                  _composerController.clear();
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat.MMMd().format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white54
                : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
