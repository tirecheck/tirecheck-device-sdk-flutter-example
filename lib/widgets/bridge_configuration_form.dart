import 'package:flutter/material.dart';
import 'package:tirecheck_device_sdk_flutter/tirecheck_device_sdk.dart';

class MutableBridgeConfiguration {
  Map<String, dynamic> customerCANSettings;
  Map<String, dynamic> workshopCANSettings;
  // Map<String, dynamic> bridgeConfiguration;
  Map<String, dynamic> customerPressureThresholds;
  Map<String, dynamic> customerTemperatureThresholds;
  Map<String, dynamic> customerImbalanceThresholds;
  Map<String, dynamic> pressuresPerAxle;
  Map<String, dynamic>? autolearnSettings;

  MutableBridgeConfiguration({
    required this.customerCANSettings,
    required this.workshopCANSettings,
    // required this.bridgeConfiguration,
    required this.customerPressureThresholds,
    required this.customerTemperatureThresholds,
    required this.customerImbalanceThresholds,
    required this.pressuresPerAxle,
    this.autolearnSettings,
  });

  factory MutableBridgeConfiguration.fromBridgeConfiguration(
      BridgeConfiguration config) {
    return MutableBridgeConfiguration(
      customerCANSettings:
          Map<String, dynamic>.from(config.customerCANSettings),
      workshopCANSettings:
          Map<String, dynamic>.from(config.workshopCANSettings),
      // bridgeConfiguration: Map<String, dynamic>.from(config.bridgeConfiguration),
      customerPressureThresholds:
          Map<String, dynamic>.from(config.customerPressureThresholds),
      customerTemperatureThresholds:
          Map<String, dynamic>.from(config.customerTemperatureThresholds),
      customerImbalanceThresholds:
          Map<String, dynamic>.from(config.customerImbalanceThresholds),
      pressuresPerAxle: Map<String, dynamic>.from(config.pressuresPerAxle),
      autolearnSettings: config.autolearnSettings != null
          ? Map<String, dynamic>.from(config.autolearnSettings!)
          : null,
    );
  }

  BridgeConfiguration toBridgeConfiguration() {
    return BridgeConfiguration(
      customerCANSettings: Map<String, dynamic>.from(customerCANSettings),
      workshopCANSettings: Map<String, dynamic>.from(workshopCANSettings),
      // bridgeConfiguration: Map<String, dynamic>.from(bridgeConfiguration),
      customerPressureThresholds:
          Map<String, dynamic>.from(customerPressureThresholds),
      customerTemperatureThresholds:
          Map<String, dynamic>.from(customerTemperatureThresholds),
      customerImbalanceThresholds:
          Map<String, dynamic>.from(customerImbalanceThresholds),
      pressuresPerAxle: Map<String, dynamic>.from(pressuresPerAxle),
      autolearnSettings: autolearnSettings != null
          ? Map<String, dynamic>.from(autolearnSettings!)
          : null,
    );
  }

  toJson() {
    return {
      'customerCANSettings': customerCANSettings,
      'workshopCANSettings': workshopCANSettings,
      // 'bridgeConfiguration': bridgeConfiguration,
      'customerPressureThresholds': customerPressureThresholds,
      'customerTemperatureThresholds': customerTemperatureThresholds,
      'customerImbalanceThresholds': customerImbalanceThresholds,
      'pressuresPerAxle': pressuresPerAxle,
      'autolearnSettings': autolearnSettings,
    };
  }
}

class BridgeConfigurationForm extends StatefulWidget {
  final BridgeConfiguration configuration;
  final TcDeviceSdk tcDeviceSdk;
  final ProcessedDevice device;

  const BridgeConfigurationForm({
    Key? key,
    required this.configuration,
    required this.tcDeviceSdk,
    required this.device,
  }) : super(key: key);

  @override
  _ConfigurationDataFormState createState() => _ConfigurationDataFormState();
}

class _ConfigurationDataFormState extends State<BridgeConfigurationForm> {
  late MutableBridgeConfiguration mutableConfiguration;
  final Map<String, TextEditingController> thresholdControllers = {};
  late final _device;
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
  void initState() {
    super.initState();
    _device = widget.device.processedDevice is BleBridge
        ? widget.device.processedDevice as BleBridge
        : widget.device.processedDevice as BleBridgeOta;
    mutableConfiguration = MutableBridgeConfiguration.fromBridgeConfiguration(
        widget.configuration);
    initializeControllers();
  }

  void initializeControllers() {
    final thresholds =
        mutableConfiguration.customerPressureThresholds['axle01'];
    thresholdControllers['overinflationWarning'] = TextEditingController(
        text: int.parse(thresholds.substring(2, 4), radix: 16).toString());
    thresholdControllers['overinflationCritical'] = TextEditingController(
        text: int.parse(thresholds.substring(0, 2), radix: 16).toString());
    thresholdControllers['underinflationWarning'] = TextEditingController(
        text: int.parse(thresholds.substring(4, 6), radix: 16).toString());
    thresholdControllers['underinflationCritical'] = TextEditingController(
        text: int.parse(thresholds.substring(6, 8), radix: 16).toString());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4.0,
      child: ExpansionTile(
        title: Text('Edit Configuration',
            style: Theme.of(context).textTheme.titleLarge),
        children: [
          ExpansionTile(
            title: const Text('Workshop CAN Settings'),
            children: [
              SwitchListTile(
                title: const Text('CAN Termination'),
                value: mutableConfiguration
                        .workshopCANSettings['canTermination'] ==
                    '01',
                onChanged: (value) {
                  setState(() {
                    mutableConfiguration.workshopCANSettings['canTermination'] =
                        value ? '01' : '00';
                  });
                },
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Customer Pressure Thresholds'),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: thresholdControllers['overinflationWarning'],
                  decoration: const InputDecoration(
                    labelText: 'Overinflation Warning Value',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      mutableConfiguration.customerPressureThresholds[
                          'axle01'] = mutableConfiguration
                              .customerPressureThresholds['axle01']
                              .substring(0, 2) +
                          int.parse(value).toRadixString(16).padLeft(2, '0') +
                          mutableConfiguration
                              .customerPressureThresholds['axle01']
                              .substring(4);
                    });
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: thresholdControllers['overinflationCritical'],
                  decoration: const InputDecoration(
                    labelText: 'Overinflation Critical Value',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      mutableConfiguration
                              .customerPressureThresholds['axle01'] =
                          int.parse(value).toRadixString(16).padLeft(2, '0') +
                              mutableConfiguration
                                  .customerPressureThresholds['axle01']
                                  .substring(2);
                    });
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: thresholdControllers['underinflationWarning'],
                  decoration: const InputDecoration(
                    labelText: 'Underinflation Warning Value',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      mutableConfiguration.customerPressureThresholds[
                          'axle01'] = mutableConfiguration
                              .customerPressureThresholds['axle01']
                              .substring(0, 4) +
                          int.parse(value).toRadixString(16).padLeft(2, '0') +
                          mutableConfiguration
                              .customerPressureThresholds['axle01']
                              .substring(6);
                    });
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: thresholdControllers['underinflationCritical'],
                  decoration: const InputDecoration(
                    labelText: 'Underinflation Critical Value',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      int intValue = int.parse(value);
                      if (intValue > 20) {
                        intValue = 20;
                        thresholdControllers['underinflationCritical']?.text =
                            '20';
                      }
                      mutableConfiguration
                              .customerPressureThresholds['axle01'] =
                          mutableConfiguration
                                  .customerPressureThresholds['axle01']
                                  .substring(0, 6) +
                              intValue.toRadixString(16).padLeft(2, '0');
                    });
                  },
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Customer Temperature Thresholds'),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: TextEditingController(
                    text: getTemperatureThresholdValue(mutableConfiguration
                            .customerTemperatureThresholds['axle01'])
                        .toString(),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'High Temperature Value',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      final intValue = int.parse(value) + 40;
                      mutableConfiguration
                              .customerTemperatureThresholds['axle01'] =
                          intValue.toRadixString(16).padLeft(2, '0');
                    });
                  },
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Customer Imbalance Thresholds'),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: TextEditingController(
                    text: getImbalanceValue(mutableConfiguration
                            .customerImbalanceThresholds['axle01'][0])
                        .toString(),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Pressure Imbalance Value',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      final intValue = int.parse(value);
                      mutableConfiguration
                              .customerImbalanceThresholds['axle01'] =
                          intValue.toRadixString(16).padLeft(1, '0') +
                              mutableConfiguration
                                  .customerImbalanceThresholds['axle01']
                                  .substring(1);
                    });
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: TextEditingController(
                    text: getImbalanceValue(mutableConfiguration
                            .customerImbalanceThresholds['axle01'][1])
                        .toString(),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Temperature Imbalance Value',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      final intValue = int.parse(value);
                      mutableConfiguration
                              .customerImbalanceThresholds['axle01'] =
                          mutableConfiguration
                                  .customerImbalanceThresholds['axle01']
                                  .substring(0, 1) +
                              intValue.toRadixString(16).padLeft(1, '0');
                    });
                  },
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Customer CAN Settings'),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('CAN Protocol'),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              mutableConfiguration
                                  .customerCANSettings['canProtocol'] = '00';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mutableConfiguration
                                        .customerCANSettings['canProtocol'] ==
                                    '00'
                                ? Colors.red
                                : const Color.fromARGB(255, 207, 207, 207),
                            foregroundColor: mutableConfiguration
                                        .customerCANSettings['canProtocol'] ==
                                    '00'
                                ? Colors.white
                                : Colors.black,
                          ),
                          child: const Text('J1939'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              mutableConfiguration
                                  .customerCANSettings['canProtocol'] = '01';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mutableConfiguration
                                        .customerCANSettings['canProtocol'] ==
                                    '01'
                                ? Colors.red
                                : const Color.fromARGB(255, 207, 207, 207),
                            foregroundColor: mutableConfiguration
                                        .customerCANSettings['canProtocol'] ==
                                    '01'
                                ? Colors.white
                                : Colors.black,
                          ),
                          child: const Text('ECE-R141'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('CAN Mode'),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              mutableConfiguration.customerCANSettings[
                                      'transparentFilteredMode'] =
                                  mutableConfiguration.customerCANSettings[
                                          'transparentFilteredMode'][0] +
                                      '0';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                mutableConfiguration.customerCANSettings[
                                            'transparentFilteredMode'][1] ==
                                        '0'
                                    ? Colors.red
                                    : const Color.fromARGB(255, 207, 207, 207),
                            foregroundColor:
                                mutableConfiguration.customerCANSettings[
                                            'transparentFilteredMode'][1] ==
                                        '0'
                                    ? Colors.white
                                    : Colors.black,
                          ),
                          child: const Text('Transparent'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              mutableConfiguration.customerCANSettings[
                                      'transparentFilteredMode'] =
                                  mutableConfiguration.customerCANSettings[
                                          'transparentFilteredMode'][0] +
                                      '1';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                mutableConfiguration.customerCANSettings[
                                            'transparentFilteredMode'][1] ==
                                        '1'
                                    ? Colors.red
                                    : const Color.fromARGB(255, 207, 207, 207),
                            foregroundColor:
                                mutableConfiguration.customerCANSettings[
                                            'transparentFilteredMode'][1] ==
                                        '1'
                                    ? Colors.white
                                    : Colors.black,
                          ),
                          child: const Text('Filtered'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('BLE Mode'),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              mutableConfiguration.customerCANSettings[
                                      'transparentFilteredMode'] =
                                  '0' +
                                      mutableConfiguration.customerCANSettings[
                                          'transparentFilteredMode'][1];
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                mutableConfiguration.customerCANSettings[
                                            'transparentFilteredMode'][0] ==
                                        '0'
                                    ? Colors.red
                                    : const Color.fromARGB(255, 207, 207, 207),
                            foregroundColor:
                                mutableConfiguration.customerCANSettings[
                                            'transparentFilteredMode'][0] ==
                                        '0'
                                    ? Colors.white
                                    : Colors.black,
                          ),
                          child: const Text('Transparent'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              mutableConfiguration.customerCANSettings[
                                      'transparentFilteredMode'] =
                                  '1' +
                                      mutableConfiguration.customerCANSettings[
                                          'transparentFilteredMode'][1];
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                mutableConfiguration.customerCANSettings[
                                            'transparentFilteredMode'][0] ==
                                        '1'
                                    ? Colors.red
                                    : const Color.fromARGB(255, 207, 207, 207),
                            foregroundColor:
                                mutableConfiguration.customerCANSettings[
                                            'transparentFilteredMode'][0] ==
                                        '1'
                                    ? Colors.white
                                    : Colors.black,
                          ),
                          child: const Text('Filtered'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Center(
            child: ElevatedButton(
              onPressed: _updateConfigurationData,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                "Update Bridge Configuration",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateConfigurationData() async {
    for (int i = 2; i <= 16; i++) {
      String axleKey = 'axle${i.toString().padLeft(2, '0')}';
      mutableConfiguration.customerPressureThresholds[axleKey] =
          mutableConfiguration.customerPressureThresholds['axle01'];
      mutableConfiguration.customerTemperatureThresholds[axleKey] =
          mutableConfiguration.customerTemperatureThresholds['axle01'];
      mutableConfiguration.customerImbalanceThresholds[axleKey] =
          mutableConfiguration.customerImbalanceThresholds['axle01'];
    }
    await widget.tcDeviceSdk.bridge.setConfiguration(
        _device.id, mutableConfiguration.toBridgeConfiguration());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Configuration updated")),
      );
    }
  }
}
