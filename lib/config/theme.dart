import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================
// A. Brand Colors
// ============================================
class MoewColors {
  // Brand — mutable runtime values
  static Color primary = Color(0xFFE8628A);     // Sakura (default)
  static Color primaryDark = Color(0xFFC2476D);
  static Color accent = Color(0xFFF4A7BE);
  static Color secondary = Color(0xFFF59E0B);

  // Semantic
  static Color success = Color(0xFF10B981);
  static Color danger = Color(0xFFEF4444);
  static Color warning = Color(0xFFF59E0B);
  static Color info = Color(0xFF3B82F6);

  // Neutral — dynamic based on preset
  static Color background = Color(0xFFFFF8FA);
  static Color surface = Color(0xFFFEF0F4);
  static Color white = Color(0xFFFFFFFF);
  static Color textMain = Color(0xFF2D1B25);
  static Color textBody = Color(0xFF5C3D4A);
  static Color textSub = Color(0xFFB08090);
  static Color border = Color(0xFFF2D5DE);
  static Color divider = Color(0xFFF2D5DE);

  // Tints
  static Color tintBlue = Color(0xFFEFF6FF);
  static Color tintAmber = Color(0xFFFEF3C7);
  static Color tintPurple = Color(0xFFF5F3FF);
  static Color tintGreen = Color(0xFFECFDF5);
  static Color tintRed = Color(0xFFFEF2F2);
  static Color tintYellow = Color(0xFFFEFCE8);

  static void applyPreset(String preset) {
    if (preset == 'sakura') {
      primary = Color(0xFFE8628A);
      primaryDark = Color(0xFFC2476D);
      accent = Color(0xFFF4A7BE);
      background = Color(0xFFFFF8FA);
      surface = Color(0xFFFEF0F4);
      textMain = Color(0xFF2D1B25);
      textBody = Color(0xFF5C3D4A);
      textSub = Color(0xFFB08090);
      border = Color(0xFFF2D5DE);
      divider = border;
    } else if (preset == 'lavender') {
      primary = Color(0xFF7C6CD6);
      primaryDark = Color(0xFF5B4AB5);
      accent = Color(0xFFC4B8F0);
      background = Color(0xFFF8F7FF);
      surface = Color(0xFFEFECFB);
      textMain = Color(0xFF1E1B33);
      textBody = Color(0xFF4A4568);
      textSub = Color(0xFF9E9BB8);
      border = Color(0xFFD9D5F0);
      divider = border;
    } else if (preset == 'peach') {
      primary = Color(0xFFE8844A);
      primaryDark = Color(0xFFC4612A);
      accent = Color(0xFFFDBA8C);
      background = Color(0xFFFFFAF7);
      surface = Color(0xFFFEF0E6);
      textMain = Color(0xFF2C1A0E);
      textBody = Color(0xFF5C3D25);
      textSub = Color(0xFFB09080);
      border = Color(0xFFF5D5BC);
      divider = border;
    } else if (preset == 'sage') {
      primary = Color(0xFF4A9B7F);
      primaryDark = Color(0xFF2D7A5F);
      accent = Color(0xFFA8D5C2);
      background = Color(0xFFF6FDFB);
      surface = Color(0xFFE8F6F1);
      textMain = Color(0xFF0D2419);
      textBody = Color(0xFF2E5044);
      textSub = Color(0xFF7FA899);
      border = Color(0xFFC2E5D8);
      divider = border;
    } else if (preset == 'midnight') {
      primary = Color(0xFFA78BFA);
      primaryDark = Color(0xFF7C5FD4);
      accent = Color(0xFFF472B6);
      background = Color(0xFF0F0F1A);
      surface = Color(0xFF1A1A2E);
      textMain = Color(0xFFF0EEFF);
      textBody = Color(0xFFC4BDE8);
      textSub = Color(0xFF6B6490);
      border = Color(0xFF2A2645);
      divider = border;
    }
  }
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
      color: Color(0xFF0F172A).withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0xFF0F172A).withValues(alpha: 0.06),
      offset: const Offset(0, 6),
      blurRadius: 24,
    ),
  ];

  static List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0xFF0F172A).withValues(alpha: 0.06),
      offset: const Offset(0, 4),
      blurRadius: 6,
    ),
    BoxShadow(
      color: Color(0xFF0F172A).withValues(alpha: 0.1),
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
      color: Color(0xFF0F172A).withValues(alpha: 0.03),
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
  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);

    return base.copyWith(
      scaffoldBackgroundColor: Color(0xFF0F0F1A),
      colorScheme: ColorScheme.dark(
        primary: MoewColors.primary,
        onPrimary: MoewColors.white,
        secondary: MoewColors.secondary,
        tertiary: MoewColors.accent,
        surface: Color(0xFF1A1A2E),
        error: MoewColors.danger,
      ),

      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: MoewTextStyles.h1.copyWith(color: Color(0xFFF0EEFF)),
        headlineMedium: MoewTextStyles.h2.copyWith(color: Color(0xFFF0EEFF)),
        headlineSmall: MoewTextStyles.h3.copyWith(color: Color(0xFFF0EEFF)),
        bodyLarge: MoewTextStyles.body.copyWith(color: Color(0xFFC4BDE8)),
        bodyMedium: MoewTextStyles.body.copyWith(color: Color(0xFFC4BDE8)),
        bodySmall: MoewTextStyles.caption.copyWith(color: Color(0xFF6B6490)),
        labelLarge: MoewTextStyles.button.copyWith(color: Colors.white),
        labelSmall: MoewTextStyles.micro.copyWith(color: Color(0xFF6B6490)),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF0F0F1A),
        foregroundColor: Color(0xFFF0EEFF),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w800,
          color: Color(0xFFF0EEFF), letterSpacing: -0.3,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A2E),
        selectedItemColor: MoewColors.primary,
        unselectedItemColor: Color(0xFF6B6490),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1A1A2E),
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoewRadius.sm),
          borderSide: BorderSide(color: Color(0xFF2A2645), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoewRadius.sm),
          borderSide: BorderSide(color: Color(0xFF2A2645), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoewRadius.sm),
          borderSide: BorderSide(color: MoewColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoewRadius.sm),
          borderSide: BorderSide(color: MoewColors.danger, width: 1),
        ),
        hintStyle: GoogleFonts.inter(color: Color(0xFF6B6490), fontSize: 15),
        labelStyle: GoogleFonts.inter(color: Color(0xFF6B6490), fontSize: 14, fontWeight: FontWeight.w500),
        prefixIconColor: Color(0xFF6B6490),
        suffixIconColor: Color(0xFF6B6490),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MoewColors.primary,
          foregroundColor: MoewColors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.sm)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MoewColors.primary,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(color: MoewColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.sm)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MoewColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.sm)),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: MoewColors.primary,
        foregroundColor: MoewColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.md)),
      ),

      cardTheme: CardThemeData(
        color: Color(0xFF1A1A2E), // Surface
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.lg)),
        margin: EdgeInsets.zero,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Color(0xFF1A1A2E),
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.xl)),
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFF0EEFF)),
        contentTextStyle: GoogleFonts.inter(fontSize: 15, color: Color(0xFFC4BDE8), height: 1.5),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Color(0xFF1A1A2E),
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        showDragHandle: true,
        dragHandleColor: Color(0xFF2A2645),
        dragHandleSize: Size(40, 4),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFF2A2645),
        selectedColor: MoewColors.primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFF0EEFF)),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      tabBarTheme: TabBarThemeData(
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        indicatorColor: MoewColors.primary,
        labelColor: MoewColors.primary,
        unselectedLabelColor: Color(0xFF6B6490),
        dividerHeight: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFFF0EEFF),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F0F1A)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.sm)),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: DividerThemeData(color: Color(0xFF2A2645), thickness: 1, space: 1),

      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1A1A2E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(MoewRadius.sm), borderSide: BorderSide(color: Color(0xFF2A2645))),
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

    return base.copyWith(
      scaffoldBackgroundColor: MoewColors.background,
      colorScheme: ColorScheme.light(
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
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
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
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoewRadius.sm),
          borderSide: BorderSide(color: MoewColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoewRadius.sm),
          borderSide: BorderSide(color: MoewColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoewRadius.sm),
          borderSide: BorderSide(color: MoewColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoewRadius.sm),
          borderSide: BorderSide(color: MoewColors.danger, width: 1),
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
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.sm)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),

      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MoewColors.primary,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(color: MoewColors.primary, width: 1.5),
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
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
      bottomSheetTheme: BottomSheetThemeData(
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
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      dividerTheme: DividerThemeData(color: MoewColors.divider, thickness: 1, space: 1),

      // ── Dropdown ──
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: MoewColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(MoewRadius.sm), borderSide: BorderSide(color: MoewColors.border)),
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
