import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand colour ramp ────────────────────────────────────────────────────────
class OC {
  // Primary orange (Soleil variant)
  static const o50  = Color(0xFFFFF6E8);
  static const o100 = Color(0xFFFCE9C7);
  static const o200 = Color(0xFFF8D399);
  static const o500 = Color(0xFFF59321);
  static const o600 = Color(0xFFE07A0C);
  static const o700 = Color(0xFFA85607);

  // Warm neutrals
  static const ink   = Color(0xFF1C1714);
  static const ink2  = Color(0xFF5B5048);
  static const muted = Color(0xFF978B80);
  static const faint = Color(0xFFC9BFB5);
  static const line  = Color(0xFFEFE8E1);
  static const line2 = Color(0xFFE4DACE);
  static const paper = Color(0xFFFFFFFF);
  static const bg    = Color(0xFFFAF6F1);
  static const panel = Color(0xFFF6F0EA);

  // Support
  static const wa      = Color(0xFF1FA855);
  static const waInk   = Color(0xFF0F7A3C);
  static const good    = Color(0xFF1E9E63);
  static const goodBg  = Color(0xFFE7F4EC);
  static const warn    = Color(0xFFC9781C);
  static const warnBg  = Color(0xFFFBEFDD);
  static const bad     = Color(0xFFD2462E);
  static const badBg   = Color(0xFFFBEAE5);
  static const blue    = Color(0xFF2D6CDF);
  static const blueBg  = Color(0xFFE7EEFB);

  // MTN / Orange Money
  static const mtn     = Color(0xFFFFCB05);
  static const orange  = Color(0xFFFF6600);

  // Dark hero
  static const darkHero  = Color(0xFF251C16);
  static const darkHero2 = Color(0xFF140F0B);

  static const LinearGradient grad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.52, 1.0],
    colors: [Color(0xFFFFB347), Color(0xFFF59321), Color(0xFFE07A0C)],
  );

  static const LinearGradient gradSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF6E8), Color(0xFFFCE9C7)],
  );
}

// ─── Typography ───────────────────────────────────────────────────────────────
TextStyle display(double size, {FontWeight weight = FontWeight.w700, Color? color}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: -0.02 * size,
      color: color ?? OC.ink,
      height: 1.08,
    );

TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color? color}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? OC.ink,
    );

TextStyle mono(double size, {FontWeight weight = FontWeight.w600, Color? color}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color ?? OC.ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

// ─── Theme ────────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: OC.o500,
      primary: OC.o500,
      onPrimary: Colors.white,
      surface: OC.paper,
      onSurface: OC.ink,
      surfaceContainerLowest: OC.bg,
    ),
    scaffoldBackgroundColor: OC.bg,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: OC.paper,
      foregroundColor: OC.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: body(17, weight: FontWeight.w700),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: OC.o500,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: body(14, weight: FontWeight.w700),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: OC.paper,
      selectedItemColor: OC.o600,
      unselectedItemColor: OC.muted,
      elevation: 0,
    ),
  );
}
