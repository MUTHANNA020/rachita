import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../utils/medical_speech_normalizer.dart';
import 'smart_voice_command_service.dart';
import '../../features/prescription/presentation/providers/medical_intelligence_providers.dart';


final speechServiceProvider = Provider((ref) => SpeechService(ref));
final isListeningProvider = StateProvider.family<bool, String>((ref, id) => false);
final partialSpeechProvider = StateProvider.family<String, String>((ref, id) => '');

final smartVoiceCommandProvider = Provider<SmartVoiceCommandService>((ref) {
  final dynamicService = ref.watch(dynamicClinicalServiceProvider);
  return SmartVoiceCommandService(dynamicService);
});


class SpeechService {
  final Ref _ref;
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool _isInitializing = false;
  String? _activeId;

  SpeechService(this._ref);

  Future<bool> init(String id) async {
    if (_isAvailable) return true;
    if (_isInitializing) return false;
    _isInitializing = true;

    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[Speech] Status: $status for ID: $_activeId');
          final listening = status == 'listening';
          if (_activeId != null) {
            _ref.read(isListeningProvider(_activeId!).notifier).state = listening;
            if (!listening) {
              _ref.read(partialSpeechProvider(_activeId!).notifier).state = '';
            }
          }
        },
        onError: (error) {
          debugPrint('[Speech] Error: ${error.errorMsg} for ID: $_activeId');
          if (_activeId != null) {
            _ref.read(isListeningProvider(_activeId!).notifier).state = false;
            _ref.read(partialSpeechProvider(_activeId!).notifier).state = '';
          }
          if (error.permanent) _isAvailable = false;
        },
      );
    } catch (e) {
      debugPrint('[Speech] Init exception: $e');
      _isAvailable = false;
    } finally {
      _isInitializing = false;
    }

    return _isAvailable;
  }

  Future<void> startListening({
    required String id,
    required Function(String) onResult,
    Function(String)? onPartial,
    String? languageCode,
    bool medicalMode = true,
  }) async {
    final available = await init(id);
    if (!available) {
      debugPrint('[Speech] Not available');
      return;
    }

    if (_speech.isListening) {
      await stopListening();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _activeId = id;
    _ref.read(isListeningProvider(id).notifier).state = true;

    await _speech.listen(
      onResult: (result) {
        final raw = result.recognizedWords;
        if (_activeId == id) {
          _ref.read(partialSpeechProvider(id).notifier).state = raw;
          onPartial?.call(raw);

          if (result.finalResult && raw.trim().isNotEmpty) {
            final corrected = medicalMode
                ? MedicalSpeechNormalizer.normalize(raw)
                : raw;
            onResult(corrected);
            _ref.read(isListeningProvider(id).notifier).state = false;
            _ref.read(partialSpeechProvider(id).notifier).state = '';
            _activeId = null;
          }
        }
      },
      localeId: languageCode ?? 'en_US',
      listenFor: const Duration(minutes: 5), // Session limit
      pauseFor: const Duration(seconds: 4),  // Auto-stop after 4s silence
      onDevice: true, // Use on-device for faster response if available
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    if (_activeId != null) {
      _ref.read(isListeningProvider(_activeId!).notifier).state = false;
      _ref.read(partialSpeechProvider(_activeId!).notifier).state = '';
      _activeId = null;
    }
  }

  bool get isListening => _speech.isListening;
}
