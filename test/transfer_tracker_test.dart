import 'dart:typed_data';

import 'package:blast_qr/features/scan/transfer_tracker.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// A frame of a transfer identified by [session].
Uint8List _frame({
  int session = 1,
  int flags = 0,
  int transferLength = 50000,
  int symbolSize = 2928,
  int version = BlastQrcodeData.protocolVersion,
}) {
  final header = BlastQrcodeData.buildHeader(
    flags: flags,
    kind: BlastQrcodeData.kindFile,
    sessionId: session,
    transferLength: transferLength,
    symbolSize: symbolSize,
  )..[3] = version;
  return Uint8List.fromList([
    ...header,
    ...Uint8List(BlastQrcodeData.packetIdLength + symbolSize),
  ]);
}

final _t0 = DateTime(2026);
DateTime _at(int ms) => _t0.add(Duration(milliseconds: ms));

void main() {
  late TransferTracker tracker;

  setUp(() => tracker = TransferTracker());

  ScanAction act(Uint8List? bytes, int ms, {bool busy = false}) =>
      tracker.handle(bytes, _at(ms), busy: busy).action;

  group('classification', () {
    test('other QR codes are foreign', () {
      expect(act(Uint8List.fromList('hello'.codeUnits), 0), ScanAction.foreign);
      expect(act(null, 0), ScanAction.foreign);
    });

    test('newer versions and unknown features ask for an update', () {
      expect(act(_frame(version: 3), 0), ScanAction.updateRequired);
      expect(act(_frame(flags: 0x04), 0), ScanAction.updateRequired);
      expect(tracker.current, isNull);
    });

    test('encrypted transfers are received', () {
      expect(
        act(_frame(flags: BlastQrcodeData.flagEncrypted), 0),
        ScanAction.start,
      );
    });

    test('unsafe headers are ignored and lock nothing', () {
      // Would need ~45M symbols.
      expect(
        act(_frame(transferLength: 0xFFFFFFFF, symbolSize: 96), 0),
        ScanAction.ignore,
      );
      expect(tracker.current, isNull);
      expect(act(_frame(), 10), ScanAction.start);
    });
  });

  group('one transfer at a time', () {
    test('first frame starts, later frames decode', () {
      expect(act(_frame(), 0), ScanAction.start);
      expect(act(_frame(), 50), ScanAction.decode);
      expect(act(_frame(), 100), ScanAction.decode);
    });

    test('another transfer is ignored while the current one is arriving', () {
      act(_frame(session: 1), 0);
      expect(act(_frame(session: 2), 100), ScanAction.ignore);
      expect(act(_frame(session: 1), 200), ScanAction.decode);
      expect(tracker.current!.sessionId, 1);
    });

    test('a second sender in view never takes over an active transfer', () {
      act(_frame(session: 1), 0);
      // Both senders keep showing frames for 10 s.
      for (var ms = 50; ms < 10000; ms += 100) {
        expect(act(_frame(session: 1), ms), ScanAction.decode);
        expect(act(_frame(session: 2), ms + 50), ScanAction.ignore);
      }
    });

    test('switches after the current transfer has been quiet for 1.5 s', () {
      act(_frame(session: 1), 0);
      expect(act(_frame(session: 2), 1499), ScanAction.ignore);
      expect(act(_frame(session: 2), 1500), ScanAction.switchTransfer);
      expect(tracker.current!.sessionId, 2);
      // Now the old transfer is the one being ignored.
      expect(act(_frame(session: 1), 1600), ScanAction.ignore);
      expect(act(_frame(session: 2), 1700), ScanAction.decode);
    });

    test('ignored frames from another sender do not delay the switch', () {
      act(_frame(session: 1), 0);
      act(_frame(session: 2), 1000); // ignored
      expect(act(_frame(session: 2), 1500), ScanAction.switchTransfer);
    });

    test('does not switch while busy (saving the current file)', () {
      act(_frame(session: 1), 0);
      expect(act(_frame(session: 2), 5000, busy: true), ScanAction.ignore);
      expect(tracker.current!.sessionId, 1);
    });

    test('other QR codes are ignored while a transfer is arriving', () {
      final hello = Uint8List.fromList('hello'.codeUnits);
      act(_frame(session: 1), 0);
      expect(act(hello, 100), ScanAction.ignore);
      expect(act(null, 200), ScanAction.ignore);
      expect(act(_frame(session: 1), 300), ScanAction.decode);
      expect(act(hello, 1800, busy: true), ScanAction.ignore);
      expect(act(hello, 1800), ScanAction.foreign);
    });

    test('reset forgets the transfer', () {
      act(_frame(session: 1), 0);
      tracker.reset();
      expect(tracker.current, isNull);
      expect(act(_frame(session: 2), 10), ScanAction.start);
    });
  });
}
