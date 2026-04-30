import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/speech_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/providers/app_settings_provider.dart';

class VoiceButton extends ConsumerStatefulWidget {
  final String contextId; // Required for independence
  final Function(String) onResult;
  final Function(String)? onPartial;
  final String? languageCode;
  final double size;
  final bool medicalMode;

  const VoiceButton({
    super.key,
    required this.contextId,
    required this.onResult,
    this.onPartial,
    this.languageCode,
    this.size = 44,
    this.medicalMode = true,
  });

  @override
  ConsumerState<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends ConsumerState<VoiceButton>
    with TickerProviderStateMixin {
  late AnimationController _ring1;
  late AnimationController _ring2;
  late AnimationController _pressCtrl;

  late Animation<double> _ring1Anim;
  late Animation<double> _ring2Anim;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();

    _ring1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _ring2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));

    _ring1Anim = Tween<double>(begin: 1.0, end: 1.6)
        .animate(CurvedAnimation(parent: _ring1, curve: Curves.easeOut));
    _ring2Anim = Tween<double>(begin: 1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _ring2, curve: Curves.easeOut));
    _pressAnim = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ring1.dispose();
    _ring2.dispose();
    _pressCtrl.dispose();
    super.dispose();
  }

  void _startPulse() {
    _ring1.repeat();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _ring2.repeat();
    });
  }

  void _stopPulse() {
    _ring1.stop(); _ring1.reset();
    _ring2.stop(); _ring2.reset();
  }

  void _toggleAuto(String lang) {
     // No action needed here, but ensures we have the language available
  }

  Future<void> _toggle() async {
    HapticFeedback.mediumImpact();
    _pressCtrl.forward().then((_) => _pressCtrl.reverse());

    final speech = ref.read(speechServiceProvider);
    final listening = ref.read(isListeningProvider(widget.contextId));
    final settings = ref.read(appSettingsProvider);

    if (listening) {
      await speech.stopListening();
    } else {
      // Use "ar-SA" for Arabic and "en-US" for English to ensure high accuracy
      final effectiveLocale = widget.languageCode ?? 
          (settings.locale.languageCode == 'ar' ? 'ar-SA' : 'en-US');

      await speech.startListening(
        id: widget.contextId,
        onResult: widget.onResult,
        onPartial: widget.onPartial,
        languageCode: effectiveLocale,
        medicalMode: widget.medicalMode,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isListening = ref.watch(isListeningProvider(widget.contextId));
    final partial = ref.watch(partialSpeechProvider(widget.contextId));

    if (isListening && !_ring1.isAnimating) _startPulse();
    if (!isListening && _ring1.isAnimating) _stopPulse();

    _toggleAuto(settings.locale.languageCode);

    const Color activeColor = Color(0xFFE53935);
    const Color idleColor = AppColors.primary;
    final double s = widget.size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _pressAnim,
          child: SizedBox(
            width: s + 24,
            height: s + 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer fade ring
                if (isListening)
                  AnimatedBuilder(
                    animation: _ring2Anim,
                    builder: (_, __) => Container(
                      width: s * _ring2Anim.value,
                      height: s * _ring2Anim.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor.withValues(
                          alpha: (1.0 - _ring2.value) * 0.10,
                        ),
                      ),
                    ),
                  ),
                // Inner pulse ring
                if (isListening)
                  AnimatedBuilder(
                    animation: _ring1Anim,
                    builder: (_, __) => Container(
                      width: s * _ring1Anim.value,
                      height: s * _ring1Anim.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor.withValues(
                          alpha: (1.0 - _ring1.value) * 0.18,
                        ),
                      ),
                    ),
                  ),
                // Core button
                GestureDetector(
                  onTap: _toggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 230),
                    curve: Curves.easeInOut,
                    width: s,
                    height: s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening ? activeColor : idleColor.withValues(alpha: 0.08),
                      border: Border.all(
                        color: isListening ? activeColor : idleColor.withValues(alpha: 0.30),
                        width: isListening ? 0 : 1.5,
                      ),
                      boxShadow: isListening
                          ? [BoxShadow(color: activeColor.withValues(alpha: 0.35), blurRadius: 14, spreadRadius: 2)]
                          : [],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          key: ValueKey(isListening),
                          color: isListening ? Colors.white : idleColor,
                          size: s * 0.46,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Live partial text display
        if (isListening && partial.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 240),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: activeColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                partial,
                style: const TextStyle(
                  fontSize: 12,
                  color: activeColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}

