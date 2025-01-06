import 'package:flutter/material.dart';
import 'package:tirecheck_device_sdk_flutter/tirecheck_device_sdk.dart';

class BridgeOtaResultTile extends StatefulWidget {
  const BridgeOtaResultTile(
      {Key? key, required this.processedDevice, this.onTap})
      : super(key: key);

  final ProcessedDevice processedDevice;
  final VoidCallback? onTap;

  @override
  State<BridgeOtaResultTile> createState() => _BridgeOtaResultTileState();
}

class _BridgeOtaResultTileState extends State<BridgeOtaResultTile> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildTitle(BuildContext context) {
    if (widget.processedDevice.processedDevice is BleBridgeOta) {
      final bleBridgeOta =
          widget.processedDevice.processedDevice as BleBridgeOta;
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            bleBridgeOta.name,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            bleBridgeOta.id,
            style: Theme.of(context).textTheme.bodySmall,
          )
        ],
      );
    } else {
      return const Text('Unknown Device');
    }
  }

  Widget _buildConnectButton(BuildContext context) {
    // Will be helpful for bridge OTA
    bool isConnectable = false;
    if (widget.processedDevice.processedDevice is BleBridgeOta) {
      isConnectable =
          true; // Assuming BleBridgeOta is always connectable for this example
    }

    return ElevatedButton(
      child: const Text('OPEN OTA'), // Open regardless of connection status
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      onPressed: widget.onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(widget.processedDevice.processedDevice is BleBridgeOta
          ? (widget.processedDevice.processedDevice as BleBridgeOta)
              .rssi
              .toString()
          : 'N/A'),
      trailing: _buildConnectButton(context),
    );
  }
}
