import '../hybrid_suggestion_engine.dart';

/// 🏥 خدمة إدارة التنبيهات السريرية
class ClinicalAlertService {
  static final ClinicalAlertService _instance =
      ClinicalAlertService._internal();

  factory ClinicalAlertService() {
    return _instance;
  }

  ClinicalAlertService._internal();

  /// 🆕 تنبيهات تم إنشاؤها (Observable للـ Riverpod/StateNotifier)
  final _alerts = <ClinicalAlert>[];

  /// 🔍 احصل على جميع التنبيهات
  List<ClinicalAlert> getAlerts() => List.unmodifiable(_alerts);

  /// 📊 احصل على التنبيهات بناءً على الأولوية
  List<ClinicalAlert> getAlertsByPriority(AlertPriority priority) {
    return _alerts.where((alert) => alert.priority == priority).toList();
  }

  /// ✅ إضافة تنبيه جديد
  void addAlert(ClinicalAlert alert) {
    _alerts.add(alert);
  }

  /// 🗑️ إزالة تنبيه
  void removeAlert(ClinicalAlert alert) {
    _alerts.remove(alert);
  }

  /// ✔️ تعليم تنبيه كمحل
  void resolveAlert(ClinicalAlert alert, String? resolutionNotes) {
    final index = _alerts.indexOf(alert);
    if (index != -1) {
      _alerts[index] = alert.copyWith(
        isResolved: true,
        resolutionNotes: resolutionNotes,
        resolvedAt: DateTime.now(),
      );
    }
  }

  /// 📉 مسح جميع التنبيهات المحلولة
  void clearResolvedAlerts() {
    _alerts.removeWhere((alert) => alert.isResolved);
  }

  /// 🔄 مسح جميع التنبيهات
  void clearAllAlerts() {
    _alerts.clear();
  }

  /// 📊 احصل على إحصائيات التنبيهات
  AlertStatistics getStatistics() {
    return AlertStatistics(
      totalAlerts: _alerts.length,
      critical:
          _alerts.where((a) => a.priority == AlertPriority.critical).length,
      warning: _alerts.where((a) => a.priority == AlertPriority.warning).length,
      info: _alerts.where((a) => a.priority == AlertPriority.info).length,
      unresolved: _alerts.where((a) => !a.isResolved).length,
      resolved: _alerts.where((a) => a.isResolved).length,
    );
  }

  /// 🎯 تحويل نتائج المحرك إلى تنبيهات
  List<ClinicalAlert> generateAlertsFromSuggestions(
    HybridSuggestionResult suggestions,
    String patientId,
    String prescriptionId,
  ) {
    final alerts = <ClinicalAlert>[];

    // 1. تنبيهات تفاعلات الأدوية (الأهم) - 🆕 تستخدم الكائن الغني
    for (final interaction in suggestions.drugInteractionAlerts) {
      final msgText = interaction.toString();
      alerts.add(
        ClinicalAlert(
          title: '${interaction.severityIcon} تفاعل: ${interaction.drug1} + ${interaction.drug2}',
          message: interaction.description,
          type: ClinicalAlertType.drugInteraction,
          priority: _extractPriorityFromText(msgText),
          patientId: patientId,
          prescriptionId: prescriptionId,
          recommendation: interaction.recommendation,
        ),
      );
    }


    // 2. تنبيهات الحساسية (الأهم)
    for (final allergy in suggestions.allergyAlerts) {
      alerts.add(
        ClinicalAlert(
          title: 'تحذير حساسية',
          message: allergy,
          type: ClinicalAlertType.allergicReaction,
          priority: AlertPriority.critical,
          patientId: patientId,
          prescriptionId: prescriptionId,
          recommendation: 'تجنب الأدوية المذكورة فوراً',
        ),
      );
    }

    // 3. تنبيهات الحمل
    for (final pregnancy in suggestions.pregnancyAlerts) {
      alerts.add(
        ClinicalAlert(
          title: 'تحذير الحمل',
          message: pregnancy,
          type: ClinicalAlertType.pregnancyWarning,
          priority: _extractPriorityFromText(pregnancy),
          patientId: patientId,
          prescriptionId: prescriptionId,
          recommendation: 'استخدم أدوية آمنة أثناء الحمل',
        ),
      );
    }

    // 4. تنبيهات العمر والأطفال
    for (final ageAlert in suggestions.ageSpecificAlerts) {
      alerts.add(
        ClinicalAlert(
          title: 'تحذير عمري',
          message: ageAlert,
          type: ClinicalAlertType.ageInappropriate,
          priority: AlertPriority.warning,
          patientId: patientId,
          prescriptionId: prescriptionId,
          recommendation: 'اضبط الجرعات وفقاً لعمر المريض',
        ),
      );
    }

    // 5. تنبيهات صحية عامة
    for (final vital in suggestions.vitalsWarnings) {
      alerts.add(
        ClinicalAlert(
          title: 'تحذير حيوي',
          message: vital,
          type: ClinicalAlertType.dosaageWarning,
          priority: AlertPriority.warning,
          patientId: patientId,
          prescriptionId: prescriptionId,
        ),
      );
    }

    // 6. إضافة تنبيه مخاطر إذا كانت درجة المخاطرة عالية
    if (suggestions.riskScore >= 60) {
      alerts.add(
        ClinicalAlert(
          title: 'مخاطر سريرية مرتفعة',
          message:
              'درجة المخاطرة: ${suggestions.riskScore}/100 (${suggestions.riskLevel})',
          type: ClinicalAlertType.longTermRisk,
          priority: suggestions.riskScore >= 80
              ? AlertPriority.critical
              : AlertPriority.warning,
          patientId: patientId,
          prescriptionId: prescriptionId,
          recommendation: 'راجع الوصفة بعناية شديدة',
        ),
      );
    }

    return alerts;
  }

  /// 🔍 استخراج مستوى الأولوية من النص
  AlertPriority _extractPriorityFromText(String text) {
    if (text.contains('🚨') || text.contains('حرج')) {
      return AlertPriority.critical;
    }
    if (text.contains('⚠️') || text.contains('تحذير')) {
      return AlertPriority.warning;
    }
    return AlertPriority.info;
  }
}

/// 📌 نموذج التنبيه السريري
class ClinicalAlert {
  final String id;
  final String title;
  final String message;
  final ClinicalAlertType type;
  final AlertPriority priority;
  final String? patientId;
  final String? prescriptionId;
  final String? recommendation;
  final bool isResolved;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;

  ClinicalAlert({
    String? id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    this.patientId,
    this.prescriptionId,
    this.recommendation,
    this.isResolved = false,
    DateTime? createdAt,
    this.resolvedAt,
    this.resolutionNotes,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  /// 📋 نسخ مع تعديلات
  ClinicalAlert copyWith({
    String? id,
    String? title,
    String? message,
    ClinicalAlertType? type,
    AlertPriority? priority,
    String? patientId,
    String? prescriptionId,
    String? recommendation,
    bool? isResolved,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolutionNotes,
  }) {
    return ClinicalAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      patientId: patientId ?? this.patientId,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      recommendation: recommendation ?? this.recommendation,
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }

  /// 🔴 هل التنبيه حرج؟
  bool get isCritical => priority == AlertPriority.critical;

  /// 🟡 هل التنبيه تحذير؟
  bool get isWarning => priority == AlertPriority.warning;

  /// 🔵 هل التنبيه معلومة؟
  bool get isInfo => priority == AlertPriority.info;
}

/// 🏥 أنواع التنبيهات السريرية
enum ClinicalAlertType {
  allergicReaction, // حساسية
  drugInteraction, // تفاعل أدوية
  contraindicatedCondition, // حالة موانع
  dosaageWarning, // تحذير جرعة
  longTermRisk, // خطر طويل الأجل
  ageInappropriate, // عمر غير مناسب
  pregnancyWarning, // تحذير حمل
  kidneyFunction, // وظيفة كلوية
  liverFunction, // وظيفة كبدية
}

/// 🎯 مستويات أولوية التنبيه
enum AlertPriority {
  info, // معلومة (أزرق)
  warning, // تحذير (أصفر/برتقالي)
  critical, // حرج (أحمر)
}

/// 📊 إحصائيات التنبيهات
class AlertStatistics {
  final int totalAlerts;
  final int critical;
  final int warning;
  final int info;
  final int unresolved;
  final int resolved;

  AlertStatistics({
    required this.totalAlerts,
    required this.critical,
    required this.warning,
    required this.info,
    required this.unresolved,
    required this.resolved,
  });

  /// 📈 معدل الحرجية (نسبة التنبيهات الحرجة)
  double get severityRate =>
      totalAlerts == 0 ? 0 : (critical / totalAlerts) * 100;

  /// 📉 معدل الحل (نسبة التنبيهات المحلولة)
  double get resolutionRate =>
      totalAlerts == 0 ? 0 : (resolved / totalAlerts) * 100;
}
