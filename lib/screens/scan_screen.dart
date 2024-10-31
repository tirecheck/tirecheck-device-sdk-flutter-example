import 'dart:async';

import 'package:flutter/material.dart';

import 'device_screen.dart';
import '../utils/snackbar.dart';
import '../widgets/scan_result_tile.dart';
import 'package:tirecheck_device_sdk_flutter/tirecheck_device_sdk.dart';

class ScanScreen extends StatefulWidget {
  final TcDeviceSdk tcDeviceSdk;

  const ScanScreen({Key? key, required this.tcDeviceSdk}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  List<ProcessedDevice> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ProcessedDevice>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initBluetoothScan();

    _isScanningSubscription = widget.tcDeviceSdk.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _initBluetoothScan() {
    _scanResultsSubscription =
        widget.tcDeviceSdk.subscribeToScanResults((results) {
      results.forEach((result) {
        if (result.processedDevice is BleBridge) {
          final device = result.processedDevice as BleBridge;
          final index = _scanResults.indexWhere((existingDevice) =>
              existingDevice.processedDevice is BleBridge &&
              (existingDevice.processedDevice as BleBridge).id == device.id);

          if (index != -1) {
            _scanResults[index] = result!;
          } else {
            _scanResults.add(result!);
          }
        } else if (result.processedDevice is BleBridgeOta) {
          final device = result.processedDevice as BleBridgeOta;
          final index = _scanResults.indexWhere((existingDevice) =>
              existingDevice.processedDevice is BleBridgeOta &&
              (existingDevice.processedDevice as BleBridgeOta).id == device.id);

          if (index != -1) {
            _scanResults[index] = result;
          } else {
            _scanResults.add(result);
          }
        }
      });

      if (mounted) {
        setState(() {});
      }
    }, (e) {
      Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Clear the scan results when the screen becomes active
      _scanResults.clear();
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future onScanPressed() async {
    _scanResults = [];
    await widget.tcDeviceSdk.performScan(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _scanResults = [];
  }

  Future onStopPressed() async {
    try {
      await widget.tcDeviceSdk.stopScan();
      Snackbar.show(ABC.b, "Stop Scan: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e),
          success: false);
    }
  }

  Future<void> onConnectPressed(ProcessedDevice device) async {
    _scanResults = [];
    try {
      MaterialPageRoute route = MaterialPageRoute(
          builder: (context) =>
              DeviceScreen(device: device, tcDeviceSdk: widget.tcDeviceSdk),
          settings: RouteSettings(name: '/DeviceScreen'));
      await widget.tcDeviceSdk.stopScan();
      Navigator.of(context).push(route);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Navigation Error:", e),
          success: false);
    }
  }

  Future onRefresh() {
    if (_isScanning == false) {
      widget.tcDeviceSdk.performScan(context);
    }
    if (mounted) {
      setState(() {});
    }
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

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return _scanResults
        .map(
          (r) => ScanResultTile(
            processedDevice: r,
            onTap: () => onConnectPressed(r),
          ),
        )
        .toList();
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
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  children: <Widget>[
                    ..._buildScanResultTiles(context),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: buildScanButton(context),
      ),
    );
  }
}
