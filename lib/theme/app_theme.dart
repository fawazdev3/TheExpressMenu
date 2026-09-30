import 'package:flutter/material.dart';

/// -----------------------------------------------------------------------------
/// THÈME DE L'APPLICATION
/// -----------------------------------------------------------------------------
/// Palette chaleureuse : terracotta en couleur principale, orange en accent,
/// fond crème pour mettre en valeur les cartes blanches.
/// Un seul endroit à modifier pour re-brander l'application avec les couleurs
/// réelles du restaurant.
/// -----------------------------------------------------------------------------
class AppTheme {
  const AppTheme._();

  /// Couleur principale : terre cuite (alignée sur le logo officiel).
  static const Color terracotta = Color(0xFFC05621);

  /// Nom de la famille de polices déclarée dans pubspec.yaml.
  static const String police = 'Poppins';

  /// Accent orange (badges, boutons secondaires).
  static const Color orange = Color(0xFFE8833A);

  /// Fond général, crème légèrement chaud.
  static const Color creme = Color(0xFFFFF8F2);

  /// Fond des encadrés informatifs (bandeaux, boutons d'ajout).
  static const Color cremeClair = Color(0xFFFDF1E7);

  /// Texte principal (brun très foncé plutôt que noir pur : plus chaleureux).
  static const Color encre = Color(0xFF2E1B12);

  /// Texte secondaire.
  static const Color grisChaud = Color(0xFF7A6A60);

  static ThemeData get light {
    final couleurs = ColorScheme.fromSeed(
      seedColor: terracotta,
      brightness: Brightness.light,
    ).copyWith(
      primary: terracotta,
      secondary: orange,
      surface: Colors.white,
      onSurface: encre,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: couleurs,

      // Poppins devient la police de TOUTE l'application : il suffit de la
      // déclarer ici, plus aucun Text n'a besoin de préciser `fontFamily`.
      // Les quatre graisses (Regular, Medium, SemiBold, Bold) sont declarées
      // dans pubspec.yaml et sont donc automatiquement utilisées selon le
      // `fontWeight` de chaque style.
      fontFamily: 'Poppins',

      scaffoldBackgroundColor: creme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: encre,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: encre,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEFE2D8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0D2C6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0D2C6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: terracotta, width: 1.6),
        ),
        labelStyle: const TextStyle(fontFamily: police, color: grisChaud),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: terracotta,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // `fontFamily` est indispensable : un TextStyle fourni ici REMPLACE
          // le style ambiant, donc sans lui le libellé du bouton retomberait sur
          // la police du système (Roboto / San Francisco) au lieu de Poppins.
          textStyle: const TextStyle(
            fontFamily: police,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: terracotta,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: terracotta),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: police,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: encre,
        contentTextStyle: TextStyle(fontFamily: police, color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFF0E5DC), space: 1),
    );
  }
}
