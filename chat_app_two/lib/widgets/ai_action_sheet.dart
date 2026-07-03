import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/ai_response.dart';
import '../providers/chat_provider.dart';
import 'smart_reply_chips.dart';

Future<String?> showAiActionSheet({
  required BuildContext context,
  required ChatProvider chat,
  required String draftText,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.elevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return _AiActionSheetBody(chat: chat, draftText: draftText);
    },
  );
}

class _AiActionSheetBody extends StatefulWidget {
  const _AiActionSheetBody({
    required this.chat,
    required this.draftText,
  });

  final ChatProvider chat;
  final String draftText;

  @override
  State<_AiActionSheetBody> createState() => _AiActionSheetBodyState();
}

class _AiActionSheetBodyState extends State<_AiActionSheetBody> {
  String? _localResult;
  List<String> _suggestions = const [];
  String? _error;
  bool _loading = false;
  AiAction? _active;
  AiAction? _lastAttempted;
  AiAction? _completedAction;

  Future<void> _run(AiAction action) async {
    setState(() {
      _loading = true;
      _active = action;
      _lastAttempted = action;
      _completedAction = null;
      _error = null;
      _localResult = null;
      _suggestions = const [];
    });

    final response = await widget.chat.requestAiAction(
      action: action,
      content: widget.draftText,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      _active = null;
      _error = widget.chat.aiError;
      if (response != null) {
        _completedAction = action;
        if (action == AiAction.smartReply) {
          _suggestions = response.suggestions;
        } else {
          _localResult = response.content;
        }
      }
    });
  }

  bool get _isRewrite =>
      _completedAction == AiAction.rewriteProfessional ||
      _completedAction == AiAction.rewriteFriendly ||
      _completedAction == AiAction.makeConcise;

  @override
  Widget build(BuildContext context) {
    const actions = [
      AiAction.smartReply,
      AiAction.rewriteProfessional,
      AiAction.rewriteFriendly,
      AiAction.makeConcise,
      AiAction.summarize,
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI tools',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Smart replies, rewrite, and summaries',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...actions.map((action) {
                final isActive = _loading && _active == action;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _loading ? null : () => _run(action),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _iconFor(action),
                              color: AppColors.neonCyan,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                action.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isActive)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.electricPurple,
                                ),
                              )
                            else
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textSecondary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.electricPurple,
                    backgroundColor: AppColors.surface,
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      TextButton(
                        onPressed: _loading || _lastAttempted == null
                            ? null
                            : () => _run(_lastAttempted!),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Try a smart reply',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SmartReplyChips(
                  suggestions: _suggestions,
                  onSelected: (value) => Navigator.pop(context, value),
                ),
              ],
              if (_localResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.electricPurple.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _completedAction == AiAction.summarize
                            ? 'Summarize this chat'
                            : 'Result',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.electricPurple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_localResult!),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                              _isRewrite ? _localResult : null,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.electricPurple,
                          ),
                          child: Text(_isRewrite ? 'Use text' : 'Done'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(AiAction action) {
    switch (action) {
      case AiAction.smartReply:
        return Icons.quickreply_outlined;
      case AiAction.rewriteProfessional:
        return Icons.business_center_outlined;
      case AiAction.rewriteFriendly:
        return Icons.sentiment_satisfied_alt_outlined;
      case AiAction.makeConcise:
        return Icons.compress_rounded;
      case AiAction.summarize:
        return Icons.summarize_outlined;
      case AiAction.ask:
        return Icons.psychology_alt_outlined;
    }
  }
}
