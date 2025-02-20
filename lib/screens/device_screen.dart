import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus_example/widgets/bridge_configuration_display.dart';
import 'package:flutter_blue_plus_example/widgets/bridge_configuration_form.dart';
import 'package:flutter_blue_plus_example/widgets/vehicle_schema_display.dart';
import '../utils/snackbar.dart';
import 'package:tirecheck_device_sdk_flutter/tirecheck_device_sdk.dart';
import '../widgets/vehicle_data_display.dart';
import '../widgets/vehicle_data_form.dart';
import '../widgets/vehicle_firmware_update.dart';

class DeviceScreen extends StatefulWidget {
  final ProcessedDevice device;
  final TcDeviceSdk tcDeviceSdk;
  const DeviceScreen(
      {Key? key, required this.device, required this.tcDeviceSdk})
      : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  int? _rssi;
  String _deviceConnectionState = 'disconnected';
  late StreamSubscription<List<ProcessedDevice>> _scanResultsSubscription;

  var _device;

  @override
  void initState() {
    super.initState();
    _initializeDevice();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeDevice() {
    widget.tcDeviceSdk.setDeviceStateChangeCallback((device, state) {
      _deviceConnectionState = state;
      if (state == 'lostConnection') {
        Snackbar.show(ABC.c, 'Disconnected from the device.', success: false);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      if (mounted) {
        setState(() {});
      }
    });

    _device = widget.device.processedDevice is BleBridge
        ? widget.device.processedDevice as BleBridge
        : widget.device.processedDevice as BleBridgeOta;

    Future.microtask(() => onConnectInner());
  }

  bool get isConnected => _deviceConnectionState == 'paired';

  BridgeTcVehicle? _vehicleData;
  BridgeConfiguration? _bridgeConfiguration;

  Future<void> onGetVehiclePressed() async {
    try {
      final vehicle = await widget.tcDeviceSdk.bridge.getVehicle(_device.id);
      final vehicleConfig =
          await widget.tcDeviceSdk.bridge.getConfiguration(_device.id);
      setState(() {
        _vehicleData = vehicle;
        _bridgeConfiguration = vehicleConfig;
      });
      Snackbar.show(ABC.c, "Vehicle: ${vehicle.vin}", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Get Vehicle Error:", e),
          success: false);
    }
  }

  Map<int, String> getDefaultTyreLabels() {
    const tyreLabelsStr = '_L;_R;_LO;_LI;_RI;_RO;_';
    final tyreLabelsStrLoc = tyreLabelsStr; // No localization needed in Dart
    final tls = tyreLabelsStrLoc.split(';');
    return {
      12: tls[0],
      22: tls[1],
      14: tls[2],
      24: tls[3],
      34: tls[4],
      44: tls[5],
      10: tls.last,
      20: tls.last,
    };
  }

  String getPositionInfo(num positionId) {
    final tyreLabels = getDefaultTyreLabels();

    num axleTyresCount = positionId % 10;
    num axlePosition = (positionId / 100).floor();
    num tyrePosition = (positionId / 10).floor() % 10;
    // bool isSpare = positionId.toString().endsWith('0');
    final l = tyreLabels[tyrePosition * 10 + axleTyresCount];
    final tyreLabel = l?.replaceAll('_', axlePosition.toString());
    if (tyreLabel != null) return tyreLabel;
    if (axleTyresCount < 2) return axlePosition.toString();
    return tyrePosition.toString();
  }

  Future<void> onConnectInner() async {
    try {
      await widget.tcDeviceSdk.bridge
          .connect(_device.id, BridgeAccessLevel.manufacturer);
      Snackbar.show(ABC.c, "Connect: Success", success: true);
    } catch (e) {
      print('Connect error: $e');
      Snackbar.show(ABC.c, prettyException("Connect Error:", e),
          success: false);
      await Future.delayed(const Duration(seconds: 20));
    }
  }

  Future<void> onConnectPressed() async {
    setState(() {
      _scanResults = [];
    });
    final idToConnect = _device.id;
    _initBluetoothScan();
    widget.tcDeviceSdk.performScan();
    try {
      await waitUntil(() => _scanResults.any((device) {
            var processedDevice = device.processedDevice is BleBridge
                ? device.processedDevice as BleBridge
                : device.processedDevice as BleBridgeOta;
            return processedDevice.id == idToConnect;
          }));
      await widget.tcDeviceSdk.stopScan();
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Bridge was not found. Scan the bridge manually.")),
      );
    }
    await _scanResultsSubscription.cancel();
    await onConnectInner();
  }

  Future onDisconnectPressed() async {
    try {
      await widget.tcDeviceSdk.bridge.disconnect(_device.id);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Disconnect Error:", e),
          success: false);
    }
  }

  List<ProcessedDevice> _scanResults = [];
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
            _scanResults[index] = result;
          } else {
            _scanResults.add(result);
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

  bool _reconnectLoading = false;
  Future<void> waitUntil(bool Function() condition,
      {Duration timeout = const Duration(seconds: 10),
      Duration interval = const Duration(milliseconds: 100)}) async {
    setState(() {
      _reconnectLoading = true;
    });

    final endTime = DateTime.now().add(timeout);
    try {
      while (DateTime.now().isBefore(endTime)) {
        if (condition()) {
          return;
        }
        await Future.delayed(interval);
      }
      throw TimeoutException('Condition not met within the timeout period');
    } finally {
      setState(() {
        _reconnectLoading = false;
      });
    }
  }

  Future onVehicleUpdated() async {
    final unMountedId = _device.id;
    await widget.tcDeviceSdk.bridge.disconnect(_device.id);
    _initBluetoothScan();
    widget.tcDeviceSdk.performScan();
    try {
      await waitUntil(() => _scanResults.any((device) {
            var processedDevice = device.processedDevice is BleBridge
                ? device.processedDevice as BleBridge
                : device.processedDevice as BleBridgeOta;
            if (processedDevice.id == unMountedId) {
              return true;
            }
            return false;
          }));
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Bridge was not found. Scan the bridge manually.")),
      );
    }
    setState(() {
      _vehicleData = null;
      _bridgeConfiguration = null;
    });
    await widget.tcDeviceSdk.stopScan();
    final foundDevice = _scanResults.firstWhere((device) {
      var processedDevice = device.processedDevice is BleBridge
          ? device.processedDevice as BleBridge
          : device.processedDevice as BleBridgeOta;
      return processedDevice.id == unMountedId;
    });

    _device = foundDevice.processedDevice is BleBridge
        ? foundDevice.processedDevice as BleBridge
        : foundDevice.processedDevice as BleBridgeOta;
    _scanResults = [];
    await onConnectPressed();
    _scanResultsSubscription.cancel();
  }

  Future onStartTest() async {}

  List<BridgeReading> _bridgeReadings = [];
  Future onGetVehicleReadings() async {
    try {
      _bridgeReadings = await widget.tcDeviceSdk.bridge
          .getVehicleReadings(_device.id, _vehicleData!);
      setState(() {});
      Snackbar.show(ABC.c, "Bridge readings has been captured.", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Get Readings Error:", e),
          success: false);
    }
  }

  Widget buildSpinner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(
          backgroundColor: Colors.black12,
          color: Colors.black26,
        ),
      ),
    );
  }

  Widget buildRemoteId(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${_device.id}'),
          Text('Name: ${_device.name}'),
          if (_vehicleData != null) Text('VIN: ${_vehicleData!.vin}'),
        ],
      ),
    );
  }

  Widget buildRssiTile(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isConnected
            ? const Icon(Icons.bluetooth_connected)
            : const Icon(Icons.bluetooth_disabled),
        Text(((isConnected && _rssi != null) ? '${_rssi!} dBm' : ''),
            style: Theme.of(context).textTheme.bodySmall)
      ],
    );
  }

  Widget buildConnectButton(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: _deviceConnectionState == 'connecting'
              ? () {} // TODO: maybe bring back cancel
              : (isConnected ? onDisconnectPressed : onConnectPressed),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            backgroundColor: _deviceConnectionState == 'connecting'
                ? Colors.orange
                : (isConnected ? Colors.red : Colors.green),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: _deviceConnectionState == 'connecting' ||
                  _deviceConnectionState == 'connected' ||
                  _deviceConnectionState == 'disconnecting'
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.0,
                  ),
                )
              : Text(
                  isConnected ? "DISCONNECT" : "CONNECT",
                  style: Theme.of(context)
                      .primaryTextTheme
                      .labelLarge
                      ?.copyWith(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Future onGetAutolearnStatus() async {
    try {
      final statuses = (await widget.tcDeviceSdk.bridge
              .getAutolearnStatuses(_device.id, _vehicleData!))
          .toList();
      if (statuses.isEmpty) {
        Snackbar.show(ABC.c, "No autolearn status has been captured.",
            success: true);
        return;
      }
      final statusMessages = statuses.map((status) {
        return 'Position ID: ${status.positionId}, Autolearned Sensor ID: ${status.autolearnedSensorId}';
      }).join('\n');
      Snackbar.show(
          ABC.c, "Autolearn status has been captured:\n$statusMessages",
          success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Get Autolearn Error:", e),
          success: false);
    }
  }

  Future onUpdateFinished() async {
    if (!isConnected) await onConnectPressed();
  }

  Future onResetAutolearnStatus() async {
    try {
      List<int> positionIds = _vehicleData!.tcTyres
          .map((el) => el.mountedOn!.positionId as int)
          .toList();
      await widget.tcDeviceSdk.bridge
          .resetAutolearnStatuses(_device.id, positionIds);
      Snackbar.show(ABC.c, "Autolearn status has been reset.", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Reset Autolearn Error:", e),
          success: false);
    }
  }

  bool _vehicleDataLoading = false;
  Widget buildActionButtons(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_device.name != '030397')
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _vehicleDataLoading = true;
                });
                await onGetVehiclePressed();
                setState(() {
                  _vehicleDataLoading = false;
                });
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: _vehicleDataLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.0,
                      ),
                    )
                  : const Text(
                      "Get Vehicle",
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          if (_vehicleData != null) const SizedBox(width: 8),
          if (_vehicleData != null)
            ElevatedButton(
              onPressed: onGetVehicleReadings,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                "Get Readings",
                style: TextStyle(color: Colors.white),
              ),
            ),
          if (_vehicleData != null) const SizedBox(width: 8),
          if (_vehicleData != null)
            ElevatedButton(
              onPressed: onGetAutolearnStatus,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                "Get Autolearn Status",
                style: TextStyle(color: Colors.white),
              ),
            ),
          if (_vehicleData != null) const SizedBox(width: 8),
          if (_vehicleData != null)
            ElevatedButton(
              onPressed: onResetAutolearnStatus,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                "Reset Autolearn Status",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return _reconnectLoading
        ? Positioned.fill(
            child: Container(
              color: const Color.fromARGB(137, 87, 87,
                  87), // Darker semi-transparent background for better contrast
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(96, 143, 143, 143),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            const Color.fromARGB(255, 255, 255, 255)),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Reconnecting after bridge data change...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color.fromARGB(255, 241, 241, 241),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please wait a moment',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        : Container();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ScaffoldMessenger(
          key: Snackbar.snackBarKeyC,
          child: Scaffold(
            appBar: AppBar(
              title: Text(_device.name),
              actions: [buildConnectButton(context)],
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () async {
                  if (_deviceConnectionState != 'disconnecting' ||
                      _deviceConnectionState != 'disconnected') {
                    await onDisconnectPressed();
                  } else if (Navigator.of(context).canPop()) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  buildRemoteId(context),
                  ListTile(
                    leading: buildRssiTile(context),
                    title: Text('Device is ${_deviceConnectionState}.'),
                  ),
                  if (isConnected)
                    buildActionButtons(
                        context), // Show action buttons only when connected
                  if (_vehicleData != null)
                    VehicleSchemaDisplay(
                      vehicleData: _vehicleData!,
                      getPositionInfo: getPositionInfo,
                      bridgeReadings: _bridgeReadings,
                    ),
                  if (_vehicleData != null)
                    VehicleDataWidget(
                      vehicleData: _vehicleData!,
                      getPositionInfo: getPositionInfo,
                    ),
                  if (_vehicleData != null)
                    VehicleDataForm(
                      vehicle: _vehicleData!,
                      tcDeviceSdk: widget.tcDeviceSdk,
                      device: widget.device,
                      onVehicleUpdated: onVehicleUpdated,
                    ),
                  if (_bridgeConfiguration != null)
                    BridgeConfigurationDisplayWidget(
                      bridgeConfiguration: _bridgeConfiguration,
                    ),
                  if (_bridgeConfiguration != null)
                    BridgeConfigurationForm(
                      configuration: _bridgeConfiguration!,
                      tcDeviceSdk: widget.tcDeviceSdk,
                      device: widget.device,
                    ),
                  if (isConnected)
                    VehicleFirmwareUpdate(
                      tcDeviceSdk: widget.tcDeviceSdk,
                      device: widget.device,
                      onUpdateFinished: onUpdateFinished,
                    ),
                ],
              ),
            ),
          ),
        ),
        _buildLoadingOverlay(), // Add loading overlay on top of the whole screen
      ],
    );
  }
}
