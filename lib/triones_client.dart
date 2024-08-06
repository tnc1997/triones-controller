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
  final TrionesBluetoothDevice _device;

  TrionesClient({
    required TrionesBluetoothDevice device,
  }) : _device = device;

  Future<void> setColor(
    int red,
    int green,
    int blue,
  ) async {
    RangeError.checkValueInInterval(red, 0x00, 0xFF, 'red');
    RangeError.checkValueInInterval(green, 0x00, 0xFF, 'green');
    RangeError.checkValueInInterval(blue, 0x00, 0xFF, 'blue');

    final service = await _device.getService(
      TrionesBluetoothServiceUuids.wrgb,
    );

    final characteristic = await service.getCharacteristic(
      TrionesBluetoothCharacteristicUuids.wrgb,
    );

    await characteristic.write([
      0x56,
      red,
      green,
      blue,
      0x00,
      0xF0,
      0xAA,
    ]);
  }

  Future<void> turnOff() async {
    final service = await _device.getService(
      TrionesBluetoothServiceUuids.wrgb,
    );

    final characteristic = await service.getCharacteristic(
      TrionesBluetoothCharacteristicUuids.wrgb,
    );

    await characteristic.write([
      0xCC,
      0x24,
      0x33,
    ]);
  }

  Future<void> turnOn() async {
    final service = await _device.getService(
      TrionesBluetoothServiceUuids.wrgb,
    );

    final characteristic = await service.getCharacteristic(
      TrionesBluetoothCharacteristicUuids.wrgb,
    );

    await characteristic.write([
      0xCC,
      0x23,
      0x33,
    ]);
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

/// Represents a characteristic provided by a service.
abstract interface class TrionesBluetoothCharacteristic {
  /// Reads the value from this characteristic.
  Future<List<int>> read();

  /// Writes the [value] to this characteristic.
  Future<void> write(List<int> value);
}

/// Represents a device.
abstract interface class TrionesBluetoothDevice {
  /// Gets the service for the [uuid].
  Future<TrionesBluetoothService> getService(String uuid);
}

/// Represents a service provided by a device.
abstract interface class TrionesBluetoothService {
  /// Gets the characteristic for the [uuid].
  Future<TrionesBluetoothCharacteristic> getCharacteristic(String uuid);
}
