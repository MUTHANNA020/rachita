import 'package:flutter/material.dart';
import '../../../domain/entities/prescription_entity.dart';

abstract class SpecialtyModule extends StatelessWidget {
  final PrescriptionEntity? lastPrescription;
  final Map<String, TextEditingController> controllers;
  final VoidCallback onChanged;

  const SpecialtyModule({
    super.key,
    required this.lastPrescription,
    required this.controllers,
    required this.onChanged,
  });

  String get specialtyName;
  IconData get icon;
}
