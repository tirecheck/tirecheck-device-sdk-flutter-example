import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../utils/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tirecheck_device_sdk_flutter/tirecheck_device_sdk.dart';

class DeviceOtaScreen extends StatefulWidget {
  final ProcessedDevice device;
  final TcDeviceSdk tcDeviceSdk;
  const DeviceOtaScreen(
      {Key? key, required this.device, required this.tcDeviceSdk})
      : super(key: key);

  @override
  State<DeviceOtaScreen> createState() => _DeviceOtaScreenState();
}

class _DeviceOtaScreenState extends State<DeviceOtaScreen> {
  var _device;
  Uint8List? application;
  Uint8List? bootloader;
  // ignore: unused_field
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();

    _device = widget.device.processedDevice is BleBridge
        ? widget.device.processedDevice as BleBridge
        : widget.device.processedDevice as BleBridgeOta;
  }

  Future<void> onFirmwareUpdate() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInitialContent(context, setState),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInitialContent(BuildContext context, StateSetter setState) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Please upload the application and bootloader files to start the firmware update process.',
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        if (application == null)
          _buildApplicationUploadButton(context, setState),
        if (application != null) _buildUploadedText("Application uploaded"),
        const SizedBox(height: 16),
        if (bootloader == null) _buildBootloaderUploadButton(context, setState),
        if (bootloader != null) _buildUploadedText("Bootloader uploaded"),
        const SizedBox(height: 16),
        _buildStartUpdateButton(context, setState),
      ],
    );
  }

  Widget _buildUploadedText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: TextStyle(color: Colors.green, fontSize: 14),
      ),
    );
  }

  Widget _buildStartUpdateButton(BuildContext context, StateSetter setState) {
    return ElevatedButton(
      onPressed: _isStartUpdateButtonEnabled()
          ? () => _startFirmwareUpdate(setState)
          : null,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        backgroundColor:
            _isStartUpdateButtonEnabled() ? Colors.blue : Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        elevation: 5,
      ),
      child: Text(
        "Start Firmware Update",
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  bool _isStartUpdateButtonEnabled() {
    return (_device.name != '030397_B' &&
            application != null &&
            bootloader != null) ||
        (_device.name == '030397_B' && application != null);
  }

  Future<void> _startFirmwareUpdate(StateSetter setState) async {
    setState(() {
      _isUpdating = true;
    });
    Navigator.pop(context); // Close the bottom sheet
    try {
      Snackbar.show(ABC.c, 'Starting firmware update.',
          success: true, duration: Duration(seconds: 15));
      await widget.tcDeviceSdk.bridgeOta.updateFirmware(
        _device.id,
        bootloader,
        application!,
        (status, progress) {
          print('Update Status: $status, Progress: $progress');
          Snackbar.show(ABC.c,
              'Update Status: $status, Progress: ${(progress * 100).toStringAsFixed(2)}%',
              success: true, duration: Duration(seconds: 15));
        },
      );
      Snackbar.show(ABC.c, 'Firmware Update Success', success: true);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Firmware Update Error:", e),
          success: false);
    } finally {
      if (mounted) {
        setState(() {
          application = null;
          bootloader = null;
          _isUpdating = false;
        });
      }
    }
  }

  Widget _buildApplicationUploadButton(
      BuildContext context, StateSetter setState) {
    return ElevatedButton(
      onPressed: () => _onFileUpload('application', setState),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: const Text(
        "Upload Application",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildBootloaderUploadButton(
      BuildContext context, StateSetter setState) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _onFileUpload('bootloader', setState),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: const Text(
            "Upload Bootloader",
            style: TextStyle(color: Colors.white),
          ),
        ),
        if (_device.name == '030397_B')
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Bootloader is optional for this device.",
              style: TextStyle(color: Colors.orange, fontSize: 14),
            ),
          ),
      ],
    );
  }

  Future<void> _onFileUpload(String type, StateSetter setState) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      try {
        String filePath = file.path!;
        final bytes = await File(filePath).readAsBytes();
        setState(() {
          if (type == 'application') {
            application = bytes;
          } else if (type == 'bootloader') {
            bootloader = bytes;
          }
        });
        // Snackbar.show(ABC.c, "$type has been uploaded.", success: true);
      } catch (e) {
        Snackbar.show(ABC.c, prettyException("$type Upload Error:", e),
            success: false);
      }
    } else {
      Snackbar.show(ABC.c, "No file selected", success: false);
    }
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
              actions: [],
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () async {
                  widget.tcDeviceSdk.performScan();
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  buildRemoteId(context),
                  ListTile(),
                  buildActionButtons(context)
                ],
              ),
            ),
          ),
        ),
      ],
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
        ],
      ),
    );
  }

  Widget buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onFirmwareUpdate,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            elevation: 5,
          ),
          child: const Text(
            "Update Firmware",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
