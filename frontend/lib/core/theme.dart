import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ParkFlow design system — futuristic offline-first smart parking palette.
class PFColors {
  PFColors._();

  // Brand greens (signal + glow).
  static const Color brand = Color(0xFF22C55E);
  static const Color brandStrong = Color(0xFF15803D);
  static const Color brandSoft = Color(0xFFD1FAE5);
  static const Color brandGlow = Color(0xFF34D399);

  // Slot semantic colors.
  static const Color slotAvailable = Color(0xFF22C55E);
  static const Color slotOccupied = Color(0xFFEF4444);
  static const Color slotReserved = Color(0xFF3B82F6);
  static const Color slotSelected = Color(0xFFA78BFA);
  static const Color slotDisabled = Color(0xFF6B7280);

  // Light surfaces.
  static const Color lightBg = Color(0xFFF7FAF8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOutline = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Dark surfaces.
  static const Color darkBg = Color(0xFF050B0A);
  static const Color darkSurface = Color(0xFF0C1614);
  static const Color darkSurfaceAlt = Color(0xFF121F1C);
  static const Color darkOutline = Color(0xFF1F2D29);
  static const Color darkTextPrimary = Color(0xFFE7FBF1);
  static const Color darkTextMuted = Color(0xFF8FA8A0);

  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);
}

class PFRadii {
  PFRadii._();
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 999;
}

class PFSpacing {
  PFSpacing._();
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class PFShadows {
  PFShadows._();

  static List<BoxShadow> soft(Brightness b) => b == Brightness.dark
      ? const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ];

  static List<BoxShadow> glow(Color color, {double opacity = 0.45}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 28,
          spreadRadius: 1,
          offset: const Offset(0, 8),
        ),
      ];
}

class PFTheme {
  PFTheme._();

  // No custom fontFamily is set: the app uses the native system font
  // (SF Pro on iOS, Roboto on Android) — the HIG-correct default.

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color bg = isDark ? PFColors.darkBg : PFColors.lightBg;
    final Color surface = isDark ? PFColors.darkSurface : PFColors.lightSurface;
    final Color text = isDark ? PFColors.darkTextPrimary : PFColors.lightTextPrimary;
    final Color muted = isDark ? PFColors.darkTextMuted : PFColors.lightTextMuted;
    final Color outline = isDark ? PFColors.darkOutline : PFColors.lightOutline;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: PFColors.brand,
      onPrimary: Colors.white,
      secondary: PFColors.brandGlow,
      onSecondary: Colors.black,
      tertiary: PFColors.info,
      onTertiary: Colors.white,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest:
          isDark ? PFColors.darkSurfaceAlt : const Color(0xFFEFF5F1),
      onSurfaceVariant: muted,
      outline: outline,
      outlineVariant: outline,
      error: PFColors.danger,
      onError: Colors.white,
    );

    final TextTheme textTheme = const TextTheme(
      displayLarge: TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.05,
      ),
      displayMedium: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ).apply(bodyColor: text, displayColor: text);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(
            allowEnterRouteSnapshotting: false,
          ),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              ),
      ),
      iconTheme: IconThemeData(color: text, size: 22),
      dividerColor: outline,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PFRadii.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? PFColors.darkSurfaceAlt : const Color(0xFFEFF5F1),
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PFRadii.md),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PFRadii.md),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PFRadii.md),
          borderSide: const BorderSide(color: PFColors.brand, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: PFColors.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PFRadii.md),
          ),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: outline),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PFRadii.md),
          ),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PFColors.brand,
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: text),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PFRadii.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(PFRadii.xl)),
        ),
      ),
    );
  }
}
