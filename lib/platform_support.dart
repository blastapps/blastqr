import 'dart:io';

import 'package:flutter/widgets.dart';

// The camera plugins have no image stream on Windows yet.
bool get canScanWithCamera => !Platform.isWindows;

/// For what depends on the operating system, like window settings or the
/// system file manager. The layout uses [DesktopLayout.useDesktopLayout].
bool get isDesktopOS =>
    Platform.isMacOS || Platform.isLinux || Platform.isWindows;

extension DesktopLayout on BuildContext {
  /// The side panel, dialogs and file manager style lists. Always on desktop
  /// OSes, and in large windows elsewhere: Android desktop mode, Chromebooks,
  /// Samsung DeX and tablets in landscape. Not phones in landscape, which
  /// are wide but short.
  bool get useDesktopLayout {
    if (isDesktopOS) return true;
    final size = MediaQuery.sizeOf(this);
    return size.width >= 840 && size.height >= 480;
  }
}
