import 'package:flutter/material.dart';

import 'package:blast_qr/color_scheme.dart';
import 'package:flutter/services.dart';

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
      statusBarIconBrightness: colorScheme.brightness.opposite,
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

ThemeData lightTheme = ThemeData(
  splashFactory: NoSplash.splashFactory,
  useMaterial3: true,
  colorScheme: lightColorScheme,
  sliderTheme: SliderThemeData(overlayShape: SliderComponentShape.noOverlay),
  textTheme: textTheme(lightColorScheme),
  textButtonTheme: textButtonTheme,
  appBarTheme: appBarTheme(lightColorScheme),
  listTileTheme: listTileTheme(lightColorScheme),
  inputDecorationTheme: textFieldTheme(lightColorScheme),
  outlinedButtonTheme: outlinedButtonTheme(lightColorScheme),
  elevatedButtonTheme: elevatedButtonTheme(lightColorScheme),
  snackBarTheme: snackBarTheme(lightColorScheme),
);

ThemeData darkTheme = ThemeData(
  splashFactory: NoSplash.splashFactory,
  useMaterial3: true,
  colorScheme: darkColorScheme,
  sliderTheme: SliderThemeData(overlayShape: SliderComponentShape.noOverlay),
  textTheme: textTheme(darkColorScheme),
  textButtonTheme: textButtonTheme,
  appBarTheme: appBarTheme(darkColorScheme),
  listTileTheme: listTileTheme(darkColorScheme),
  inputDecorationTheme: textFieldTheme(darkColorScheme),
  outlinedButtonTheme: outlinedButtonTheme(darkColorScheme),
  elevatedButtonTheme: elevatedButtonTheme(darkColorScheme),
  snackBarTheme: snackBarTheme(darkColorScheme),
);

extension BrightnessExtension on Brightness {
  Brightness get opposite =>
      this == Brightness.dark ? Brightness.light : Brightness.dark;
}
