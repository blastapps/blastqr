import 'package:blast_qr/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum BlastTheme {
  light,
  dark;

  ThemeMode get themeMode {
    if (this == BlastTheme.dark) {
      return ThemeMode.dark;
    }
    if (this == BlastTheme.light) {
      return ThemeMode.light;
    }
    return ThemeMode.system;
  }

  ColorScheme buildColorScheme(Color primaryColor, bool pureBlack) {
    switch (this) {
      case BlastTheme.light:
        return lightColorScheme(primaryColor);
      case BlastTheme.dark:
        if (pureBlack) {
          return blackColorScheme(primaryColor);
        }
        return darkColorScheme(primaryColor);
    }
  }

  ThemeData buildTheme(Color primaryColor, bool pureBlack) {
    final colorScheme = buildColorScheme(primaryColor, pureBlack);
    return ThemeData(
      splashFactory: NoSplash.splashFactory,
      useMaterial3: true,
      colorScheme: colorScheme,
      sliderTheme: SliderThemeData(
        overlayShape: SliderComponentShape.noOverlay,
      ),
      textTheme: textTheme(colorScheme),
      textButtonTheme: textButtonTheme,
      appBarTheme: appBarTheme(colorScheme),
      listTileTheme: listTileTheme(colorScheme),
      inputDecorationTheme: textFieldTheme(colorScheme),
      outlinedButtonTheme: outlinedButtonTheme(colorScheme),
      elevatedButtonTheme: elevatedButtonTheme(colorScheme),
      snackBarTheme: snackBarTheme(colorScheme),
    );
  }
}

ElevatedButtonThemeData elevatedButtonTheme(ColorScheme colorScheme) {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      textStyle: const TextStyle(
        fontFamily: 'Jersey25',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
      ),
      minimumSize: const Size.fromHeight(48),
      elevation: 0,
      shadowColor: Colors.transparent,
      foregroundColor: Colors.white,
      backgroundColor: colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

OutlinedButtonThemeData outlinedButtonTheme(ColorScheme colorScheme) {
  return OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      textStyle: const TextStyle(
        fontFamily: 'Jersey25',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
      ),
      minimumSize: const Size.fromHeight(48),
      elevation: 0,
      backgroundColor: colorScheme.surface,
      shadowColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

AppBarTheme appBarTheme(ColorScheme colorScheme) {
  return AppBarTheme(
    actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: colorScheme.surface,
      statusBarBrightness: colorScheme.brightness, // iOS
      statusBarIconBrightness: colorScheme.brightness.opposite, // Android
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: colorScheme.brightness.opposite,
      systemNavigationBarContrastEnforced: false,
    ),
  );
}

TextButtonThemeData textButtonTheme = TextButtonThemeData(
  style: TextButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

TextTheme textTheme(ColorScheme colorScheme) {
  return TextTheme(
    titleLarge: const TextStyle(
      fontFamily: 'Jersey25',
      fontWeight: FontWeight.bold,
      fontSize: 28,
    ),
    titleMedium: const TextStyle(
      fontWeight: FontWeight.bold,
      fontFamily: 'Jersey25',
      fontSize: 20,
    ),
    titleSmall: TextStyle(
      fontWeight: FontWeight.bold,
      color: colorScheme.secondary,
    ),
  );
}

ListTileThemeData listTileTheme(ColorScheme colorScheme) {
  return ListTileThemeData(
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: colorScheme.onPrimaryContainer,
    ),
  );
}

InputDecorationTheme textFieldTheme(ColorScheme colorScheme) {
  return InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    prefixIconColor: colorScheme.onSurface,
  );
}

SnackBarThemeData snackBarTheme(ColorScheme colorScheme) {
  return SnackBarThemeData(
    backgroundColor: colorScheme.primaryContainer,
    contentTextStyle: TextStyle(color: colorScheme.onPrimaryContainer),
  );
}

extension BrightnessExtension on Brightness {
  Brightness get opposite =>
      this == Brightness.dark ? Brightness.light : Brightness.dark;
}
