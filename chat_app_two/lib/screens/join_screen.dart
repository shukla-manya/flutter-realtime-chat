import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/validators.dart';
import '../models/connection_status.dart';
import '../providers/chat_provider.dart';
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
                          const Row(
                            children: [
                              MsMark(size: 40, showGlow: true),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppConstants.appName,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'by ${AppConstants.brandInitials}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
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
                                  color: AppColors.purple.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Join a room',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Start chatting in real time.',
                                        style: TextStyle(
                                          color: Colors.white70,
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
                              color: AppColors.elevated,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusXl,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
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
                                    prefixIcon: Icon(Icons.hub_outlined),
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
