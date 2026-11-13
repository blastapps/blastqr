import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('blastqr/device');

/// Smaller transfers always fit.
const _minCheckedBytes = 50000000;

/// Sending or receiving needs about this many times the transfer's size in
/// memory, with some margin (sending measured ~3.2x).
const _memoryPerTransferByte = 4;

/// Whether a transfer of [bytes] may need more memory than this device has,
/// so the app could be closed partway. Only phones are checked: desktops
/// swap rather than close the app.
Future<bool> mayRunOutOfMemory(int bytes) async {
  if (!Platform.isIOS && !Platform.isAndroid) return false;
  if (bytes < _minCheckedBytes) return false;
  try {
    final available = await _channel.invokeMethod<int>('availableMemory');
    // iOS reports 0 when the app has no memory limit, e.g. in the simulator
    // or on a Mac.
    if (available == null || available == 0) return false;
    return bytes * _memoryPerTransferByte > available;
  } on PlatformException catch (_) {
    return false;
  }
}
