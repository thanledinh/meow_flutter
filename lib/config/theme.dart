import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================
// A. Brand Colors
// ============================================
class MoewColors {
  // Brand — refined palette
  static const Color primary = Color(0xFF2563EB);     // Vivid Blue
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color secondary = Color(0xFFF59E0B);   // Warm Amber
  static const Color accent = Color(0xFF8B5CF6);      // Violet

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Neutral — richer grays
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFF1F5F9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textMain = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF334155);
  static const Color textSub = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Tints — softer, more harmonious
  static const Color tintBlue = Color(0xFFEFF6FF);
  static const Color tintAmber = Color(0xFFFEF3C7);
  static const Color tintPurple = Color(0xFFF5F3FF);
  static const Color tintGreen = Color(0xFFECFDF5);
  static const Color tintRed = Color(0xFFFEF2F2);
  static const Color tintYellow = Color(0xFFFEFCE8);
}

// ============================================
// B. Border Radius
// ============================================
class MoewRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double full = 999;
}

// ============================================
// C. Spacing
// ============================================
class MoewSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ============================================
// D. Shadows — layered for depth
// ============================================
class MoewShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
      offset: const Offset(0, 6),
      blurRadius: 24,
    ),
  ];

  static List<BoxShadow> elevated = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
      offset: const Offset(0, 4),
      blurRadius: 6,
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.1),
      offset: const Offset(0, 12),
      blurRadius: 32,
    ),
  ];

  static List<BoxShadow> button = [
    BoxShadow(
      color: MoewColors.primary.withValues(alpha: 0.25),
      offset: const Offset(0, 4),
      blurRadius: 14,
    ),
  ];

  static List<BoxShadow> buttonSecondary = [
    BoxShadow(
      color: MoewColors.secondary.withValues(alpha: 0.25),
      offset: const Offset(0, 4),
      blurRadius: 14,
    ),
  ];

  static List<BoxShadow> buttonAccent = [
    BoxShadow(
      color: MoewColors.accent.withValues(alpha: 0.25),
      offset: const Offset(0, 4),
      blurRadius: 14,
    ),
  ];

  static List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
      offset: const Offset(0, 2),
      blurRadius: 12,
    ),
  ];
}

// ============================================
// E. Typography — Inter font
// ============================================
class MoewTextStyles {
  static TextStyle h1 = GoogleFonts.inter(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: MoewColors.textMain, letterSpacing: -0.5, height: 1.2,
  );
  static TextStyle h2 = GoogleFonts.inter(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: MoewColors.textMain, letterSpacing: -0.3, height: 1.3,
  );
  static TextStyle h3 = GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: MoewColors.textMain, height: 1.3,
  );
  static TextStyle body = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: MoewColors.textBody, height: 1.5,
  );
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: MoewColors.textSub, height: 1.4,
  );
  static TextStyle label = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w600,
    color: MoewColors.textSub, letterSpacing: 0.8,
  );
  static TextStyle micro = GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: MoewColors.textSub,
  );
  static TextStyle button = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w700,
    color: MoewColors.white, letterSpacing: 0.3,
  );
}

// ============================================
// F. App Theme — comprehensive Material 3
// ============================================
class MoewTheme {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

    return base.copyWith(
      scaffoldBackgroundColor: MoewColors.background,
      colorScheme: const ColorScheme.light(
        primary: MoewColors.primary,
        onPrimary: MoewColors.white,
        secondary: MoewColors.secondary,
        tertiary: MoewColors.accent,
        surface: MoewColors.white,
        error: MoewColors.danger,
      ),

      // ── Text theme (Inter everywhere) ──
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: MoewTextStyles.h1,
        headlineMedium: MoewTextStyles.h2,
        headlineSmall: MoewTextStyles.h3,
        bodyLarge: MoewTextStyles.body,
        bodyMedium: MoewTextStyles.body,
        bodySmall: MoewTextStyles.caption,
        labelLarge: MoewTextStyles.button,
        labelSmall: MoewTextStyles.micro,
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: MoewColors.background,
        foregroundColor: MoewColors.textMain,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w800,
          color: MoewColors.textMain, letterSpacing: -0.3,
        ),
      ),

      // ── Bottom Nav ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MoewColors.white,
        selectedItemColor: MoewColors.primary,
        unselectedItemColor: MoewColors.textSub,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),

      // ── Input fields — polished look ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MoewColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoewRadius.sm),
          borderSide: const BorderSide(color: MoewColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoewRadius.sm),
          borderSide: const BorderSide(color: MoewColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoewRadius.sm),
          borderSide: const BorderSide(color: MoewColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoewRadius.sm),
          borderSide: const BorderSide(color: MoewColors.danger, width: 1),
        ),
        hintStyle: GoogleFonts.inter(color: MoewColors.textSub, fontSize: 15),
        labelStyle: GoogleFonts.inter(color: MoewColors.textSub, fontSize: 14, fontWeight: FontWeight.w500),
        prefixIconColor: MoewColors.textSub,
        suffixIconColor: MoewColors.textSub,
      ),

      // ── Elevated Button — bold, rounded, shadowed ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MoewColors.primary,
          foregroundColor: MoewColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.sm)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),

      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MoewColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: MoewColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.sm)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      // ── Text Button ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MoewColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.sm)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),

      // ── FloatingActionButton ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: MoewColors.primary,
        foregroundColor: MoewColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.md)),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        color: MoewColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.lg)),
        margin: EdgeInsets.zero,
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: MoewColors.white,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.xl)),
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: MoewColors.textMain),
        contentTextStyle: GoogleFonts.inter(fontSize: 15, color: MoewColors.textBody, height: 1.5),
      ),

      // ── BottomSheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: MoewColors.white,
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        showDragHandle: true,
        dragHandleColor: MoewColors.border,
        dragHandleSize: Size(40, 4),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: MoewColors.surface,
        selectedColor: MoewColors.tintBlue,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Tab ──
      tabBarTheme: TabBarThemeData(
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        indicatorColor: MoewColors.primary,
        labelColor: MoewColors.primary,
        unselectedLabelColor: MoewColors.textSub,
        dividerHeight: 0,
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MoewColors.textMain,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: MoewColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.sm)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(color: MoewColors.divider, thickness: 1, space: 1),

      // ── Dropdown ──
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: MoewColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(MoewRadius.sm), borderSide: const BorderSide(color: MoewColors.border)),
        ),
      ),

      // ── Page transitions — smooth ──
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
