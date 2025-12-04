import 'package:flutter/material.dart';

/// App-wide theme configuration using Material Design 3
/// Study-focused design with calming colors and clear visual hierarchy
class AppTheme {
  // Color Scheme - Study-friendly palette with better readability
  // Primary: Deep indigo-blue for clarity and professionalism
  static const Color primaryColor = Color(0xFF4A5568); // Slate gray-blue
  static const Color primaryLightColor = Color(0xFF718096);
  static const Color primaryDarkColor = Color(0xFF2D3748);
  static const Color primarySurfaceColor = Color(0xFFF7FAFC);

  // Secondary: Rich navy for contrast
  static const Color secondaryColor = Color(0xFF1A365D); // Deep navy
  static const Color secondaryLightColor = Color(0xFF2C5282);
  static const Color secondaryDarkColor = Color(0xFF0D2137);

  // Accent: Vibrant blue for CTAs and highlights
  static const Color accentColor = Color(0xFF3182CE); // Bright blue
  static const Color accentLightColor = Color(0xFF63B3ED);

  // Semantic Colors - Clear and accessible
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color errorLightColor = Color(0xFFFED7D7);
  static const Color successColor = Color(0xFF38A169);
  static const Color successLightColor = Color(0xFFC6F6D5);
  static const Color warningColor = Color(0xFFD69E2E);
  static const Color warningLightColor = Color(0xFFFEFCBF);
  static const Color infoColor = Color(0xFF3182CE);
  static const Color infoLightColor = Color(0xFFBEE3F8);

  // Background Colors - Clean and bright
  static const Color backgroundColor = Color(0xFFF7FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color scaffoldGradientStart = Color(0xFFEDF2F7);
  static const Color scaffoldGradientEnd = Color(0xFFF7FAFC);

  // Text Colors - Enhanced readability
  static const Color textPrimaryColor = Color(0xFF2D3748);
  static const Color textSecondaryColor = Color(0xFF718096);
  static const Color textDisabledColor = Color(0xFFA0AEC0);
  static const Color textOnPrimaryColor = Color(0xFFFFFFFF);
  static const Color textMutedColor = Color(0xFF9CA3AF);

  // Border Colors - Subtle and refined
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color dividerColor = Color(0xFFEDF2F7);
  static const Color cardBorderColor = Color(0xFFE8ECF0);

  // Role-Specific Colors
  static const Color instructorColor = Color(0xFF2C5282);
  static const Color studentColor = Color(0xFF38A169);

  // Status Colors - Clear visual feedback
  static const Color statusNotSubmitted = Color(0xFFE6A23C);
  static const Color statusSubmitted = Color(0xFF5B9BD5);
  static const Color statusGraded = Color(0xFF4CAF7D);
  static const Color statusLate = Color(0xFFD45B5B);
  static const Color statusPending = Color(0xFFBDA06D);

  // Study-themed accent colors
  static const Color bookColor = Color(0xFF8B6F47);
  static const Color noteColor = Color(0xFFFFF8DC);
  static const Color highlightColor = Color(0xFFFFF59D);

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primarySurfaceColor,
        secondary: secondaryColor,
        secondaryContainer: secondaryLightColor,
        tertiary: accentColor,
        error: errorColor,
        surface: surfaceColor,
        onPrimary: textOnPrimaryColor,
        onSecondary: textOnPrimaryColor,
        onSurface: textPrimaryColor,
        onError: textOnPrimaryColor,
        outline: borderColor,
      ),

      // App Bar Theme - Clean and modern
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: primaryColor),
        surfaceTintColor: Colors.transparent,
      ),

      // Card Theme - Subtle shadows and refined borders
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorderColor, width: 1),
        ),
        margin: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        surfaceTintColor: Colors.transparent,
      ),

      // Elevated Button Theme - Polished and modern
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimaryColor,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.1)),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme - Clean and focused
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF7FAFC),
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: TextStyle(color: textSecondaryColor, fontSize: 14),
        hintStyle: TextStyle(color: textDisabledColor, fontSize: 14),
        errorStyle: TextStyle(color: errorColor, fontSize: 12),
        prefixIconColor: textSecondaryColor,
        suffixIconColor: textSecondaryColor,
      ),

      // Floating Action Button Theme - Elevated and inviting
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: textOnPrimaryColor,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip Theme - Soft and readable
      chipTheme: ChipThemeData(
        backgroundColor: primarySurfaceColor,
        selectedColor: primaryLightColor,
        deleteIconColor: textSecondaryColor,
        labelStyle: TextStyle(color: textPrimaryColor, fontSize: 13),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),

      // Dialog Theme - Clean and focused
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        contentTextStyle: TextStyle(
          color: textSecondaryColor,
          fontSize: 15,
          height: 1.5,
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textMutedColor,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primarySurfaceColor,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: textMutedColor,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: 24);
          }
          return IconThemeData(color: textMutedColor, size: 24);
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // Drawer Theme
      drawerTheme: DrawerThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.transparent,
        selectedTileColor: primarySurfaceColor,
        textColor: textPrimaryColor,
        iconColor: textSecondaryColor,
        minLeadingWidth: 24,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 24,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        circularTrackColor: primarySurfaceColor,
        linearTrackColor: primarySurfaceColor,
      ),

      // Snack Bar Theme - Polished notifications
      snackBarTheme: SnackBarThemeData(
        backgroundColor: secondaryColor,
        contentTextStyle: TextStyle(
          color: textOnPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: accentLightColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textMutedColor,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryColor, width: 3),
          borderRadius: BorderRadius.circular(3),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),

      // Text Theme - Improved typography with better hierarchy
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: textPrimaryColor,
          letterSpacing: -1.0,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
          letterSpacing: -0.5,
          height: 1.25,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
          letterSpacing: -0.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          letterSpacing: -0.1,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimaryColor,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimaryColor,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: textSecondaryColor,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          letterSpacing: 0.2,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          letterSpacing: 0.3,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textSecondaryColor,
          letterSpacing: 0.3,
        ),
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: textSecondaryColor,
        size: 24,
      ),

      // Scaffold Background Color
      scaffoldBackgroundColor: backgroundColor,
    );
  }

  // Dark Theme (optional but good to have)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryLightColor,
        primaryContainer: primaryColor,
        secondary: secondaryLightColor,
        secondaryContainer: secondaryColor,
        error: errorColor,
        surface: Color(0xFF1E1E1E),
        onPrimary: Color(0xFF000000),
        onSecondary: Color(0xFF000000),
        onSurface: Color(0xFFE0E0E0),
        onError: textOnPrimaryColor,
      ),
      scaffoldBackgroundColor: Color(0xFF121212),
    );
  }

  // Helper methods for consistent spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;
  static const double radiusCircular = 999.0;

  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;

  // Card Decorations for enhanced UI
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(radiusXL),
        border: Border.all(color: cardBorderColor, width: 1),
      );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration gradientCardDecoration(Color color) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(radiusXL),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // Gradient backgrounds
  static LinearGradient get scaffoldGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [scaffoldGradientStart, scaffoldGradientEnd],
      );

  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor, primaryDarkColor],
      );

  static LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accentColor, Color(0xFFD4694A)],
      );

  // Status badge decoration
  static BoxDecoration statusBadgeDecoration(Color color) => BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(radiusS),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      );

  // Icon container decoration
  static BoxDecoration iconContainerDecoration(Color color) => BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusL),
      );
}
