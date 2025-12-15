// lib/core/theme/app_themes.dart
import 'package:flutter/material.dart';

// =============================================================================
// APP THEME MODEL
// =============================================================================
class AppTheme {
  final String name;
  final String description;
  final Color primary;
  final Color primaryVariant;
  final Color secondary;
  final Color accent;
  final Color lightBackground;
  final Color darkBackground;
  final Color success;
  final Color warning;
  final Color error;
  final bool isRecommended;
  final bool isPremium;
  final ThemeMode themeMode;

  AppTheme({
    required this.name,
    required this.description,
    required this.primary,
    required this.primaryVariant,
    required this.secondary,
    required this.accent,
    required this.lightBackground,
    required this.darkBackground,
    required this.success,
    required this.warning,
    required this.error,
    this.isRecommended = false,
    this.isPremium = false,
    this.themeMode = ThemeMode.light,
  });

  AppTheme copyWith({
    String? name,
    String? description,
    Color? primary,
    Color? primaryVariant,
    Color? secondary,
    Color? accent,
    Color? lightBackground,
    Color? darkBackground,
    Color? success,
    Color? warning,
    Color? error,
    bool? isRecommended,
    bool? isPremium,
    ThemeMode? themeMode,
  }) {
    return AppTheme(
      name: name ?? this.name,
      description: description ?? this.description,
      primary: primary ?? this.primary,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      lightBackground: lightBackground ?? this.lightBackground,
      darkBackground: darkBackground ?? this.darkBackground,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      isRecommended: isRecommended ?? this.isRecommended,
      isPremium: isPremium ?? this.isPremium,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  // Helper colors derived from theme colors ================
  // Background Colors

  Color get textLight => const Color(0xFF161616);
  Color get textDark => const Color(0xFFFEF8E8);
  Color get textSecondary => const Color(0xFFE4E2E3);

  Color get buttonBackground => primary; // Orange
  Color get buttonText => lightBackground; // Silver
  Color get buttonSecondary => stone; // Stone

  Color get grey => const Color(0xFFE4E2E3);
  Color get stone => const Color(0xFFA8AAAC);
  Color get cardLight => secondary;
  Color get cardDark => const Color(0xFF2A2A2A);
  Color get purple => const Color(0xFF9C27B0);
  Color get greenTeal => const Color(0xFF009688);
  // ========================================================

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: stone,
        surface: secondary,
        onPrimary: secondary,
        onSecondary: textLight,
        onSurface: textLight,
      ),
      primaryColor: primary,
      scaffoldBackgroundColor: lightBackground,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: secondary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 4,
        shadowColor: grey.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(8),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error, width: 2),
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7)),
      ),

      // Text Theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textLight,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textLight,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textLight,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textLight,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: textLight, fontSize: 16),
        bodyMedium: TextStyle(color: textLight, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
      ),

      // FloatingActionButton Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // IconButton Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: primary),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: secondary,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: textLight),
        secondaryLabelStyle: TextStyle(color: textLight),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: lightBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // BottomSheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: lightBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 8,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: grey.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),

      // ProgressIndicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: grey.withValues(alpha: 0.3),
        circularTrackColor: grey.withValues(alpha: 0.3),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.5);
          }
          return grey.withValues(alpha: 0.3);
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return grey;
        }),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: grey.withValues(alpha: 0.3),
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.2),
        valueIndicatorColor: primary,
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),

      // TabBar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textLight,
        contentTextStyle: TextStyle(color: textDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textLight,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: textDark),
      ),

      // ListTile Theme
      listTileTheme: ListTileThemeData(
        selectedColor: primary,
        iconColor: textSecondary,
        textColor: textLight,
      ),
    );
  }

  //==================================================
  // DARK THEME
  // =================================================

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: stone,
        surface: const Color(0xFF1E1E1E),
        onPrimary: textLight,
        onSecondary: secondary,
        onSurface: secondary,
      ),
      primaryColor: primary,
      scaffoldBackgroundColor: darkBackground,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: secondary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(8),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: stone),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: stone),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error, width: 2),
        ),
        labelStyle: TextStyle(color: stone),
        hintStyle: TextStyle(color: stone.withValues(alpha: 0.7)),
      ),

      // Text Theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textDark,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textDark,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textDark,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: textDark, fontSize: 16),
        bodyMedium: TextStyle(color: textDark, fontSize: 14),
        bodySmall: TextStyle(color: stone, fontSize: 12),
      ),

      // FloatingActionButton Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // IconButton Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: primary),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: cardDark,
        selectedColor: primary.withValues(alpha: 0.3),
        labelStyle: TextStyle(color: textDark),
        secondaryLabelStyle: TextStyle(color: textDark),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // BottomSheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 8,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: stone.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),

      // ProgressIndicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: stone.withValues(alpha: 0.3),
        circularTrackColor: stone.withValues(alpha: 0.3),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return stone;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.5);
          }
          return stone.withValues(alpha: 0.3);
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return stone;
        }),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: stone.withValues(alpha: 0.3),
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.2),
        valueIndicatorColor: primary,
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),

      // TabBar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: stone,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardDark,
        contentTextStyle: TextStyle(color: textDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: textDark),
      ),

      // ListTile Theme
      listTileTheme: ListTileThemeData(
        selectedColor: primary,
        iconColor: stone,
        textColor: textDark,
      ),
    );
  }
}

class ThemeNames {
  static const String energeticOrange = "Energetic Orange";
  static const String calmBlue = "Calm Blue";
  static const String naturalGreen = "Natural Green";
  static const String royalPurple = "Royal Purple";
  static const String sunsetCoral = "Sunset Coral";
  static const String midnightIndigo = "Midnight Indigo";
  static const String amberGold = "Amber Gold";
  static const String tealOcean = "Teal Ocean";
  static const String rosePink = "Rose Pink";
  static const String slateGray = "Slate Gray";
  static const String defaultTheme = "Default";
}

class ThemeDescriptions {
  static const String energeticOrange =
      "Bold & energizing for focused study sessions";
  static const String calmBlue = "Promotes focus, trust, and retention";
  static const String naturalGreen =
      "Balanced & easy on the eyes for long sessions";
  static const String royalPurple = "Inspiring creativity and luxury feel";
  static const String sunsetCoral = "Warm & friendly for comfortable learning";
  static const String midnightIndigo = "Deep focus for serious study";
  static const String amberGold = "Optimistic & energizing warmth";
  static const String tealOcean = "Fresh & balanced for steady learning";
  static const String rosePink = "Gentle & nurturing learning environment";
  static const String slateGray = "Minimal distractions, pure focus";
  static const String defaultTheme = "Default";
}

// =============================================================================
// THEME 1: ENERGETIC ORANGE (Current - High Energy & Focus)
// =============================================================================
class EnergeticOrangeThemeColors {
  static const Color primary = Color(0xFFF44A22); // Vibrant Orange
  static const Color primaryVariant = Color(0xFFE03E1A);
  static const Color secondary = Color(0xFFFEF8E8); // Warm Cream
  static const Color accent = Color(0xFFF44A22);
  static const Color lightBackground = Color(0xFFFEF8E8);
  static const Color darkBackground = Color(0xFF161616);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);

  // static const String name = "Energetic Orange";
  // static const String description =
  //     "Bold & energizing for focused study sessions";
}

class EnergeticOrangeTheme extends AppTheme {
  // Psychological Impact: Stimulates creativity, energy, and enthusiasm
  // Best for: Short, intense study sessions and creative subjects
  EnergeticOrangeTheme()
    : super(
        name: ThemeNames.energeticOrange,
        description: ThemeDescriptions.energeticOrange,
        primary: EnergeticOrangeThemeColors.primary,
        primaryVariant: EnergeticOrangeThemeColors.primaryVariant,
        secondary: EnergeticOrangeThemeColors.secondary,
        accent: EnergeticOrangeThemeColors.accent,
        lightBackground: EnergeticOrangeThemeColors.lightBackground,
        darkBackground: EnergeticOrangeThemeColors.darkBackground,
        success: EnergeticOrangeThemeColors.success,
        warning: EnergeticOrangeThemeColors.warning,
        error: EnergeticOrangeThemeColors.error,
      );
}

// =============================================================================
// THEME 2: CALM BLUE (RECOMMENDED DEFAULT - Best for Learning)
// =============================================================================
class CalmBlueThemeColors {
  static const Color primary = Color(0xFF2196F3); // Trust Blue
  static const Color primaryVariant = Color(0xFF1976D2);
  static const Color secondary = Color(0xFFE3F2FD); // Light Blue
  static const Color accent = Color(0xFF03A9F4);

  static const Color lightBackground = Color(0xFFF5F9FC);
  static const Color darkBackground = Color(0xFF0D1B2A);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
}

class CalmBlueTheme extends AppTheme {
  // Psychological Impact: Enhances concentration, reduces stress, improves memory
  // Best for: Long study sessions, memorization, and analytical thinking
  // ⭐ RECOMMENDED DEFAULT - Scientifically proven to enhance learning

  CalmBlueTheme()
    : super(
        name: ThemeNames.calmBlue,
        description: ThemeDescriptions.calmBlue,
        primary: CalmBlueThemeColors.primary,
        primaryVariant: CalmBlueThemeColors.primaryVariant,
        secondary: CalmBlueThemeColors.secondary,
        accent: CalmBlueThemeColors.accent,
        lightBackground: CalmBlueThemeColors.lightBackground,
        darkBackground: CalmBlueThemeColors.darkBackground,
        success: CalmBlueThemeColors.success,
        warning: CalmBlueThemeColors.warning,
        error: CalmBlueThemeColors.error,
        isRecommended: true,
      );
}

// =============================================================================
// THEME 3: NATURAL GREEN (Balanced & Refreshing)
// =============================================================================
class NaturalGreenThemeColors {
  static const Color primary = Color(0xFF4CAF50); // Fresh Green
  static const Color primaryVariant = Color(0xFF388E3C);
  static const Color secondary = Color(0xFFE8F5E9); // Mint Cream
  static const Color accent = Color(0xFF66BB6A);

  static const Color lightBackground = Color(0xFFF1F8F4);
  static const Color darkBackground = Color(0xFF1A1F1E);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
}

class NaturalGreenTheme extends AppTheme {
  // Psychological Impact: Reduces eye strain, promotes balance and harmony
  // Best for: Extended study periods, reading-heavy subjects
  NaturalGreenTheme()
    : super(
        name: ThemeNames.naturalGreen,
        description: ThemeDescriptions.naturalGreen,
        primary: NaturalGreenThemeColors.primary,
        primaryVariant: NaturalGreenThemeColors.primaryVariant,
        secondary: NaturalGreenThemeColors.secondary,
        accent: NaturalGreenThemeColors.accent,
        lightBackground: NaturalGreenThemeColors.lightBackground,
        darkBackground: NaturalGreenThemeColors.darkBackground,
        success: NaturalGreenThemeColors.success,
        warning: NaturalGreenThemeColors.warning,
        error: NaturalGreenThemeColors.error,
      );
}

// =============================================================================
// THEME 4: ROYAL PURPLE (Premium & Creative)
// =============================================================================
class RoyalPurpleThemeColors {
  static const Color primary = Color(0xFF9C27B0); // Deep Purple
  static const Color primaryVariant = Color(0xFF7B1FA2);
  static const Color secondary = Color(0xFFF3E5F5); // Lavender
  static const Color accent = Color(0xFFAB47BC);

  static const Color lightBackground = Color(0xFFFAF7FC);
  static const Color darkBackground = Color(0xFF1A0A1F);

  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);
}

class RoyalPurpleTheme extends AppTheme {
  // Psychological Impact: Stimulates creativity, imagination, and wisdom
  // Best for: Creative subjects, arts, and premium users

  RoyalPurpleTheme()
    : super(
        name: ThemeNames.royalPurple,
        description: ThemeDescriptions.royalPurple,
        primary: RoyalPurpleThemeColors.primary,
        primaryVariant: RoyalPurpleThemeColors.primaryVariant,
        secondary: RoyalPurpleThemeColors.secondary,
        accent: RoyalPurpleThemeColors.accent,
        lightBackground: RoyalPurpleThemeColors.lightBackground,
        darkBackground: RoyalPurpleThemeColors.darkBackground,
        success: RoyalPurpleThemeColors.success,
        warning: RoyalPurpleThemeColors.warning,
        error: RoyalPurpleThemeColors.error,
        isPremium: true,
      );
}

// =============================================================================
// THEME 5: SUNSET CORAL (Warm & Inviting)
// =============================================================================
class SunsetCoralThemeColors {
  static const Color primary = Color(0xFFFF6B6B); // Coral Red
  static const Color primaryVariant = Color(0xFFEE5A6F);
  static const Color secondary = Color(0xFFFFF5F5); // Soft Pink
  static const Color accent = Color(0xFFFF8E8E);

  static const Color lightBackground = Color(0xFFFFF9F9);
  static const Color darkBackground = Color(0xFF1F1314);

  static const Color success = Color(0xFF4ECDC4);
  static const Color warning = Color(0xFFFFE66D);
  static const Color error = Color(0xFFFF6B6B);
}

class SunsetCoralTheme extends AppTheme {
  // Psychological Impact: Friendly, approachable, reduces anxiety
  // Best for: Social learning, group study, language learning
  SunsetCoralTheme()
    : super(
        name: ThemeNames.sunsetCoral,
        description: ThemeDescriptions.sunsetCoral,
        primary: SunsetCoralThemeColors.primary,
        primaryVariant: SunsetCoralThemeColors.primaryVariant,
        secondary: SunsetCoralThemeColors.secondary,
        accent: SunsetCoralThemeColors.accent,
        lightBackground: SunsetCoralThemeColors.lightBackground,
        darkBackground: SunsetCoralThemeColors.darkBackground,
        success: SunsetCoralThemeColors.success,
        warning: SunsetCoralThemeColors.warning,
        error: SunsetCoralThemeColors.error,
      );
}

// =============================================================================
// THEME 6: MIDNIGHT INDIGO (Sophisticated & Modern)
// =============================================================================
class MidnightIndigoThemeColors {
  static const Color primary = Color(0xFF3F51B5); // Indigo
  static const Color primaryVariant = Color(0xFF303F9F);
  static const Color secondary = Color(0xFFE8EAF6); // Light Indigo
  static const Color accent = Color(0xFF536DFE);

  static const Color lightBackground = Color(0xFFF5F6FA);
  static const Color darkBackground = Color(0xFF0A0E27);

  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF5252);
}

class MidnightIndigoTheme extends AppTheme {
  // Psychological Impact: Depth, intelligence, concentration
  // Best for: Technical subjects, coding, mathematics
  MidnightIndigoTheme()
    : super(
        name: ThemeNames.midnightIndigo,
        description: ThemeDescriptions.midnightIndigo,
        primary: MidnightIndigoThemeColors.primary,
        primaryVariant: MidnightIndigoThemeColors.primaryVariant,
        secondary: MidnightIndigoThemeColors.secondary,
        accent: MidnightIndigoThemeColors.accent,
        lightBackground: MidnightIndigoThemeColors.lightBackground,
        darkBackground: MidnightIndigoThemeColors.darkBackground,
        success: MidnightIndigoThemeColors.success,
        warning: MidnightIndigoThemeColors.warning,
        error: MidnightIndigoThemeColors.error,
      );
}

// =============================================================================
// THEME 7: AMBER GOLD (Warm & Optimistic)
// =============================================================================
class AmberGoldThemeColors {
  static const Color primary = Color(0xFFFFA726); // Warm Amber
  static const Color primaryVariant = Color(0xFFFB8C00);
  static const Color secondary = Color(0xFFFFF8E1); // Light Yellow
  static const Color accent = Color(0xFFFFB74D);

  static const Color lightBackground = Color(0xFFFFFBF5);
  static const Color darkBackground = Color(0xFF1F1A0D);

  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);
}

class AmberGoldTheme extends AppTheme {
  // Psychological Impact: Optimism, happiness, mental stimulation
  // Best for: Morning study sessions, motivational content
  AmberGoldTheme()
    : super(
        name: ThemeNames.amberGold,
        description: ThemeDescriptions.amberGold,
        primary: AmberGoldThemeColors.primary,
        primaryVariant: AmberGoldThemeColors.primaryVariant,
        secondary: AmberGoldThemeColors.secondary,
        accent: AmberGoldThemeColors.accent,
        lightBackground: AmberGoldThemeColors.lightBackground,
        darkBackground: AmberGoldThemeColors.darkBackground,
        success: AmberGoldThemeColors.success,
        warning: AmberGoldThemeColors.warning,
        error: AmberGoldThemeColors.error,
      );
}

// =============================================================================
// THEME 8: TEAL OCEAN (Fresh & Modern)
// =============================================================================
class TealOceanThemeColors {
  static const Color primary = Color(0xFF009688); // Teal
  static const Color primaryVariant = Color(0xFF00796B);
  static const Color secondary = Color(0xFFE0F2F1); // Mint
  static const Color accent = Color(0xFF26A69A);

  static const Color lightBackground = Color(0xFFF0F9F8);
  static const Color darkBackground = Color(0xFF0D1F1E);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);
}

class TealOceanTheme extends AppTheme {
  // Psychological Impact: Clarity, emotional balance, calmness
  // Best for: Sciences, research, analytical work
  TealOceanTheme()
    : super(
        name: ThemeNames.tealOcean,
        description: ThemeDescriptions.tealOcean,
        primary: TealOceanThemeColors.primary,
        primaryVariant: TealOceanThemeColors.primaryVariant,
        secondary: TealOceanThemeColors.secondary,
        accent: TealOceanThemeColors.accent,
        lightBackground: TealOceanThemeColors.lightBackground,
        darkBackground: TealOceanThemeColors.darkBackground,
        success: TealOceanThemeColors.success,
        warning: TealOceanThemeColors.warning,
        error: TealOceanThemeColors.error,
      );
}

// =============================================================================
// THEME 9: ROSE PINK (Gentle & Approachable)
// =============================================================================
class RosePinkThemeColors {
  static const Color primary = Color(0xFFE91E63); // Rose Pink
  static const Color primaryVariant = Color(0xFFC2185B);
  static const Color secondary = Color(0xFFFCE4EC); // Light Pink
  static const Color accent = Color(0xFFF06292);

  static const Color lightBackground = Color(0xFFFFF9FA);
  static const Color darkBackground = Color(0xFF1F0D14);

  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);
}

class RosePinkTheme extends AppTheme {
  // Psychological Impact: Compassion, nurturing, reduces aggression
  // Best for: Language learning, humanities, social sciences
  RosePinkTheme()
    : super(
        name: ThemeNames.rosePink,
        description: ThemeDescriptions.rosePink,
        primary: RosePinkThemeColors.primary,
        primaryVariant: RosePinkThemeColors.primaryVariant,
        secondary: RosePinkThemeColors.secondary,
        accent: RosePinkThemeColors.accent,
        lightBackground: RosePinkThemeColors.lightBackground,
        darkBackground: RosePinkThemeColors.darkBackground,
        success: RosePinkThemeColors.success,
        warning: RosePinkThemeColors.warning,
        error: RosePinkThemeColors.error,
      );
}

// =============================================================================
// THEME 10: SLATE GRAY (Minimal & Professional)
// =============================================================================
class SlateGrayThemeColors {
  static const Color primary = Color(0xFF607D8B); // Blue Gray
  static const Color primaryVariant = Color(0xFF455A64);
  static const Color secondary = Color(0xFFECEFF1); // Light Gray
  static const Color accent = Color(0xFF78909C);

  static const Color lightBackground = Color(0xFFF5F7F8);
  static const Color darkBackground = Color(0xFF0F1518);

  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);
}

class SlateGrayTheme extends AppTheme {
  // Psychological Impact: Neutrality, professionalism, no distraction
  // Best for: Professional development, business studies
  SlateGrayTheme()
    : super(
        name: ThemeNames.slateGray,
        description: ThemeDescriptions.slateGray,
        primary: SlateGrayThemeColors.primary,
        primaryVariant: SlateGrayThemeColors.primaryVariant,
        secondary: SlateGrayThemeColors.secondary,
        accent: SlateGrayThemeColors.accent,
        lightBackground: SlateGrayThemeColors.lightBackground,
        darkBackground: SlateGrayThemeColors.darkBackground,
        success: SlateGrayThemeColors.success,
        warning: SlateGrayThemeColors.warning,
        error: SlateGrayThemeColors.error,
      );
}

// =============================================================================
// THEME MANAGER
// =============================================================================
class ThemeManager {
  static final List<AppTheme> themes = [
    CalmBlueTheme(),
    EnergeticOrangeTheme(),
    NaturalGreenTheme(),
    RoyalPurpleTheme(),
    SunsetCoralTheme(),
    MidnightIndigoTheme(),
    AmberGoldTheme(),
    TealOceanTheme(),
    RosePinkTheme(),
    SlateGrayTheme(),
  ];

  static AppTheme get defaultTheme => CalmBlueTheme(); // Calm Blue
  static AppTheme getThemeByName(String name) {
    return themes.firstWhere(
      (theme) => theme.name == name,
      orElse: () => defaultTheme,
    );
  }
}
