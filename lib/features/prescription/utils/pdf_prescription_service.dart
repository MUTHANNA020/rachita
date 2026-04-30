import 'dart:io' show File;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import '../../doctor/domain/entities/doctor_entity.dart';
import '../../patient/domain/entities/patient_entity.dart';
import '../domain/entities/prescription_entity.dart';

class PdfPrescriptionService {
  static Future<void> printPrescription({
    required DoctorEntity doctor,
    required PatientEntity patient,
    required PrescriptionEntity prescription,
    required String languageCode,
  }) async {
    final pdfBytes = await generatePrescriptionPdfBytes(
      doctor: doctor,
      patient: patient,
      prescription: prescription,
      languageCode: languageCode,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Prescription_${patient.name}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static Future<void> generateAndPrint({
    required DoctorEntity doctor,
    required PatientEntity patient,
    required PrescriptionEntity prescription,
    String languageCode = 'ar',
  }) async {
    await printPrescription(
      doctor: doctor,
      patient: patient,
      prescription: prescription,
      languageCode: languageCode,
    );
  }

  static Future<Uint8List> generatePrescriptionPdfBytes({
    required DoctorEntity doctor,
    required PatientEntity patient,
    required PrescriptionEntity prescription,
    required String languageCode,
  }) async {
    // ── CONFIG & COLORS ────────────────────────────────────────────────────────
    final bool isRtl = languageCode == 'ar';
    const primaryColor = PdfColor.fromInt(0xFF003780); // Deep Navy
    const accentColor = PdfColor.fromInt(0xFF00A299);  // Clinical Teal
    const borderColor = PdfColors.grey400;

    // ── FONTS ──────────────────────────────────────────────────────────────────
    final fontRegularData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
    final fontBoldData = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
    final fontLatinData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");

    final fontRegular = pw.Font.ttf(fontRegularData);
    final fontBold = pw.Font.ttf(fontBoldData);
    final fontLatin = pw.Font.ttf(fontLatinData);

    // ── ASSETS ─────────────────────────────────────────────────────────────────
    pw.ImageProvider? signatureImage;
    if (doctor.signaturePath != null && doctor.signaturePath!.isNotEmpty) {
      try {
        if (doctor.signaturePath!.startsWith('data:image')) {
          signatureImage = pw.MemoryImage(base64Decode(doctor.signaturePath!.split(',').last));
        } else if (kIsWeb || doctor.signaturePath!.startsWith('http')) {
          signatureImage = await networkImage(doctor.signaturePath!);
        } else if (File(doctor.signaturePath!).existsSync()) {
          signatureImage = pw.MemoryImage(File(doctor.signaturePath!).readAsBytesSync());
        }
      } catch (e) {
        print("⚠️ Failed to load signature image: $e");
      }
    }

    pw.ImageProvider? logoImage;
    if (doctor.logoPath != null && doctor.logoPath!.isNotEmpty) {
      try {
        if (doctor.logoPath!.startsWith('data:image')) {
          logoImage = pw.MemoryImage(base64Decode(doctor.logoPath!.split(',').last));
        } else if (kIsWeb || doctor.logoPath!.startsWith('http')) {
          logoImage = await networkImage(doctor.logoPath!);
        } else if (File(doctor.logoPath!).existsSync()) {
          logoImage = pw.MemoryImage(File(doctor.logoPath!).readAsBytesSync());
        }
      } catch (e) {
        print("⚠️ Failed to load logo image: $e");
      }
    }

    // ── DICTIONARY ────────────────────────────────────────────────────────────
    final Map<String, Map<String, String>> dict = {
      'ar': {
        'doctor': 'الدكتور:',
        'specialty': 'الاختصاص:',
        'patient': 'المريض:',
        'age': 'العمر:',
        'gender': 'الجنس:',
        'date': 'التاريخ:',
        'rx_id': 'رقم الوصفة:',
        'diagnosis': 'التشخيص:',
        'medicine': 'العلاج',
        'symptoms': 'الأعراض:',
        'dosage': 'الجرعة',
        'freq': 'التكرار',
        'duration': 'المدة',
        'route': 'المسار',
        'qty': 'الكمية',
        'note': 'ملاحظات إضافية:',
        'address': 'العنوان:',
        'phone': 'الهاتف:',
        'license': 'رقم الترخيص:',
        'male': 'ذكر',
        'female': 'أنثى',
        'signature': 'التوقيع والختم الرسمي',
        'weight': 'الوزن:',
        'height': 'الطول:',
        'bp': 'الضغط:',
        'sugar': 'السكري:',
        'temp': 'الحرارة:',
        'pulse': 'النبض:',
        'iop': 'ضغط العين:',
        'va': 'حدة الإبصار:',
        'head_circ': 'محيط الرأس:',
      },
      'en': {
        'doctor': 'Dr.',
        'specialty': 'Specialty:',
        'patient': 'Patient Name:',
        'age': 'Age:',
        'gender': 'Gender:',
        'date': 'Date:',
        'rx_id': 'Rx ID:',
        'diagnosis': 'Diagnosis:',
        'medicine': 'Medication',
        'symptoms': 'Symptoms:',
        'dosage': 'Dosage',
        'freq': 'Frequency',
        'duration': 'Duration',
        'route': 'Route',
        'qty': 'Qty',
        'note': 'Additional Notes:',
        'address': 'Address:',
        'phone': 'Phone:',
        'license': 'License No:',
        'male': 'Male',
        'female': 'Female',
        'signature': 'Official Signature & Stamp',
        'weight': 'Weight:',
        'height': 'Height:',
        'bp': 'BP:',
        'sugar': 'Sugar:',
        'temp': 'Temp:',
        'pulse': 'Pulse:',
        'iop': 'IOP:',
        'va': 'VA:',
        'head_circ': 'Head Circ:',
      }
    };

    final L = dict[languageCode]!;
    final formattedDate = intl.DateFormat('yyyy/MM/dd').format(prescription.date);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        header: (ctx) => pw.Column(children: [
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Dr. ${doctor.nameEn?.trim() ?? doctor.name.trim()}', style: pw.TextStyle(font: fontBold, fontSize: 16, color: primaryColor, fontFallback: [fontLatin])),
                      pw.SizedBox(height: 1),
                      pw.Text(doctor.specialtyEn?.trim() ?? doctor.specialty.trim(), style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey900, fontFallback: [fontLatin])),
                      if (doctor.credentialsEn != null && doctor.credentialsEn!.trim().isNotEmpty)
                        pw.Padding(padding: const pw.EdgeInsets.only(top: 1.5), child: pw.Text(doctor.credentialsEn!.trim(), style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey700, fontFallback: [fontLatin]))),
                      if (doctor.bioEn != null && doctor.bioEn!.trim().isNotEmpty)
                        pw.Padding(padding: const pw.EdgeInsets.only(top: 2.5), child: pw.Text(doctor.bioEn!.trim(), style: pw.TextStyle(font: fontRegular, fontSize: 6.8, color: PdfColors.grey600, fontFallback: [fontLatin]))),
                    ],
                  ),
                ),
                if (logoImage != null)
                   pw.Padding(
                     padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                     child: pw.Image(logoImage, width: 50, height: 50, fit: pw.BoxFit.contain),
                   )
                else
                   pw.Padding(
                     padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                     child: pw.Container(width: 0.8, height: 55, color: borderColor),
                   ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('الدكتور/ ${doctor.name.trim()}', style: pw.TextStyle(font: fontBold, fontSize: 16, color: primaryColor)),
                        pw.SizedBox(height: 1),
                        pw.Text(doctor.specialty.trim(), style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey900)),
                        if (doctor.credentials != null && doctor.credentials!.trim().isNotEmpty)
                          pw.Padding(padding: const pw.EdgeInsets.only(top: 1.5), child: pw.Text(doctor.credentials!.trim(), style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey700))),
                        if (doctor.bio != null && doctor.bio!.trim().isNotEmpty)
                          pw.Padding(padding: const pw.EdgeInsets.only(top: 2.5), child: pw.Text(doctor.bio!.trim(), style: pw.TextStyle(font: fontRegular, fontSize: 6.8, color: PdfColors.grey600))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: accentColor, thickness: 1.2),
        ]),
        footer: (ctx) => pw.Column(children: [
          pw.Divider(color: borderColor, thickness: 0.5),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (doctor.address != null) pw.Expanded(child: pw.Text(doctor.address!.trim(), style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey700))),
              if (doctor.licenseNumber != null && doctor.licenseNumber!.trim().isNotEmpty) 
                pw.Expanded(child: pw.Center(child: pw.Text('${L['license']}: ${doctor.licenseNumber!.trim()}', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: primaryColor)))),
              if (doctor.phone != null) pw.Expanded(child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('${L['phone']}: ${doctor.phone}', style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey700, fontFallback: [fontLatin])))),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (signatureImage != null) pw.Image(signatureImage, width: 70, height: 35, fit: pw.BoxFit.contain),
                  pw.Container(width: 100, height: 0.8, color: borderColor),
                  pw.SizedBox(height: 2),
                  pw.Text(L['signature']!, style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey700)),
                  pw.SizedBox(height: 4),
                  pw.Text('Rachita Medical System - 2026', style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey500)),
                ],
              ),
            ],
          ),
        ]),
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 45, vertical: 35),
          textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
        build: (ctx) => [
          pw.SizedBox(height: 5),
          // PATIENT INFO BAR
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.3),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _infoItem(L['patient']!, patient.name.trim(), fontBold, fontRegular, 10, fontLatin),
                if (patient.bloodGroup != null) _infoItem('فصيلة الدم', patient.bloodGroup!, fontBold, fontRegular, 10, fontLatin),
                if (patient.gender != null) _infoItem(L['gender']!, patient.gender == 'male' ? L['male']! : L['female']!, fontBold, fontRegular, 10, fontLatin),
                if (patient.age != null) _infoItem(L['age']!, '${patient.age}', fontBold, fontRegular, 10, fontLatin),
                _infoItem(L['date']!, formattedDate, fontBold, fontRegular, 9, fontLatin),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // VITAL SIGNS BAR (CLINICAL ACCURACY)
          _buildVitalsBar(L, prescription, patient, fontBold, fontRegular, fontLatin),
          pw.SizedBox(height: 15),

          // CLINICAL SUMMARY SECTION
          if ((patient.allergies?.isNotEmpty ?? false) || (patient.chronicDiseases?.isNotEmpty ?? false)) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: PdfColors.orange50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
              child: pw.Column(
                crossAxisAlignment: pw.TextDirection.rtl == (isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr) ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
                children: [
                  if (patient.chronicDiseases?.isNotEmpty ?? false)
                    pw.Text('الأمراض المزمنة: ${patient.chronicDiseases}', style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.orange900)),
                  if (patient.allergies?.isNotEmpty ?? false)
                    pw.Text('الحساسية والموانع: ${patient.allergies}', style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.red900)),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
          ],

          // DIAGNOSIS SECTION
          if (prescription.diagnosis.isNotEmpty && prescription.diagnosis != 'غير محدد') ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${L['diagnosis']} ', style: pw.TextStyle(font: fontBold, fontSize: 10, color: primaryColor)),
                pw.Expanded(child: pw.Text(prescription.diagnosis, style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.black, fontFallback: [fontLatin]))),
              ],
            ),
            pw.SizedBox(height: 15),
          ],
          
          // MEDICINES TABLE
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(3.4),  // Medicine
              1: const pw.FlexColumnWidth(1.2),  // Dosage
              2: const pw.FlexColumnWidth(1.2),  // Frequency
              3: const pw.FlexColumnWidth(1.2),  // Route
              4: const pw.FlexColumnWidth(1.1),  // Duration
              5: const pw.FlexColumnWidth(0.8),  // Qty
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                children: [
                  _headerCell(L['medicine']!, fontBold, alignLeft: true),
                  _headerCell(L['dosage']!, fontBold, center: true),
                  _headerCell(L['freq']!, fontBold, center: true),
                  _headerCell(L['route']!, fontBold, center: true),
                  _headerCell(L['duration']!, fontBold, center: true),
                  _headerCell(L['qty']!, fontBold, center: true),
                ],
              ),
              // Medication Rows
              ...prescription.medicines!.asMap().entries.map((entry) {
                final i = entry.key;
                final med = entry.value;
                final bool isEven = i % 2 == 0;
                final hasEnName = med.medicineNameEn != null && med.medicineNameEn!.trim().isNotEmpty;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isEven ? PdfColors.white : PdfColors.grey50,
                    border: const pw.Border(bottom: pw.BorderSide(color: borderColor, width: 0.3)),
                  ),
                  children: [
                    pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              hasEnName ? med.medicineNameEn!.trim() : med.medicineName.trim(), 
                              style: pw.TextStyle(font: fontBold, fontSize: 9, color: primaryColor, fontFallback: [fontLatin]),
                            ),
                            if (hasEnName) 
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 1),
                                child: pw.Text(
                                  med.medicineName.trim(), 
                                  style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.grey700),
                                  textDirection: pw.TextDirection.rtl,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    _cellText(med.dosage.trim(), fontRegular, center: true),
                    _cellText(med.frequency.trim(), fontRegular, center: true),
                    _cellText(med.routeOfAdmin ?? '-', fontRegular, center: true),
                    _cellText(med.duration.trim(), fontRegular, center: true),
                    _cellText(med.totalUnits?.toString() ?? '-', fontBold, center: true, color: accentColor),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildVitalsBar(Map<String, String> L, PrescriptionEntity rx, PatientEntity patient, pw.Font bold, pw.Font regular, pw.Font fallback) {
    int count = 0;
    if (rx.weight != null) count++;
    if (patient.height != null) count++;
    if (rx.systolic != null) count++;
    if (rx.sugar != null) count++;
    if (rx.pulse != null) count++;
    if (rx.temperature != null) count++;
    if (rx.extraVitals != null && rx.extraVitals!.isNotEmpty) count++;
    
    if (count == 0) return pw.SizedBox.shrink();

    Map<String, dynamic> extras = {};
    if (rx.extraVitals != null && rx.extraVitals!.isNotEmpty) {
      try { extras = Map<String, dynamic>.from(jsonDecode(rx.extraVitals!)); } catch (_) {}
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
      child: pw.Wrap(
        spacing: 15,
        runSpacing: 5,
        children: [
          if (rx.weight != null) _vNode(L['weight']!, '${rx.weight} kg', bold, regular, fallback),
          if (patient.height != null) _vNode(L['height']!, '${patient.height} cm', bold, regular, fallback),
          if (rx.systolic != null) _vNode(L['bp']!, '${rx.systolic}/${rx.diastolic ?? 0}', bold, regular, fallback),
          if (rx.sugar != null) _vNode(L['sugar']!, '${rx.sugar} mg/dL', bold, regular, fallback),
          if (rx.pulse != null) _vNode(L['pulse']!, '${rx.pulse} bpm', bold, regular, fallback),
          if (rx.temperature != null) _vNode(L['temp']!, '${rx.temperature} C', bold, regular, fallback),
          if (extras['va'] != null && extras['va'].toString().isNotEmpty) _vNode(L['va']!, '${extras['va']}', bold, regular, fallback),
          if (extras['iop'] != null && extras['iop'].toString().isNotEmpty) _vNode(L['iop']!, '${extras['iop']} mmHg', bold, regular, fallback),
          if (extras['head_circ'] != null && extras['head_circ'].toString().isNotEmpty) _vNode(L['head_circ']!, '${extras['head_circ']} cm', bold, regular, fallback),
        ],
      ),
    );
  }

  static pw.Widget _vNode(String label, String value, pw.Font bold, pw.Font regular, pw.Font fallback) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(label, style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(width: 2),
        pw.Text(value, style: pw.TextStyle(font: regular, fontSize: 8.5, color: PdfColors.black, fontFallback: [fallback])),
      ],
    );
  }

  static pw.Widget _headerCell(String text, pw.Font font, {bool alignLeft = false, bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: pw.Align(
          alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center, 
          child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8.5, color: PdfColors.white))
      ),
    );
  }

  static pw.Widget _cellText(String text, pw.Font font, {bool center = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Align(
          alignment: center ? pw.Alignment.center : pw.Alignment.centerLeft,
          child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8.5, color: color ?? PdfColors.grey900))
      ),
    );
  }

  static pw.Widget _infoItem(String label, String value, pw.Font bold, pw.Font regular, double size, pw.Font fallback) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('$label: ', style: pw.TextStyle(font: bold, fontSize: 8.5, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(font: regular, fontSize: size, color: PdfColors.black, fontFallback: [fallback])),
      ],
    );
  }
}
