import 'dart:core';

import 'package:collection/collection.dart';

class TrionesClient {}

List<int>? _normalize(
  List<int>? uuid,
) {
  const suffix = [
    0x00,
    0x00,
    0x10,
    0x00,
    0x80,
    0x00,
    0x00,
    0x80,
    0x5F,
    0x9B,
    0x34,
    0xFB,
  ];

  switch (uuid) {
    case _?:
      switch (uuid.length) {
        case 2:
          return [0x00, 0x00, ...uuid, ...suffix];
        case 4:
          return [...uuid, ...suffix];
        case 16:
          return uuid;
        default:
          throw FormatException('Invalid UUID', uuid);
      }
    default:
      return uuid;
  }
}

String _prettify(
  List<int> uuid,
) {
  switch (uuid.length) {
    case 2 || 4:
      return uuid.fold(
        '',
        (previous, current) {
          return previous + current.toRadixString(16).padLeft(2, '0');
        },
      );
    case 16:
      return uuid.foldIndexed(
        '',
        (index, previous, current) {
          if (index == 3 || index == 5 || index == 7 || index == 9) {
            return previous + current.toRadixString(16).padLeft(2, '0') + '-';
          } else {
            return previous + current.toRadixString(16).padLeft(2, '0');
          }
        },
      );
    default:
      throw FormatException('Invalid UUID', uuid);
  }
}