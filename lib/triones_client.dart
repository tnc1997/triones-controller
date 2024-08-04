import 'dart:core';

import 'package:collection/collection.dart';

class TrionesClient {}

class TrionesBluetoothCharacteristicUuids {
  static const data = '0000ffd4-0000-1000-8000-00805f9b34fb';
  static const wrgb = '0000ffd9-0000-1000-8000-00805f9b34fb';
}

class TrionesBluetoothServiceUuids {
  static const data = '0000ffd0-0000-1000-8000-00805f9b34fb';
  static const wrgb = '0000ffd5-0000-1000-8000-00805f9b34fb';
}

class TrionesException implements Exception {
  const TrionesException();
}

class TrionesModes {
  static const pulsatingRainbow = 0x25;
  static const pulsatingRed = 0x26;
  static const pulsatingGreen = 0x27;
  static const pulsatingBlue = 0x28;
  static const pulsatingYellow = 0x29;
  static const pulsatingCyan = 0x2A;
  static const pulsatingPurple = 0x2B;
  static const pulsatingWhite = 0x2C;
  static const pulsatingRedGreen = 0x2D;
  static const pulsatingRedBlue = 0x2E;
  static const pulsatingGreenBlue = 0x2F;
  static const rainbowStrobe = 0x30;
  static const redStrobe = 0x31;
  static const greenStrobe = 0x32;
  static const blueStrobe = 0x33;
  static const yellowStrobe = 0x34;
  static const cyanStrobe = 0x35;
  static const purpleStrobe = 0x36;
  static const whiteStrobe = 0x37;
  static const rainbowJumpingChange = 0x38;
}

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
