import 'package:flutter/material.dart';

class AppColors {
  // ═══════════════════════════════════════════════════════
  // 🏥 CLINICAL BLUE & TEAL — PROFESSIONAL MEDICAL SUITE
  // ═══════════════════════════════════════════════════════

  // Primary — Deep Professional Medical Blue (Trust & Authority)
  static const Color primary       = Color(0xFF0A4B8F); // Richer, darker blue
  static const Color primaryDark   = Color(0xFF063366); 
  static const Color primaryLight  = Color(0xFFEBF3FB); 

  // Secondary — Clinical Clean Teal (Precision & Calm)
  static const Color secondary      = Color(0xFF0D9488); // Teal
  static const Color secondaryDark  = Color(0xFF0F766E);
  static const Color secondaryLight = Color(0xFFEAF5F4);

  // ── Surface Architecture (Light & Clean) ───────────
  static const Color background    = Color(0xFFF7F9FC); // Medical crisp off-white
  static const Color surface       = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceVariant = Color(0xFFEEF2F6); 
  static const Color cardBg        = Color(0xFFFFFFFF);

  // ── Dark Mode Architecture ────────────────────────
  static const Color darkBackground = Color(0xFF0F172A); // Deep Slate Blue-Black
  static const Color darkSurface    = Color(0xFF1E293B); // Slate Blue
  static const Color darkBorder     = Color(0xFF334155);
  static const Color darkDivider    = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);

  // ── Precision Typography ──────────────────────────────
  static const Color textPrimary   = Color(0xFF1E293B); // Very dark slate blue for text
  static const Color textSecondary = Color(0xFF475569); 
  static const Color textMuted     = Color(0xFF94A3B8); 

  // ── Status Tokens (Strict UI Signals) ─────────────────
  static const Color success       = Color(0xFF0D9488); // Treat success as Teal instead of generic green
  static const Color warning       = Color(0xFFD97706); // Amber for warnings
  static const Color error         = Color(0xFFDC2626); // Bright red for critical clinical alerts
  static const Color accent        = Color(0xFFDC2626); // Accent aligns with critical action

  // ── Borders & Dividers ─────────────────────────────
  static const Color border        = Color(0xFFE2E8F0); 
  static const Color divider       = Color(0xFFF1F5F9);
  static const Color glassBorder   = Color(0x1F1E293B);

  // ── Modern Professional Gradients ──────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0A4B8F), Color(0xFF063366)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F9FC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Legacy compatibility getters
  static Color get primaryGlow => primary.withOpacity(0.08);
  static Color get primaryMid => primary.withOpacity(0.5);
  static const Color gold = warning; // Legacy mappings
}
