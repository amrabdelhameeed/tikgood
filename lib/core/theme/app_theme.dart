import 'package:flutter/material.dart';
import 'package:tikgood/core/theme/app_colors.dart';

class AppTheme {
  static String _font(String locale) => locale == 'en' ? "tiktok" : "kufi";

  static TextStyle textStyleFontFamilyBasedOnLocale(locale) =>
      TextStyle(fontFamily: _font(locale));

  /// Builds a full Typography override so every Material widget
  /// (AppBar titles, Dialog text, Tooltip, SnackBar, etc.) uses our font.
  static Typography _typography(String locale) {
    final font = _font(locale);
    // We build one TextTheme and apply it to all three slots Flutter cares about.
    final base = _textTheme(locale);
    return Typography(
      black: base.apply(bodyColor: Colors.black, displayColor: Colors.black),
      white: base.apply(bodyColor: Colors.white, displayColor: Colors.white),
      englishLike: base,
      dense: base,
      tall: base,
      platform: TargetPlatform.android,
    );
  }

  static TextTheme _textTheme(String locale) {
    final font = _font(locale);
    return TextTheme(
      // ── Display ─────────────────────────────────────────────
      displayLarge: TextStyle(
        fontFamily: font,
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        fontFamily: font,
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        fontFamily: font,
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
      ),
      // ── Headline ────────────────────────────────────────────
      headlineLarge: TextStyle(
        fontFamily: font,
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontFamily: font,
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontFamily: font,
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.33,
      ),
      // ── Title ───────────────────────────────────────────────
      titleLarge: TextStyle(
        fontFamily: font,
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontFamily: font,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.50,
      ),
      titleSmall: TextStyle(
        fontFamily: font,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      // ── Body ────────────────────────────────────────────────
      bodyLarge: TextStyle(
        fontFamily: font,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.50,
      ),
      bodyMedium: TextStyle(
        fontFamily: font,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontFamily: font,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      ),
      // ── Label ───────────────────────────────────────────────
      labelLarge: TextStyle(
        fontFamily: font,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        fontFamily: font,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontFamily: font,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
      ),
    );
  }

  static ThemeData lightTheme(String locale) => ThemeData(
        fontFamily: _font(locale), // catches most widgets
        typography: _typography(locale), // catches Material internals
        bottomSheetTheme: BottomSheetThemeData(backgroundColor: Colors.white),
        primaryColor: AppColors.appColor,
        iconTheme: IconThemeData(color: Colors.grey[900]),
        scaffoldBackgroundColor: Colors.grey[100],
        brightness: Brightness.light,
        primaryColorDark: AppColors.greyMid,
        primaryColorLight: const Color.fromRGBO(230, 230, 230, 1),
        secondaryHeaderColor: Colors.grey[600],
        shadowColor: Colors.grey[200],
        buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.accent),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor:
                WidgetStateProperty.resolveWith((states) => AppColors.appColor),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) return Colors.grey;
              return Colors.white;
            }),
            textStyle: WidgetStateProperty.all<TextStyle>(
              TextStyle(fontFamily: _font(locale)),
            ),
          ),
        ),
        textTheme: _textTheme(locale),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(fontFamily: _font(locale)),
          labelStyle: TextStyle(fontFamily: _font(locale)),
          helperStyle: TextStyle(fontFamily: _font(locale)),
          errorStyle: TextStyle(fontFamily: _font(locale)),
          counterStyle: TextStyle(fontFamily: _font(locale)),
          prefixStyle: TextStyle(fontFamily: _font(locale)),
          suffixStyle: TextStyle(fontFamily: _font(locale)),
        ),
        tabBarTheme: TabBarThemeData(
          indicatorSize: TabBarIndicatorSize.tab,
          tabAlignment: TabAlignment.center,
          labelStyle: TextStyle(fontFamily: _font(locale)),
          unselectedLabelStyle: TextStyle(fontFamily: _font(locale)),
        ),
        tooltipTheme: TooltipThemeData(
          textStyle: TextStyle(fontFamily: _font(locale)),
        ),
        snackBarTheme: SnackBarThemeData(
          contentTextStyle: TextStyle(fontFamily: _font(locale)),
        ),
        dialogTheme: DialogThemeData(
          titleTextStyle:
              TextStyle(fontFamily: _font(locale), fontWeight: FontWeight.bold),
          contentTextStyle: TextStyle(fontFamily: _font(locale)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color.fromRGBO(227, 202, 224, 1)),
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontFamily: _font(locale)),
          backgroundColor: Colors.white,
          elevation: 2,
          actionsIconTheme: IconThemeData(color: Colors.grey[900]),
        ),
      );

  static ThemeData darkTheme(String locale) => ThemeData(
        fontFamily: _font(locale),
        typography: _typography(locale),
        textTheme: _textTheme(locale),
        bottomSheetTheme:
            BottomSheetThemeData(backgroundColor: AppColors.greyDark),
        primaryColor: AppColors.appColorDarkMode,
        scaffoldBackgroundColor: AppColors.greyDark,
        highlightColor: Colors.black,
        primaryColorLight: const Color.fromRGBO(42, 49, 57, 1),
        brightness: Brightness.dark,
        cardColor: const Color.fromRGBO(30, 37, 43, 1),
        primaryColorDark: Colors.grey[300],
        secondaryHeaderColor: Colors.grey[400],
        shadowColor: const Color(0xff282828),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(fontFamily: _font(locale)),
          labelStyle: TextStyle(fontFamily: _font(locale)),
          helperStyle: TextStyle(fontFamily: _font(locale)),
          errorStyle: TextStyle(fontFamily: _font(locale)),
          counterStyle: TextStyle(fontFamily: _font(locale)),
          prefixStyle: TextStyle(fontFamily: _font(locale)),
          suffixStyle: TextStyle(fontFamily: _font(locale)),
        ),
        tabBarTheme: TabBarThemeData(
          indicatorSize: TabBarIndicatorSize.tab,
          tabAlignment: TabAlignment.center,
          labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: _font(locale)),
          unselectedLabelStyle:
              TextStyle(fontSize: 14, fontFamily: _font(locale)),
        ),
        tooltipTheme: TooltipThemeData(
          textStyle: TextStyle(fontFamily: _font(locale)),
        ),
        snackBarTheme: SnackBarThemeData(
          contentTextStyle: TextStyle(fontFamily: _font(locale)),
        ),
        dialogTheme: DialogThemeData(
          titleTextStyle:
              TextStyle(fontFamily: _font(locale), fontWeight: FontWeight.bold),
          contentTextStyle: TextStyle(fontFamily: _font(locale)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color.fromRGBO(42, 49, 57, 1)),
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: _font(locale)),
          backgroundColor: AppColors.greyDark,
          elevation: 2,
        ),
      );
}
