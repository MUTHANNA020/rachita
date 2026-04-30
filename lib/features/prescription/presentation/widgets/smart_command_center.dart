import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/services/smart_voice_command_service.dart';

/// 🚀 مركز القيادة السريري الذكي - Smart Clinical Command Center
/// 
/// واجهة متطورة تدعم الأوامر الصوتية والنصية بدقة عالية واستجابة فورية.
class SmartCommandCenter extends ConsumerStatefulWidget {
  final Function(SmartCommandResult) onCommandExecuted;

  const SmartCommandCenter({super.key, required this.onCommandExecuted});

  @override
  ConsumerState<SmartCommandCenter> createState() => _SmartCommandCenterState();
}

class _SmartCommandCenterState extends ConsumerState<SmartCommandCenter> {
  final String _id = 'clinical_command_center';
  String _lastFeedback = 'تحدث الآن لوصف علاج أو تشخيص...';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isListening = ref.watch(isListeningProvider(_id));
    final partialText = ref.watch(partialSpeechProvider(_id));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const Duration(milliseconds: 400).inMilliseconds > 0 ? const EdgeInsets.all(16) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isListening ? Colors.blue.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isListening ? Colors.blue : Colors.grey.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: isListening ? [
          BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)
        ] : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildVoiceButton(isListening),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isListening ? 'جاري الاستماع...' : 'المساعد السريري الذكي',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isListening ? Colors.blue : Colors.grey[700],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isListening && partialText.isNotEmpty ? partialText : _lastFeedback,
                      style: TextStyle(
                        color: isListening ? Colors.blue[700] : Colors.grey[600],
                        fontStyle: isListening ? FontStyle.italic : FontStyle.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isProcessing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton(bool isListening) {
    return GestureDetector(
      onTap: () => _toggleListening(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isListening ? Colors.red : Colors.blue,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isListening ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  void _toggleListening() async {
    final speechService = ref.read(speechServiceProvider);
    
    if (speechService.isListening) {
      await speechService.stopListening();
    } else {
      await speechService.startListening(
        id: _id,
        onResult: (text) async {
          setState(() => _isProcessing = true);
          final smartCommandService = ref.read(smartVoiceCommandProvider);
          final result = await smartCommandService.processCommand(text);
          
          setState(() {
            _lastFeedback = result.message ?? 'تم تنفيذ الأمر بنجاح';
            _isProcessing = false;
          });

          widget.onCommandExecuted(result);
        },
      );
    }
  }
}
