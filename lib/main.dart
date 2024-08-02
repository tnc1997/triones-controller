import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00006E),
        ),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
      ),
      body: StreamBuilder(
        stream: FlutterBluePlus.scanResults,
        builder: (context, snapshot) {
          if (snapshot.data case final results?) {
            return ListView.builder(
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(results[index].device.platformName),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return DeviceScreen(
                            device: results[index].device,
                          );
                        },
                      ),
                    );
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
    );
  }

  @override
  void initState() {
    super.initState();

    FlutterBluePlus.startScan(
      withKeywords: [
        'Triones',
      ],
      timeout: const Duration(
        seconds: 5,
      ),
    );
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
    0x25: 'Pulsating Rainbow',
    0x26: 'Pulsating Red',
    0x27: 'Pulsating Green',
    0x28: 'Pulsating Blue',
    0x29: 'Pulsating Yellow',
    0x2A: 'Pulsating Cyan',
    0x2B: 'Pulsating Purple',
    0x2C: 'Pulsating White',
    0x2D: 'Pulsating Red Green',
    0x2E: 'Pulsating Red Blue',
    0x2F: 'Pulsating Green Blue',
    0x30: 'Rainbow Strobe',
    0x31: 'Red Strobe',
    0x32: 'Green Strobe',
    0x33: 'Blue Strobe',
    0x34: 'Yellow Strobe',
    0x35: 'Cyan Strobe',
    0x36: 'Purple Strobe',
    0x37: 'White Strobe',
    0x38: 'Rainbow Jumping Change',
  };

  double _brightness = 1;
  late final Future<BluetoothCharacteristic?> _characteristic;
  Color _color = Colors.white;
  final _debouncer = Debouncer(duration: const Duration(milliseconds: 500));
  int? _mode;
  bool _power = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.platformName),
      ),
      body: FutureBuilder(
        future: _characteristic,
        builder: (context, snapshot) {
          if (snapshot.data case final characteristic?) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await characteristic.write([
                          0xCC,
                          _power ? 0x24 : 0x23,
                          0x33,
                        ]);

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

                                      await characteristic.write([
                                        0x56,
                                        color.red,
                                        color.green,
                                        color.blue,
                                        0x00,
                                        0xF0,
                                        0xAA,
                                      ]);
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

                                  await characteristic.write([
                                    0x56,
                                    color.red,
                                    color.green,
                                    color.blue,
                                    0x00,
                                    0xF0,
                                    0xAA,
                                  ]);
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
                          await characteristic.write([
                            0xBB,
                            mode,
                            0x00,
                            0x44,
                          ]);
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
                ],
              ),
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

    _characteristic = widget.device.connect().then((_) async {
      for (final service in await widget.device.discoverServices()) {
        if (service.uuid == Guid('FFD5')) {
          for (final characteristic in service.characteristics) {
            if (characteristic.uuid == Guid('FFD9')) {
              return characteristic;
            }
          }
        }
      }

      return null;
    });
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
