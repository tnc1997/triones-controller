import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'triones_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controller for Triones',
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF00006E),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF00006E),
      ),
      home: const ScanScreen(),
    );
  }
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
  });

  @override
  State<ScanScreen> createState() {
    return _ScanScreenState();
  }
}

class _ScanScreenState extends State<ScanScreen> {
  bool? _isConnecting;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FlutterBluePlus.isScanning,
      builder: (context, snapshot) {
        FloatingActionButton? floatingActionButton;

        if (snapshot.data != true) {
          floatingActionButton = FloatingActionButton.extended(
            onPressed: () async {
              try {
                await FlutterBluePlus.startScan(
                  withKeywords: [
                    'Triones',
                  ],
                  timeout: const Duration(
                    seconds: 5,
                  ),
                );
              } catch (e) {
                if (context.mounted) {
                  return await showDialog(
                    context: context,
                    builder: (context) {
                      return SimpleDialog(
                        children: [
                          Text(e.toString()),
                        ],
                      );
                    },
                  );
                }
              }
            },
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('Scan'),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: StreamBuilder<List<ScanResult>>(
              stream: FlutterBluePlus.scanResults,
              builder: (context, snapshot) {
                if (snapshot.data case final results?) {
                  return ListView.builder(
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(results[index].device.platformName),
                        enabled: _isConnecting != true,
                        onTap: () async {
                          try {
                            setState(() {
                              _isConnecting = true;
                            });

                            await results[index].device.connect();

                            if (context.mounted) {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) {
                                    return DeviceScreen(
                                      device: results[index].device,
                                    );
                                  },
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              return await showDialog(
                                context: context,
                                builder: (context) {
                                  return SimpleDialog(
                                    children: [
                                      Text(e.toString()),
                                    ],
                                  );
                                },
                              );
                            }
                          } finally {
                            setState(() {
                              _isConnecting = false;
                            });
                          }
                        },
                      );
                    },
                    itemCount: results.length,
                  );
                }

                if (snapshot.error case final error?) {
                  return Center(
                    child: Text('$error'),
                  );
                }

                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    try {
      FlutterBluePlus.startScan(
        withKeywords: [
          'Triones',
        ],
        timeout: const Duration(
          seconds: 5,
        ),
      );
    } catch (e) {
      // ignored
    }
  }
}

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({
    super.key,
    required this.device,
  });

  final BluetoothDevice device;

  @override
  State<DeviceScreen> createState() {
    return _DeviceScreenState();
  }
}

class _DeviceScreenState extends State<DeviceScreen> {
  static const _modes = {
    TrionesModes.pulsatingRainbow: 'Pulsating Rainbow',
    TrionesModes.pulsatingRed: 'Pulsating Red',
    TrionesModes.pulsatingGreen: 'Pulsating Green',
    TrionesModes.pulsatingBlue: 'Pulsating Blue',
    TrionesModes.pulsatingYellow: 'Pulsating Yellow',
    TrionesModes.pulsatingCyan: 'Pulsating Cyan',
    TrionesModes.pulsatingPurple: 'Pulsating Purple',
    TrionesModes.pulsatingWhite: 'Pulsating White',
    TrionesModes.pulsatingRedGreen: 'Pulsating Red Green',
    TrionesModes.pulsatingRedBlue: 'Pulsating Red Blue',
    TrionesModes.pulsatingGreenBlue: 'Pulsating Green Blue',
    TrionesModes.rainbowStrobe: 'Rainbow Strobe',
    TrionesModes.redStrobe: 'Red Strobe',
    TrionesModes.greenStrobe: 'Green Strobe',
    TrionesModes.blueStrobe: 'Blue Strobe',
    TrionesModes.yellowStrobe: 'Yellow Strobe',
    TrionesModes.cyanStrobe: 'Cyan Strobe',
    TrionesModes.purpleStrobe: 'Purple Strobe',
    TrionesModes.whiteStrobe: 'White Strobe',
    TrionesModes.rainbowJumpingChange: 'Rainbow Jumping Change',
  };

  double _brightness = 1;
  late final TrionesClient _client;
  Color _color = Colors.white;
  final _debouncer = Debouncer(duration: const Duration(milliseconds: 500));
  int? _mode;
  bool _power = false;
  double _speed = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.platformName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_power) {
                    await _client.turnOff();
                  } else {
                    await _client.turnOn();
                  }

                  setState(() {
                    _power = !_power;
                  });
                },
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Power'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return SimpleDialog(
                        children: [
                          ColorPicker(
                            pickerColor: _color,
                            onColorChanged: (color) {
                              setState(() {
                                _color = color;
                              });

                              _debouncer.run(() async {
                                final color = _color.withBrightness(
                                  _brightness,
                                );

                                await _client.setColor(
                                  color.red,
                                  color.green,
                                  color.blue,
                                );
                              });
                            },
                            enableAlpha: false,
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.color_lens),
                label: const Text('Color'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.brightness_low),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                      ),
                      child: Slider(
                        value: _brightness,
                        onChanged: (brightness) {
                          setState(() {
                            _brightness = brightness;
                          });

                          _debouncer.run(() async {
                            final color = _color.withBrightness(
                              _brightness,
                            );

                            await _client.setColor(
                              color.red,
                              color.green,
                              color.blue,
                            );
                          });
                        },
                      ),
                    ),
                  ),
                  const Icon(Icons.brightness_high),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownMenu(
                label: const Text('Mode'),
                onSelected: (mode) async {
                  if (mode != null) {
                    await _client.setMode(
                      mode,
                      speed: (255 * _speed).round(),
                    );
                  }

                  setState(() {
                    _mode = mode;
                  });
                },
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: [
                  for (final entry in _modes.entries)
                    DropdownMenuEntry(
                      value: entry.key,
                      label: entry.value,
                    ),
                ],
              ),
            ),
            if (_mode case final mode?)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(Icons.speed),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                        ),
                        child: Slider(
                          value: _speed,
                          onChanged: (speed) {
                            setState(() {
                              _speed = speed;
                            });

                            _debouncer.run(() async {
                              await _client.setMode(
                                mode,
                                speed: (255 * _speed).round(),
                              );
                            });
                          },
                        ),
                      ),
                    ),
                    const Icon(Icons.speed),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debouncer.dispose();

    widget.device.disconnect();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _client = TrionesClient(
      bluetoothService: FlutterBluePlusBluetoothService(
        device: widget.device,
      ),
    );
  }
}

class Debouncer {
  final Duration _duration;
  Timer? _timer;

  Debouncer({
    required Duration duration,
  }) : _duration = duration;

  void run(void Function() callback) {
    _timer?.cancel();

    _timer = Timer(_duration, callback);
  }

  void dispose() {
    _timer?.cancel();
  }
}

extension on Color {
  Color withBrightness(double brightness) {
    return Color.fromARGB(
      alpha,
      (red * brightness).round(),
      (green * brightness).round(),
      (blue * brightness).round(),
    );
  }
}

class FlutterBluePlusBluetoothService implements TrionesBluetoothService {
  final BluetoothDevice _device;

  FlutterBluePlusBluetoothService({
    required BluetoothDevice device,
  }) : _device = device;

  @override
  Future<List<int>> readCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  ) async {
    final characteristic = await _getCharacteristic(
      serviceUuid,
      characteristicUuid,
    );

    return await characteristic.read();
  }

  @override
  Future<void> writeCharacteristic(
    String serviceUuid,
    String characteristicUuid,
    List<int> value,
  ) async {
    final characteristic = await _getCharacteristic(
      serviceUuid,
      characteristicUuid,
    );

    await characteristic.write(value);
  }

  Future<BluetoothCharacteristic> _getCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  ) async {
    if (_device.servicesList.isEmpty) {
      await _device.discoverServices();
    }

    for (final service in _device.servicesList) {
      if (service.uuid == Guid.fromString(serviceUuid)) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == Guid.fromString(characteristicUuid)) {
            return characteristic;
          }
        }

        throw Exception('Failed to find the characteristic.');
      }
    }

    throw Exception('Failed to find the service.');
  }
}
