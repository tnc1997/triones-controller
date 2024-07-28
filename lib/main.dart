import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  late final Future<List<BluetoothService>> _services;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.platformName),
      ),
      body: FutureBuilder(
        future: _services,
        builder: (context, snapshot) {
          if (snapshot.data case final services?) {
            return ListView.builder(
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(services[index].serviceUuid.str),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return ServiceScreen(
                            service: services[index],
                          );
                        },
                      ),
                    );
                  },
                );
              },
              itemCount: services.length,
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
    widget.device.disconnect();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _services = widget.device.connect().then((_) async {
      return await widget.device.discoverServices();
    });
  }
}

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({
    super.key,
    required this.service,
  });

  final BluetoothService service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(service.serviceUuid.str),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(service.characteristics[index].characteristicUuid.str),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return CharacteristicScreen(
                      characteristic: service.characteristics[index],
                    );
                  },
                ),
              );
            },
          );
        },
        itemCount: service.characteristics.length,
      ),
    );
  }
}

class CharacteristicScreen extends StatefulWidget {
  const CharacteristicScreen({
    super.key,
    required this.characteristic,
  });

  final BluetoothCharacteristic characteristic;

  @override
  State<CharacteristicScreen> createState() {
    return _CharacteristicScreenState();
  }
}

class _CharacteristicScreenState extends State<CharacteristicScreen> {
  var _power = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (widget.characteristic.properties.write)
            IconButton(
              onPressed: () async {
                await widget.characteristic.write([
                  0xCC,
                  _power ? 0x24 : 0x23,
                  0x33,
                ]);

                setState(() {
                  _power = !_power;
                });
              },
              icon: Icon(_power ? Icons.power_off : Icons.power),
            ),
        ],
        title: Text(widget.characteristic.characteristicUuid.str),
      ),
      body: ListView(
        children: [
          ...widget.characteristic.descriptors.map(
            (descriptor) {
              return ListTile(
                title: Text(descriptor.descriptorUuid.str),
              );
            },
          ),
          ListTile(
            title: Text('${widget.characteristic.properties}'),
          ),
        ],
      ),
    );
  }
}
