import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand colour ramp ────────────────────────────────────────────────────────
class OC {
  // Primary orange (Soleil variant) — constant dans les deux thèmes.
  static const o50  = Color(0xFFFFF6E8);
  static const o100 = Color(0xFFFCE9C7);
  static const o200 = Color(0xFFF8D399);
  static const o500 = Color(0xFFF59321);
  static const o600 = Color(0xFFE07A0C);
  static const o700 = Color(0xFFA85607);

  // ── Neutres « warm » : MUTABLES (basculés clair/sombre par applyBrightness) ─
  // Ne sont PAS `const` : la valeur dépend du thème courant.
  static Color ink   = _lInk;
  static Color ink2  = _lInk2;
  static Color muted = _lMuted;
  static Color faint = _lFaint;
  static Color line  = _lLine;
  static Color line2 = _lLine2;
  static Color paper = _lPaper;
  static Color bg    = _lBg;
  static Color panel = _lPanel;

  // Valeurs CLAIR
  static const _lInk   = Color(0xFF1C1714);
  static const _lInk2  = Color(0xFF5B5048);
  static const _lMuted = Color(0xFF978B80);
  static const _lFaint = Color(0xFFC9BFB5);
  static const _lLine  = Color(0xFFEFE8E1);
  static const _lLine2 = Color(0xFFE4DACE);
  static const _lPaper = Color(0xFFFFFFFF);
  static const _lBg    = Color(0xFFFAF6F1);
  static const _lPanel = Color(0xFFF6F0EA);

  // Valeurs SOMBRE (gardent la chaleur de la marque)
  static const _dInk   = Color(0xFFF4EEE7);
  static const _dInk2  = Color(0xFFC7BDB2);
  static const _dMuted = Color(0xFF998E83);
  static const _dFaint = Color(0xFF6E645A);
  static const _dLine  = Color(0xFF2E2720);
  static const _dLine2 = Color(0xFF3A322B);
  static const _dPaper = Color(0xFF1F1B17);
  static const _dBg    = Color(0xFF15120F);
  static const _dPanel = Color(0xFF2A231D);

  static bool isDark = false;

  /// Bascule les neutres selon la luminosité. À appeler avant le 1er build et
  /// à chaque changement de thème.
  static void applyBrightness(Brightness b) {
    final d = b == Brightness.dark;
    isDark = d;
    ink   = d ? _dInk   : _lInk;
    ink2  = d ? _dInk2  : _lInk2;
    muted = d ? _dMuted : _lMuted;
    faint = d ? _dFaint : _lFaint;
    line  = d ? _dLine  : _lLine;
    line2 = d ? _dLine2 : _lLine2;
    paper = d ? _dPaper : _lPaper;
    bg    = d ? _dBg    : _lBg;
    panel = d ? _dPanel : _lPanel;
  }

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
/// Construit le thème à partir des valeurs `OC` courantes (déjà basculées par
/// `OC.applyBrightness`). À reconstruire après chaque changement de thème.
ThemeData buildAppTheme() {
  final dark = OC.isDark;
  final brightness = dark ? Brightness.dark : Brightness.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: OC.o500,
      brightness: brightness,
      primary: OC.o500,
      onPrimary: Colors.white,
      surface: OC.paper,
      onSurface: OC.ink,
    ),
    scaffoldBackgroundColor: OC.bg,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData(brightness: brightness).textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: OC.paper,
      foregroundColor: OC.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
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
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: OC.paper,
      selectedItemColor: OC.o600,
      unselectedItemColor: OC.muted,
      elevation: 0,
    ),
  );
}
