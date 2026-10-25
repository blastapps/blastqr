import 'dart:io';

// The camera plugins have no image stream on Windows yet.
bool get canScanWithCamera => !Platform.isWindows;
