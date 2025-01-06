import 'dart:async';
import 'package:flutter/material.dart';
import 'device_screen.dart';
import 'device_ota_screen.dart';
import '../utils/snackbar.dart';
import '../widgets/bridge_result_tile.dart';
import '../widgets/bridge_ota_result_tile.dart';
import 'package:tirecheck_device_sdk_flutter/tirecheck_device_sdk.dart';

class ScanScreen extends StatefulWidget {
  final TcDeviceSdk tcDeviceSdk;

  const ScanScreen({Key? key, required this.tcDeviceSdk}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  List<ProcessedDevice> _bridgeScanResults = [];
  List<ProcessedDevice> _bridgeOtaScanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ProcessedDevice>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initBluetoothScan();
    _isScanningSubscription = widget.tcDeviceSdk.isScanning.listen((state) {
      setState(() {
        _isScanning = state;
      });
    });
    _clearScanResults();
  }

  void _initBluetoothScan() {
    _scanResultsSubscription = widget.tcDeviceSdk.subscribeToScanResults(
      (results) {
        setState(() {
          _updateScanResults(results);
        });
      },
      (e) {
        Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
      },
    );
  }

  void _updateScanResults(List<ProcessedDevice> results) {
    for (var result in results) {
      if (result.processedDevice is BleBridge || result.processedDevice is BleBridgeOta) {
        final device = result.processedDevice;
        final isBleBridge = device is BleBridge;     
        final id = isBleBridge ? (device).id : (device as BleBridgeOta).id;
        final list = isBleBridge ? _bridgeScanResults : _bridgeOtaScanResults;

        final index = list.indexWhere((existingDevice) {
          final existingDeviceId = isBleBridge
              ? (existingDevice.processedDevice as BleBridge).id
              : (existingDevice.processedDevice as BleBridgeOta).id;
          return existingDeviceId == id;
        });

        if (index != -1) {
          list[index] = result;
        } else {
          list.add(result);
        }
      }
    }
  }

  void _clearScanResults() {
    setState(() {
      _bridgeOtaScanResults.clear();
      _bridgeScanResults.clear();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _clearScanResults();
      _initBluetoothScan();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future<void> onScanPressed() async {
    _clearScanResults();
    await widget.tcDeviceSdk.performScan();
  }

  Future<void> onStopPressed() async {
    try {
      await widget.tcDeviceSdk.stopScan();
      Snackbar.show(ABC.b, "Stop Scan: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e), success: false);
    }
  }

  Future<void> onConnectPressed(ProcessedDevice device) async {
    _clearScanResults();
    try {
      await widget.tcDeviceSdk.stopScan();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => DeviceScreen(device: device, tcDeviceSdk: widget.tcDeviceSdk),
        settings: RouteSettings(name: '/DeviceScreen'),
      ));
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Navigation Error:", e), success: false);
    }
  }

  Future<void> onConnectOtaPressed(ProcessedDevice device) async {
    _clearScanResults();
    try {
      await widget.tcDeviceSdk.stopScan();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => DeviceOtaScreen(device: device, tcDeviceSdk: widget.tcDeviceSdk),
        settings: RouteSettings(name: '/DeviceOtaScreen'),
      ));
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Navigation Error:", e), success: false);
    }
  }

  Future<void> onRefresh() async {
    if (!_isScanning) {
      await widget.tcDeviceSdk.performScan();
    }
    setState(() {});
    return Future.delayed(Duration(milliseconds: 500));
  }

  Widget buildScanButton(BuildContext context) {
    if (_isScanning) {
      return FloatingActionButton(
        child: const Icon(Icons.stop),
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
      );
    } else {
      return FloatingActionButton(
          child: const Text("SCAN"), onPressed: onScanPressed);
    }
  }

  List<Widget> _buildBridgeScanResultTiles(BuildContext context) {
    return _bridgeScanResults.map((r) => BridgeResultTile(
      processedDevice: r,
      onTap: () => onConnectPressed(r),
    )).toList();
  }

  List<Widget> _buildBridgeOtaScanResultTiles(BuildContext context) {
    return _bridgeOtaScanResults.map((r) => BridgeOtaResultTile(
      processedDevice: r,
      onTap: () => onConnectOtaPressed(r),
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Find Devices'),
        ),
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      if (_bridgeScanResults.isNotEmpty)
                        const Text(
                          "Bridge Devices",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ..._buildBridgeScanResultTiles(context),
                      const SizedBox(height: 20),
                      if (_bridgeOtaScanResults.isNotEmpty)
                        const Text(
                          "Bridge OTA Devices",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ..._buildBridgeOtaScanResultTiles(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: buildScanButton(context),
      ),
    );
  }
}
