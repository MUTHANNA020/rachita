import 'package:flutter/material.dart';

class SecurityWrapper extends StatelessWidget {
  final Widget child;
  const SecurityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Disabled security: always return child directly
    return child;
  }
}
