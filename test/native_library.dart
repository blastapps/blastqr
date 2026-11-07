import 'dart:io';

/// Where `flutter test` builds the Rust library [name] for this machine.
String nativeLibraryPath(String name) {
  if (Platform.isMacOS) return 'build/native_assets/macos/lib$name.dylib';
  if (Platform.isWindows) return 'build/native_assets/windows/$name.dll';
  return 'build/native_assets/linux/lib$name.so';
}
