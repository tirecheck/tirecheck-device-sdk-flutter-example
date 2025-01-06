import 'package:flutter/material.dart';
import 'package:tirecheck_device_sdk_flutter/tirecheck_device_sdk.dart';

class BridgeResultTile extends StatefulWidget {
  const BridgeResultTile({Key? key, required this.processedDevice, this.onTap})
      : super(key: key);

  final ProcessedDevice processedDevice;
  final VoidCallback? onTap;

  @override
  State<BridgeResultTile> createState() => _BridgeResultTileState();
}

class _BridgeResultTileState extends State<BridgeResultTile> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildTitle(BuildContext context) {
    if (widget.processedDevice.processedDevice is BleBridge) {
      final bleBridge = widget.processedDevice.processedDevice as BleBridge;
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            bleBridge.name,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            bleBridge.id,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'VIN: ${bleBridge.vin != '' ? bleBridge.vin : '-'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    } else {
      return const Text('Unknown Device');
    }
  }

  Widget _buildConnectButton(BuildContext context) {
    // Will be helpful for bridge OTA
    bool isConnectable = false;
    if (widget.processedDevice.processedDevice is BleBridge) {
      isConnectable = (widget.processedDevice.processedDevice as BleBridge)
              .advertisingData !=
          null;
    }

    return ElevatedButton(
      child: const Text('OPEN'), // Open regardless of connection status
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      onPressed: widget.onTap,
    );
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var advData = widget.processedDevice.processedDevice is BleBridge
        ? (widget.processedDevice.processedDevice as BleBridge).advertisingData
        : null;

    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(widget.processedDevice.processedDevice is BleBridge
          ? (widget.processedDevice.processedDevice as BleBridge)
              .rssi
              .toString()
          : 'N/A'),
      trailing: _buildConnectButton(context),
      children: <Widget>[
        if (advData != null && advData.fwVersion != null)
          _buildAdvRow(context, 'FW Version', advData.fwVersion!),
        if (advData != null)
          _buildAdvRow(
              context, 'Config Version', advData.configVersion.toString()),
      ],
    );
  }
}
