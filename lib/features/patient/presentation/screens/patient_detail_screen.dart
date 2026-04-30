import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../domain/entities/patient_entity.dart';
import '../../../prescription/domain/entities/prescription_entity.dart';
import '../../../prescription/presentation/providers/prescription_provider.dart';
import '../../../prescription/presentation/screens/new_prescription_screen.dart';
import '../../../prescription/utils/pdf_prescription_service.dart';
import '../../../doctor/presentation/providers/doctor_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rachita/core/utils/clinical_logic.dart';
import '../providers/patient_provider.dart';
import '../widgets/clinical_risk_card.dart';
import '../widgets/medication_list_widget.dart';


class PatientDetailScreen extends ConsumerStatefulWidget {
  final PatientEntity patient;
  const PatientDetailScreen({super.key, required this.patient});

  @override
  ConsumerState<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final prescriptionsAsync = ref.watch(patientPrescriptionsProvider(widget.patient.id!));
    final doctor = ref.watch(doctorProvider).value;
    final accentColor = widget.patient.gender == 'male' ? AppColors.primary : AppColors.secondary;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildNestedAppBar(context, accentColor),
            SliverToBoxAdapter(child: _buildPatientHeaderHud()),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: 'الملخص', icon: Icon(Icons.analytics_outlined, size: 20)),
                    Tab(text: 'الزيارات', icon: Icon(Icons.history_edu_rounded, size: 20)),
                    Tab(text: 'الرسوم', icon: Icon(Icons.show_chart_rounded, size: 20)),
                    Tab(text: 'الملف', icon: Icon(Icons.person_pin_rounded, size: 20)),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildSummaryTab(prescriptionsAsync),
              _buildVisitsTab(prescriptionsAsync, doctor, accentColor),
              _buildAnalyticsTab(prescriptionsAsync),
              _buildProfileTab(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            ref.read(currentPrescriptionProvider.notifier).state = null;
            Navigator.push(context, MaterialPageRoute(builder: (_) => NewPrescriptionScreen(patientId: widget.patient.id!)));
          },
          backgroundColor: AppColors.primary,
          elevation: 4,
          icon: const Icon(Icons.add_moderator_rounded, color: Colors.white),
          label: const Text('روشتة جديدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildNestedAppBar(BuildContext context, Color color) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.print_rounded, color: AppColors.primary),
          onPressed: () {
            // Future: Print full patient summary
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(widget.patient.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(right: 56, bottom: 16),
      ),
    );
  }

  Widget _buildPatientHeaderHud() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _hudMiniItem('العمر', '${widget.patient.age ?? "--"}'),
          _hudMiniItem('فصيلة الدم', widget.patient.bloodGroup ?? "--", color: Colors.redAccent),
          _hudMiniItem('الجنس', widget.patient.gender == 'male' ? 'ذكر' : 'أنثى'),
          _hudMiniItem('الزيارات', '${widget.patient.visitCount}'),
        ],
      ),
    );
  }

  Widget _hudMiniItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color ?? AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSummaryTab(AsyncValue<List<PrescriptionEntity>> rxs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClinicalRiskCard(patient: widget.patient),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildSectionTitle('التحليل السريري الأخير', Icons.science_outlined),
          const SizedBox(height: 16),
          _buildClinicalAnalysis(rxs),
          const SizedBox(height: 32),
          _buildSectionTitle('الملاحظات الطبية المستمرة', Icons.history_edu_rounded),
          const SizedBox(height: 16),
          _buildAlertCard(),
          const SizedBox(height: 16),
          _buildPermanentNotes(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(child: _actionButton('تصدير PDF', Icons.picture_as_pdf_rounded, AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _actionButton('مشاركة', Icons.share_rounded, Colors.blueGrey)),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }


  Widget _buildAlertCard() {
    bool hasAllergies = widget.patient.allergies?.isNotEmpty ?? false;
    bool hasChronic = widget.patient.chronicDiseases?.isNotEmpty ?? false;

    if (!hasAllergies && !hasChronic) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('تنبيهات طبية هامة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.orange)),
            ],
          ),
          if (hasAllergies) ...[
            const SizedBox(height: 12),
            Text('الحساسية: ${widget.patient.allergies}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
          if (hasChronic) ...[
            const SizedBox(height: 8),
            Text('أمراض مزمنة: ${widget.patient.chronicDiseases}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ],
      ),
    );
  }

  Widget _buildClinicalAnalysis(AsyncValue<List<PrescriptionEntity>> rxs) {
    return rxs.when(
      data: (list) {
        if (list.isEmpty) return _buildEmptyAnalysis();
        final latest = list.first;
        final bpStatus = ClinicalLogic.interpretBP(latest.systolic, latest.diastolic);
        final bmi = ClinicalLogic.calculateBMI(latest.weight, widget.patient.height);
        final bmiStatus = ClinicalLogic.calculateBMIStatus(latest.weight, widget.patient.height ?? 170.0);

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _analysisBox('مؤشر BMI', bmi?.toStringAsFixed(1) ?? "--", ClinicalLogic.getBMIAr(bmiStatus), AppColors.primary)),
                const SizedBox(width: 16),
                Expanded(child: _analysisBox('ضغط الدم', latest.systolic != null ? '${latest.systolic}/${latest.diastolic}' : "--", ClinicalLogic.getBPStatusAr(bpStatus), ClinicalLogic.getBPColor(bpStatus))),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow('آخر تشخيص', latest.diagnosis ?? "لم يحدد", Icons.assignment_turned_in_outlined),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _analysisBox(String label, String value, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildVisitsTab(AsyncValue<List<PrescriptionEntity>> rxs, doctor, Color themeColor) {
    return rxs.when(
      data: (prescriptions) {
        if (prescriptions.isEmpty) return _buildEmptyVisits();
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: prescriptions.length,
          itemBuilder: (ctx, i) => _buildVisitCard(prescriptions[i], doctor, i == 0, themeColor),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  Widget _buildVisitCard(PrescriptionEntity rx, doctor, bool isLatest, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isLatest ? themeColor.withOpacity(0.3) : AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isLatest,
          title: Text(intl.DateFormat('dd MMMM yyyy', 'ar').format(rx.createdAt), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textSecondary)),
          subtitle: Text(rx.diagnosis ?? "فحص عام", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.medical_information_outlined, color: themeColor, size: 20),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.print_outlined, color: AppColors.primary),
            onPressed: () {
               if (doctor != null) {
                 PdfPrescriptionService.generateAndPrint(doctor: doctor, patient: widget.patient, prescription: rx);
               }
            },
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('الأدوية الموصوفة:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  if (rx.medicines?.isEmpty ?? true)
                    const Text('لا توجد أدوية لهذة الزيارة', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                  else
                    ...rx.medicines!.map((m) => _medicineMiniRow(m)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _medicineMiniRow(m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(child: Text(m.medicineName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          Text('${m.dosage} - ${m.frequency}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(AsyncValue<List<PrescriptionEntity>> rxs) {
    return rxs.when(
      data: (list) {
        if (list.length < 2) return _buildNotEnoughData();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildChartSection('منحنى ضغط الدم (الانقباضي)', _getBpSpots(list), Colors.redAccent),
              const SizedBox(height: 24),
              _buildChartSection('معدل السكر (mg/dL)', _getSugarSpots(list), Colors.orange),
              const SizedBox(height: 24),
              _buildChartSection('تغيرات الوزن (كغ)', _getWeightSpots(list), AppColors.primary),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }

  List<FlSpot> _getSugarSpots(List<PrescriptionEntity> list) {
    final history = list.reversed.toList();
    List<FlSpot> spots = [];
    for (int i = 0; i < history.length; i++) {
       if (history[i].sugar != null) spots.add(FlSpot(i.toDouble(), history[i].sugar!));
    }
    return spots;
  }


  List<FlSpot> _getBpSpots(List<PrescriptionEntity> list) {
    final history = list.reversed.toList();
    List<FlSpot> spots = [];
    for (int i = 0; i < history.length; i++) {
       if (history[i].systolic != null) spots.add(FlSpot(i.toDouble(), history[i].systolic!.toDouble()));
    }
    return spots;
  }

  List<FlSpot> _getWeightSpots(List<PrescriptionEntity> list) {
    final history = list.reversed.toList();
    List<FlSpot> spots = [];
    for (int i = 0; i < history.length; i++) {
       if (history[i].weight != null) spots.add(FlSpot(i.toDouble(), history[i].weight!));
    }
    return spots;
  }

  Widget _buildChartSection(String title, List<FlSpot> spots, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 4,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('المعلومات الديموغرافية', Icons.badge_outlined),
          const SizedBox(height: 16),
          _bioItem('الاسم الكامل', widget.patient.name, Icons.person_outline),
          _bioItem('رقم الهاتف', widget.patient.phone ?? "--", Icons.phone_android_outlined),
          _bioItem('العمر والفئة', '${widget.patient.age ?? "--"} سنة (${_getAgeCategoryAr(widget.patient.ageCategory)})', Icons.calendar_month_outlined),
          _bioItem('الطول الشخصي', '${widget.patient.height ?? "--"} سم', Icons.height_outlined),
          _bioItem('فصيلة الدم', widget.patient.bloodGroup ?? "--", Icons.bloodtype_outlined),
          
          if (widget.patient.gender == 'female')
             _bioItem('حالة الحمل', widget.patient.isPregnant ? 'نعم - مراجعة دقيقة' : 'لا', Icons.pregnant_woman_rounded),

          const SizedBox(height: 24),
          _buildSectionTitle('التاريخ السريري المفصل', Icons.account_tree_outlined),
          const SizedBox(height: 16),
          MedicationListWidget(
            title: 'الأدوية الحالية',
            jsonList: widget.patient.currentMedicationsJson,
            icon: Icons.medication_liquid_rounded,
            themeColor: AppColors.primary,
          ),
          const SizedBox(height: 16),
          MedicationListWidget(
            title: 'التاريخ المرضي المسبق',
            jsonList: widget.patient.preexistingConditionsJson,
            icon: Icons.history_rounded,
            themeColor: AppColors.secondary,
          ),
          const SizedBox(height: 16),
          MedicationListWidget(
            title: 'سجل الأدوية السابقة',
            jsonList: widget.patient.medicationHistoryJson,
            icon: Icons.replay_rounded,
            themeColor: Colors.blueGrey,
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('تعديل الملف الطبي الكامل'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAgeCategoryAr(int cat) {
    switch (cat) {
      case 0: return 'أطفال';
      case 1: return 'يافعين';
      case 2: return 'بالغين';
      case 3: return 'كبار سن';
      default: return 'عام';
    }
  }


  Widget _bioItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.textSecondary, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermanentNotes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Text(
        widget.patient.notes ?? "لا توجد ملاحظات طبية مسجلة حالياً.",
        style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildEmptyAnalysis() => const Center(child: Text('لا توجد بيانات كافية للتحليل حالياً'));
  Widget _buildEmptyVisits() => const Center(child: Text('السجل فارغ. ابدأ بإضافة روشتة مريض أولى.'));
  Widget _buildNotEnoughData() => const Center(child: Text('تحتاج لزيارتين على الأقل لإظهار الرسوم البيانية.'));
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
