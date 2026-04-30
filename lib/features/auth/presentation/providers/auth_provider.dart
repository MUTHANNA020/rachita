import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../doctor/presentation/providers/doctor_provider.dart';
import '../../../patient/presentation/providers/patient_provider.dart';
import '../../../prescription/presentation/providers/prescription_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/auth_repository.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository, ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref)
      : super(AuthState(isAuthenticated: _repository.isAuthenticated()));

  void _invalidateAllClinicalData() {
    _ref.invalidate(doctorProvider);
    _ref.invalidate(patientsProvider);
    _ref.invalidate(globalPatientCountProvider);
    _ref.invalidate(patientPrescriptionsProvider);
    _ref.invalidate(currentPrescriptionProvider);
    _ref.invalidate(diagnosesSuggestionsProvider);
    _ref.invalidate(notesSuggestionsProvider);
    _ref.invalidate(globalPrescriptionCountProvider);
    _ref.invalidate(dashboardStatsProvider);
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.login(username, password);
      if (success) {
        _invalidateAllClinicalData();
        state = state.copyWith(isLoading: false, isAuthenticated: true);
      } else {
        state = state.copyWith(isLoading: false, error: 'اسم المستخدم أو كلمة المرور غير صحيحة');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'حدث خطأ أثناء تسجيل الدخول: $e');
    }
  }

  void logout() {
    _repository.logout();
    _invalidateAllClinicalData();
    state = state.copyWith(isAuthenticated: false);
  }
}
