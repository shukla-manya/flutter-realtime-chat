import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/validators.dart';
import '../models/connection_status.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/brand_footer.dart';
import '../widgets/ms_mark.dart';
import 'chat_screen.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _roomController;
  late final ChatProvider _chat;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatProvider>();
    _nameController = TextEditingController(text: _chat.username);
    _roomController = TextEditingController(
      text: _chat.roomId.isEmpty ? AppConstants.defaultRoomId : _chat.roomId,
    );
    _chat.addListener(_syncFromProvider);
  }

  void _syncFromProvider() {
    if (!mounted) return;
    if (_nameController.text.isEmpty && _chat.username.isNotEmpty) {
      _nameController.text = _chat.username;
    }
    if ((_roomController.text.isEmpty ||
            _roomController.text == AppConstants.defaultRoomId) &&
        _chat.roomId.isNotEmpty) {
      _roomController.text = _chat.roomId;
    }
  }

  @override
  void dispose() {
    _chat.removeListener(_syncFromProvider);
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _onJoinPressed() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final chat = context.read<ChatProvider>();
    final ok = await chat.join(
      username: _nameController.text,
      roomId: _roomController.text,
    );

    if (!mounted) return;

    if (ok ||
        chat.connectionStatus == ConnectionStatus.connected ||
        chat.connectionStatus == ConnectionStatus.connecting ||
        chat.connectionStatus == ConnectionStatus.reconnecting) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
      return;
    }

    final message = chat.errorMessage ?? 'Could not connect';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    chat.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final chat = context.watch<ChatProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 360 ? AppSpacing.md : AppSpacing.lg;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    AppSpacing.lg,
                    horizontal,
                    AppSpacing.sm,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.maxContentWidth,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const MsMark(size: 40),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppConstants.appName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    Text(
                                      'by ${AppConstants.brandInitials}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                        color: isDark
                                            ? Colors.white60
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Toggle theme',
                                onPressed: themeProvider.toggleTheme,
                                icon: Icon(
                                  themeProvider.isDarkMode
                                      ? Icons.light_mode_outlined
                                      : Icons.dark_mode_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLg,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.22,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.wifi_tethering_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Join a room',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Start chatting in real time.',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusXl,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.25 : 0.06,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  enabled: !chat.isJoining,
                                  textInputAction: TextInputAction.next,
                                  validator: Validators.username,
                                  decoration: const InputDecoration(
                                    labelText: 'Display name',
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  controller: _roomController,
                                  enabled: !chat.isJoining,
                                  textInputAction: TextInputAction.done,
                                  validator: Validators.roomId,
                                  onFieldSubmitted: (_) {
                                    if (!chat.isJoining) _onJoinPressed();
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Room ID',
                                    prefixIcon: Icon(
                                      Icons.meeting_room_outlined,
                                    ),
                                    helperText: 'Default room: general',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                FilledButton(
                                  onPressed:
                                      chat.isJoining ? null : _onJoinPressed,
                                  child: chat.isJoining
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Join Conversation',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const BrandFooter(),
          ],
        ),
      ),
    );
  }
}
