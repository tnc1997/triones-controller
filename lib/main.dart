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
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
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
  var _brightness = 0.0;
  late final Future<BluetoothCharacteristic?> _characteristic;
  var _color = Colors.white;
  final _debouncer = Debouncer(duration: const Duration(milliseconds: 500));
  var _power = false;

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
                                      await characteristic.write([
                                        0x56,
                                        _color.red,
                                        _color.green,
                                        _color.blue,
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
                                  await characteristic.write([
                                    0x56,
                                    0x00,
                                    0x00,
                                    0x00,
                                    (brightness * 255).round(),
                                    0x0F,
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
