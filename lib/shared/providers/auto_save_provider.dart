import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AutoSaveStatus { idle, saving, saved }

final autoSaveProvider = StateNotifierProvider<AutoSaveNotifier, AutoSaveStatus>((ref) {
  return AutoSaveNotifier();
});

class AutoSaveNotifier extends StateNotifier<AutoSaveStatus> {
  AutoSaveNotifier() : super(AutoSaveStatus.idle);
  Timer? _debounce;

  void onFieldChanged(VoidCallback saveAction) {
    state = AutoSaveStatus.saving;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      saveAction();
      state = AutoSaveStatus.saved;
      Future.delayed(
        const Duration(seconds: 2),
        () {
          if (mounted && state == AutoSaveStatus.saved) {
            state = AutoSaveStatus.idle;
          }
        },
      );
    });
  }
  
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
