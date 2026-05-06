import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/services/ai_copilot_service.dart';
import '../../../../shared/widgets/voice_button.dart';

class LiveClinicalChatWidget extends ConsumerStatefulWidget {
  const LiveClinicalChatWidget({super.key});

  @override
  ConsumerState<LiveClinicalChatWidget> createState() => _LiveClinicalChatWidgetState();
}

class _LiveClinicalChatWidgetState extends ConsumerState<LiveClinicalChatWidget> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    HapticFeedback.lightImpact();

    ref.read(aiCopilotServiceProvider).sendMessage(text, () {
      if (mounted) setState(() {});
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final copilot = ref.watch(aiCopilotServiceProvider);
    final messages = copilot.messages;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A2236).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 40)],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            children: [
              // ─── Header ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5))),
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('المساعد السريري (Live Copilot)',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary)),
                          Text('يعتمد على بيانات المريض الحالية',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ─── Chat Messages ────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(messages[index], isDark),
                ),
              ),

              // ─── Input Area ───────────────────────────────────────────────
              Container(
                padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2236) : Colors.white,
                  border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.5))),
                ),
                child: Row(
                  children: [
                    VoiceButton(
                      contextId: 'live_chat',
                      size: 48,
                      onResult: _sendMessage,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'اسأل عن تفاعل أو بروتوكول علاجي...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF2A3A52)
                              : AppColors.surfaceVariant.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: () => _sendMessage(_textController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(CopilotMessage msg, bool isDark) {
    // ─── رسالة الطبيب (يسار RTL) ──────────────────────────────────────────
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, right: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Text(msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      );
    }

    // ─── رسالة المساعد – تلوين حسب الخطورة ───────────────────────────────
    Color bgColor = isDark ? const Color(0xFF2A3A52) : Colors.white;
    Color borderColor = AppColors.border;

    if (msg.text.contains('[🚨 CRITICAL]')) {
      bgColor = AppColors.error.withValues(alpha: 0.1);
      borderColor = AppColors.error.withValues(alpha: 0.35);
    } else if (msg.text.contains('[🔴 HIGH]')) {
      bgColor = Colors.orange.withValues(alpha: 0.1);
      borderColor = Colors.orange.withValues(alpha: 0.35);
    } else if (msg.text.contains('[💡 NOTE]')) {
      bgColor = AppColors.primary.withValues(alpha: 0.05);
      borderColor = AppColors.primary.withValues(alpha: 0.2);
    }

    final formattedText = msg.text
        .replaceAll('[🚨 CRITICAL]:', '🚨 حرج جداً:')
        .replaceAll('[🔴 HIGH]:', '🔴 تنبيه عالي:')
        .replaceAll('[💡 NOTE]:', '💡 ملاحظة سريرية:');

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text('المساعد السريري',
                    style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              formattedText,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14, height: 1.65, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
