import 'package:blast_qr/color_scheme.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
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
      chipTheme: chipTheme(colorScheme),
      pageTransitionsTheme: pageTransitionsTheme,
    );
  }
}

/// Desktop pages switch without the phone-style slide. Phones keep
/// Flutter's defaults.
const pageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: _NoPageTransitionsBuilder(),
    TargetPlatform.windows: _NoPageTransitionsBuilder(),
    TargetPlatform.linux: _NoPageTransitionsBuilder(),
  },
);

class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    prefixIconColor: colorScheme.onSurface,
  );
}

SnackBarThemeData snackBarTheme(ColorScheme colorScheme) {
  return SnackBarThemeData(
    backgroundColor: colorScheme.secondary,
    behavior: SnackBarBehavior.floating,
    width: 160,
    shape: const StadiumBorder(),
    contentTextStyle: TextStyle(
      fontFamily: 'Jersey25',
      color: colorScheme.onPrimary,
    ),
  );
}

ChipThemeData chipTheme(ColorScheme colorScheme) {
  return ChipThemeData(
    color: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return colorScheme.primary;
      }
      return Colors.transparent;
    }),
    selectedColor: colorScheme.primary,
    checkmarkColor: colorScheme.onPrimary,
    labelStyle: TextStyle(fontFamily: 'Jersey25', color: colorScheme.onPrimary),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadiusGeometry.circular(24),
    ),
  );
}

extension BrightnessExtension on Brightness {
  Brightness get opposite =>
      this == Brightness.dark ? Brightness.light : Brightness.dark;
}
