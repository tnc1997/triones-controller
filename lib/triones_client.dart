import 'dart:core';

class TrionesBluetoothCharacteristicUuids {
  static const data = '0000ffd4-0000-1000-8000-00805f9b34fb';
  static const wrgb = '0000ffd9-0000-1000-8000-00805f9b34fb';
}

class TrionesBluetoothServiceUuids {
  static const data = '0000ffd0-0000-1000-8000-00805f9b34fb';
  static const wrgb = '0000ffd5-0000-1000-8000-00805f9b34fb';
}

class TrionesClient {
  final TrionesBluetoothService _bluetoothService;

  TrionesClient({
    required TrionesBluetoothService bluetoothService,
  }) : _bluetoothService = bluetoothService;

  Future<void> setColor(
    int red,
    int green,
    int blue,
  ) async {
    RangeError.checkValueInInterval(red, 0x00, 0xFF, 'red');
    RangeError.checkValueInInterval(green, 0x00, 0xFF, 'green');
    RangeError.checkValueInInterval(blue, 0x00, 0xFF, 'blue');

    await _bluetoothService.writeCharacteristic(
      TrionesBluetoothServiceUuids.wrgb,
      TrionesBluetoothCharacteristicUuids.wrgb,
      [
        0x56,
        red,
        green,
        blue,
        0x00,
        0xF0,
        0xAA,
      ],
    );
  }

  Future<void> setMode(
    int mode, {
    int speed = 0xFF,
  }) async {
    RangeError.checkValueInInterval(mode, 0x25, 0x38, 'mode');
    RangeError.checkValueInInterval(speed, 0x00, 0xFF, 'speed');

    await _bluetoothService.writeCharacteristic(
      TrionesBluetoothServiceUuids.wrgb,
      TrionesBluetoothCharacteristicUuids.wrgb,
      [
        0xBB,
        mode,
        speed,
        0x44,
      ],
    );
  }

  Future<void> setWhite({
    int brightness = 0xFF,
  }) async {
    RangeError.checkValueInInterval(brightness, 0x00, 0xFF, 'brightness');

    await _bluetoothService.writeCharacteristic(
      TrionesBluetoothServiceUuids.wrgb,
      TrionesBluetoothCharacteristicUuids.wrgb,
      [
        0x56,
        0x00,
        0x00,
        0x00,
        brightness,
        0x0F,
        0xAA,
      ],
    );
  }

  Future<void> turnOff() async {
    await _bluetoothService.writeCharacteristic(
      TrionesBluetoothServiceUuids.wrgb,
      TrionesBluetoothCharacteristicUuids.wrgb,
      [
        0xCC,
        0x24,
        0x33,
      ],
    );
  }

  Future<void> turnOn() async {
    await _bluetoothService.writeCharacteristic(
      TrionesBluetoothServiceUuids.wrgb,
      TrionesBluetoothCharacteristicUuids.wrgb,
      [
        0xCC,
        0x23,
        0x33,
      ],
    );
  }
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

abstract interface class TrionesBluetoothService {
  /// Reads the value from the characteristic for the [serviceUuid] and the [characteristicUuid].
  Future<List<int>> readCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  );

  /// Writes the [value] to the characteristic for the [serviceUuid] and the [characteristicUuid].
  Future<void> writeCharacteristic(
    String serviceUuid,
    String characteristicUuid,
    List<int> value,
  );
}
