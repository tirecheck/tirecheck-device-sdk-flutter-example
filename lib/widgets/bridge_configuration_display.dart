import 'package:flutter/material.dart';
import 'package:tirecheck_device_sdk_flutter/tirecheck_device_sdk.dart';

class BridgeConfigurationDisplayWidget extends StatelessWidget {
  final BridgeConfiguration? bridgeConfiguration;

  const BridgeConfigurationDisplayWidget({
    Key? key,
    required this.bridgeConfiguration,
  }) : super(key: key);

  int getTemperatureThresholdValue(String hex) {
    final decimalValue = int.parse(hex, radix: 16);
    return decimalValue - 40;
  }

  int getImbalanceValue(String byte) {
    if (byte == '0') return 0;
    final binary = int.parse(byte, radix: 16).toRadixString(2);
    return int.parse(binary, radix: 2);
  }

  @override
  Widget build(BuildContext context) {
    if (bridgeConfiguration == null) {
      return Container();
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4.0,
      child: ExpansionTile(
        title: Text('Bridge Configuration',
            style: Theme.of(context).textTheme.titleLarge),
        children: [
          ExpansionTile(
            title: const Text('Workshop CAN Settings'),
            children: [
              ListTile(
                title: const Text('CAN Termination'),
                subtitle: Text(
                    'Termination: ${bridgeConfiguration!.workshopCANSettings['canTermination'] == '01' ? 'On' : 'Off'}'),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Customer Pressure Thresholds'),
            children: [
              ListTile(
                title: Text('Overinflation Warning'),
                subtitle: Text(
                    'Value: ${int.parse(bridgeConfiguration!.customerPressureThresholds['axle01'].substring(2, 4), radix: 16)} %'),
              ),
              ListTile(
                title: Text('Overinflation Critical'),
                subtitle: Text(
                    'Value: ${int.parse(bridgeConfiguration!.customerPressureThresholds['axle01'].substring(0, 2), radix: 16)} %'),
              ),
              ListTile(
                title: Text('Underinflation Warning'),
                subtitle: Text(
                    'Value: ${int.parse(bridgeConfiguration!.customerPressureThresholds['axle01'].substring(4, 6), radix: 16)} %'),
              ),
              ListTile(
                title: Text('Underinflation Critical'),
                subtitle: Text(
                    'Value: ${int.parse(bridgeConfiguration!.customerPressureThresholds['axle01'].substring(6, 8), radix: 16)} %'),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('Customer Temperature Thresholds'),
            children: [
              ListTile(
                title: Text('High Temperature'),
                subtitle: Text(
                    'High Temperature ${getTemperatureThresholdValue(bridgeConfiguration!.customerTemperatureThresholds['axle01'])} °C'),
              )
            ],
          ),
          ExpansionTile(
            title: const Text('Customer Imbalance Thresholds'),
            children: [
              ListTile(
                title: Text('Pressure Imbalance'),
                subtitle: Text(
                    'Value ${getImbalanceValue(bridgeConfiguration!.customerImbalanceThresholds['axle01'][0])}'),
              ),
              ListTile(
                title: Text('Temperature Imbalance'),
                subtitle: Text(
                    'Value ${getImbalanceValue(bridgeConfiguration!.customerImbalanceThresholds['axle01'][1])}'),
              ),
            ],
          ),
          ExpansionTile(title: Text('Customer CAN Settings'), children: [
            ListTile(
              title: const Text('CAN Protocol'),
              subtitle: Text(
                  'Protocol: ${bridgeConfiguration!.customerCANSettings['canProtocol'] == '01' ? 'ECE-R141' : 'J1939'}'),
            ),
            ListTile(
              title: const Text('CAN Mode'),
              subtitle: Text(
                  'Mode: ${bridgeConfiguration!.customerCANSettings['transparentFilteredMode'][1] == '1' ? 'Filtered' : 'Transparent'}'),
            ),
            ListTile(
              title: const Text('BLE Mode'),
              subtitle: Text(
                  'Mode: ${bridgeConfiguration!.customerCANSettings['transparentFilteredMode'][0] == '1' ? 'Filtered' : 'Transparent'}'),
            ),
          ]),
          // ExpansionTile(title: Text('Bridge Info'),
          // children: [
          //   ListTile(
          //     title: const Text('Bridge Version'),
          //     subtitle: Text('Version: ${bridgeConfiguration!.bridgeConfiguration['softwareVersion']}'),
          //   ),
          //   ListTile(
          //     title: const Text('Manufacturer'),
          //     subtitle: Text('Version: ${bridgeConfiguration!.bridgeConfiguration['manufacturerName']}'),
          //   ),
          // ],)
        ],
      ),
    );
  }
}
