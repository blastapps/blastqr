import 'package:blast_qr/model/file_extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/scanned_qr_code.dart';
import 'package:flutter/material.dart';

/// In chip order.
enum ReceivedFilter { all, image, video, audio, document, book, other, qr }

/// A row in the received list: a [DateHeader] or a [ReceivedItem].
sealed class ReceivedRow {}

class DateHeader extends ReceivedRow {
  final DateTime date;

  /// Groups everything older than two years.
  final bool isOlder;

  DateHeader(this.date, {this.isOlder = false});
}

sealed class ReceivedItem extends ReceivedRow {
  DateTime get date;
  ReceivedFilter get filter;
  Future<FileWrapper> toFileWrapper();
}

class ReceivedFile extends ReceivedItem {
  ReceivedFile(this.file);
  final FileWrapper file;

  @override
  DateTime get date => file.modified;

  @override
  ReceivedFilter get filter {
    final type = file.type;
    if (type.isImage) return ReceivedFilter.image;
    if (type.isVideo) return ReceivedFilter.video;
    if (type.isAudio) return ReceivedFilter.audio;
    if (type.isDocument) return ReceivedFilter.document;
    if (type.isEbook) return ReceivedFilter.book;
    return ReceivedFilter.other;
  }

  @override
  Future<FileWrapper> toFileWrapper() async => file;
}

class ReceivedQrCode extends ReceivedItem {
  ReceivedQrCode(this.code);
  final ScannedQrCode code;

  @override
  DateTime get date => code.scanned;

  @override
  ReceivedFilter get filter => ReceivedFilter.qr;

  @override
  Future<FileWrapper> toFileWrapper() => code.file.toFileWrapper();
}

/// Puts a [DateHeader] before each day of [items] (newest first), with
/// anything from two or more years before [now] under one "older" header.
List<ReceivedRow> groupByDay(List<ReceivedItem> items, {DateTime? now}) {
  final twoYearsAgo = DateUtils.dateOnly(
    (now ?? DateTime.now()).subtract(const Duration(days: 365 * 2)),
  );
  final grouped = <DateTime, List<ReceivedItem>>{};
  final older = <ReceivedItem>[];
  for (final item in items) {
    final day = DateUtils.dateOnly(item.date);
    if (day.isAfter(twoYearsAgo)) {
      grouped.putIfAbsent(day, () => []).add(item);
    } else {
      older.add(item);
    }
  }
  final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in days) ...[DateHeader(day), ...grouped[day]!],
    if (older.isNotEmpty) ...[DateHeader(DateTime(0), isOlder: true), ...older],
  ];
}
