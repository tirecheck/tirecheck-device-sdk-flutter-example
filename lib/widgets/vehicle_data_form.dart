import 'package:flutter/material.dart';
import 'package:flutter_blue_plus_example/utils/snackbar.dart';
import 'package:tirecheck_device_sdk_flutter/tirecheck_device_sdk.dart';

class MutableTcTyreMountedOn {
  int? positionId;

  MutableTcTyreMountedOn({this.positionId});

  toJson() {
    return {
      'positionId': positionId,
    };
  }
}

class MutableBridgeTcVehicleAxle {
  double targetPressure;
  double minTargetPressure;
  double maxTargetPressure;
  bool? isSpare;
  bool? isSteer;
  bool? isDrive;
  bool? isLift;
  int spacesBelow;
  int tyresCount;

  MutableBridgeTcVehicleAxle({
    this.targetPressure = 0.0,
    this.minTargetPressure = 0.0,
    this.maxTargetPressure = 0.0,
    this.isSpare,
    this.isSteer,
    this.isDrive,
    this.isLift,
    this.spacesBelow = 0,
    this.tyresCount = 0,
  });

  toJson() {
    return {
      'targetPressure': targetPressure,
      'minTargetPressure': minTargetPressure,
      'maxTargetPressure': maxTargetPressure,
      'isSpare': isSpare,
      'isSteer': isSteer,
      'isDrive': isDrive,
      'isLift': isLift,
      'spacesBelow': spacesBelow,
      'tyresCount': tyresCount,
    };
  }
}

class MutableBridgeTcTyre {
  MutableTcTyreMountedOn? mountedOn;
  String? serialNumber;
  double? temperature;
  Map<String, String>? tcTpmsSensor;
  double? pressure;

  MutableBridgeTcTyre({
    this.mountedOn,
    this.serialNumber,
    this.temperature,
    this.tcTpmsSensor,
    this.pressure,
  });

  toJson() {
    return {
      'mountedOn': mountedOn?.toJson(),
      'serialNumber': serialNumber,
      'temperature': temperature,
      'tcTpmsSensor': tcTpmsSensor,
      'pressure': pressure,
    };
  }
}

class MutableBridgeTcVehicle {
  String? vin;
  List<MutableBridgeTcVehicleAxle> axles; // Change to mutable axle type
  List<MutableBridgeTcTyre> tcTyres;
  Map<String, String>? tcBridge;

  MutableBridgeTcVehicle({
    required this.vin,
    required this.axles,
    required this.tcTyres,
    this.tcBridge,
  });

  toJson() {
    return {
      'vin': vin,
      'axles': axles.map((axle) => axle.toJson()).toList(),
      'tcTyres': tcTyres.map((tyre) => tyre.toJson()).toList(),
      'tcBridge': tcBridge,
    };
  }

  // from BridgeTcVehicle to MutableBridgeTcVehicle
  factory MutableBridgeTcVehicle.fromBridgeTcVehicle(BridgeTcVehicle vehicle) {
    return MutableBridgeTcVehicle(
      vin: vehicle.vin,
      axles: vehicle.axles
          .map((axle) => MutableBridgeTcVehicleAxle(
                targetPressure: axle.targetPressure ?? 0.0,
                minTargetPressure: axle.minTargetPressure ?? 0.0,
                maxTargetPressure: axle.maxTargetPressure ?? 0.0,
                isSpare: axle.isSpare,
                isSteer: axle.isSteer,
                isDrive: axle.isDrive,
                isLift: axle.isLift,
                spacesBelow: axle.spacesBelow ?? 0,
                tyresCount: axle.tyresCount,
              ))
          .toList(),
      tcBridge: vehicle.tcBridge,
      tcTyres: vehicle.tcTyres.map((tyre) {
        return MutableBridgeTcTyre(
          mountedOn: tyre.mountedOn != null
              ? MutableTcTyreMountedOn(positionId: tyre.mountedOn!.positionId)
              : null,
          serialNumber: tyre.serialNumber,
          temperature: tyre.temperature,
          tcTpmsSensor: tyre.tcTpmsSensor,
          pressure: tyre.pressure,
        );
      }).toList(),
    );
  }

  // back to BridgeTcVehicle
  BridgeTcVehicle toBridgeTcVehicle() {
    return BridgeTcVehicle(
        vin: vin,
        axles: axles
            .map((axle) => BridgeTcVehicleAxle(
                  targetPressure: axle.targetPressure,
                  minTargetPressure: axle.minTargetPressure,
                  maxTargetPressure: axle.maxTargetPressure,
                  isSpare: axle.isSpare,
                  isSteer: axle.isSteer,
                  isDrive: axle.isDrive,
                  isLift: axle.isLift,
                  spacesBelow: axle.spacesBelow,
                  tyresCount: axle.tyresCount,
                ))
            .toList(),
        tcTyres: tcTyres.map((tyre) {
          return BridgeTcTyre(
            mountedOn: tyre.mountedOn != null
                ? TcTyreMountedOn(positionId: tyre.mountedOn!.positionId)
                : null,
            serialNumber: tyre.serialNumber,
            temperature: tyre.temperature,
            tcTpmsSensor: tyre.tcTpmsSensor,
            pressure: tyre.pressure,
          );
        }).toList(),
        tcBridge: tcBridge);
  }
}

class VehicleDataForm extends StatefulWidget {
  final BridgeTcVehicle vehicle;
  final TcDeviceSdk tcDeviceSdk;
  final ProcessedDevice device;
  final VoidCallback? onVehicleUpdated;
  const VehicleDataForm(
      {Key? key,
      required this.vehicle,
      required this.tcDeviceSdk,
      required this.device,
      this.onVehicleUpdated})
      : super(key: key);

  @override
  _VehicleDataFormState createState() => _VehicleDataFormState();
}

class _VehicleDataFormState extends State<VehicleDataForm> {
  late MutableBridgeTcVehicle mutableVehicle;
  final TextEditingController vinController = TextEditingController();
  late final _device;
  List<Map<String, TextEditingController>> axlesControllers = [];
  List<Map<String, TextEditingController>> tyresControllers = [];
  @override
  void initState() {
    super.initState();

    _device = widget.device.processedDevice is BleBridge
        ? widget.device.processedDevice as BleBridge
        : widget.device.processedDevice as BleBridgeOta;

    // Convert BridgeTcVehicle to MutableBridgeTcVehicle
    mutableVehicle = MutableBridgeTcVehicle.fromBridgeTcVehicle(widget.vehicle);
    vinController.text = mutableVehicle.vin ?? '';
    axlesControllers = mutableVehicle.axles.map((axle) {
      return {
        'tyresCount': TextEditingController(text: axle.tyresCount.toString()),
        'minTargetPressure':
            TextEditingController(text: axle.minTargetPressure.toString()),
        'targetPressure':
            TextEditingController(text: axle.targetPressure.toString()),
        'maxTargetPressure':
            TextEditingController(text: axle.maxTargetPressure.toString()),
      };
    }).toList();

    tyresControllers = mutableVehicle.tcTyres.map((tyre) {
      return {
        'positionId': TextEditingController(
            text: tyre.mountedOn?.positionId.toString() ?? ''),
        'serialNumber': TextEditingController(text: tyre.serialNumber ?? ''),
        'tpmsSensorId':
            TextEditingController(text: tyre.tcTpmsSensor?['id'] ?? ''),
        'pressure':
            TextEditingController(text: tyre.pressure?.toString() ?? ''),
        'temperature':
            TextEditingController(text: tyre.temperature?.toString() ?? ''),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (mutableVehicle == null) {
      return Container();
    }

    // final vinController = TextEditingController(text: mutableVehicle.vin);
    // final axlesControllers = mutableVehicle.axles.map<TextEditingController>((axle) {
    //   return TextEditingController(text: axle.targetPressure.toString());
    // }).toList();

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4.0,
      child: ExpansionTile(
        title: Text('Edit Vehicle Information',
            style: Theme.of(context).textTheme.titleLarge),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: vinController,
                  decoration: const InputDecoration(labelText: 'VIN'),
                  maxLength: 17,
                  onChanged: (value) {
                    if (value.length > 17) {
                      vinController.text = value.substring(0, 17);
                      vinController.selection =
                          TextSelection.fromPosition(TextPosition(offset: 17));
                    }
                  },
                ),
                const Divider(height: 20.0, thickness: 1.0),
                for (var i = 0; i < mutableVehicle.axles.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Axle ${i + 1}:',
                                style: Theme.of(context).textTheme.titleMedium),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  // Remove axle from the list
                                  mutableVehicle.axles.removeAt(i);
                                  axlesControllers.removeAt(i);
                                });
                                Snackbar.show(ABC.a, "Axle ${i + 1} removed",
                                    success: true);
                              },
                            ),
                          ],
                        ),
                        TextField(
                          controller: axlesControllers[i]['tyresCount'],
                          decoration:
                              const InputDecoration(labelText: 'Tyres Count'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              mutableVehicle.axles[i].tyresCount =
                                  int.tryParse(value) ?? 0;
                            });
                          },
                        ),
                        TextField(
                          controller: axlesControllers[i]['minTargetPressure'],
                          decoration: const InputDecoration(
                              labelText: 'Min Target Pressure'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              mutableVehicle.axles[i].minTargetPressure =
                                  double.tryParse(value) ?? 0.0;
                            });
                          },
                        ),
                        TextField(
                          controller: axlesControllers[i]['targetPressure'],
                          decoration: const InputDecoration(
                              labelText: 'Target Pressure'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              mutableVehicle.axles[i].targetPressure =
                                  double.tryParse(value) ?? 0.0;
                            });
                          },
                        ),
                        TextField(
                          controller: axlesControllers[i]['maxTargetPressure'],
                          decoration: const InputDecoration(
                              labelText: 'Max Target Pressure'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              mutableVehicle.axles[i].maxTargetPressure =
                                  double.tryParse(value) ?? 0.0;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: onAddAxle,
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      backgroundColor: const Color.fromARGB(255, 27, 134, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    icon: Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      "Add Axle",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const Divider(height: 20.0, thickness: 1.0),
                for (var i = 0; i < mutableVehicle.tcTyres.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tyre ${i + 1}:',
                                style: Theme.of(context).textTheme.titleMedium),
                            // IconButton(
                            //   icon: Icon(Icons.delete, color: Colors.red),
                            //   onPressed: () {
                            //     setState(() {
                            //       mutableVehicle.tcTyres.removeAt(i);
                            //       tyresControllers.removeAt(i);
                            //     });
                            //     Snackbar.show(ABC.a, "Tyre ${i + 1} removed", success: true);
                            //   },
                            // ),
                          ],
                        ),
                        TextField(
                          controller: tyresControllers[i]['positionId'],
                          decoration:
                              const InputDecoration(labelText: 'Position ID'),
                          keyboardType: TextInputType.number,
                          readOnly: true,
                          onChanged: (value) {
                            setState(() {
                              mutableVehicle.tcTyres[i].mountedOn?.positionId =
                                  int.tryParse(value);
                            });
                          },
                        ),
                        TextField(
                          controller: tyresControllers[i]['serialNumber'],
                          decoration:
                              const InputDecoration(labelText: 'Serial Number'),
                          readOnly: true,
                          onChanged: (value) {
                            setState(() {
                              mutableVehicle.tcTyres[i].serialNumber = value;
                            });
                          },
                        ),
                        TextField(
                          controller: tyresControllers[i]['tpmsSensorId'],
                          decoration: const InputDecoration(
                              labelText: 'TPMS Sensor ID'),
                          onChanged: (value) {
                            setState(() {
                              if (mutableVehicle.tcTyres[i].tcTpmsSensor ==
                                  null) {
                                mutableVehicle.tcTyres[i].tcTpmsSensor = {
                                  'id': '',
                                };
                              }
                              mutableVehicle.tcTyres[i].tcTpmsSensor?['id'] =
                                  value.toUpperCase();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16.0),
                Center(
                  child: ElevatedButton(
                    onPressed: _updateVehicleData,
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      "Set Vehicle Data",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onAddAxle() {
    setState(() {
      // Add new axle
      mutableVehicle.axles.add(MutableBridgeTcVehicleAxle(
        targetPressure: 0.0,
        minTargetPressure: 0.0,
        maxTargetPressure: 0.0,
        tyresCount: 0,
        isSpare: false,
        isSteer: false,
        isDrive: false,
        isLift: false,
        spacesBelow: 0,
      ));

      // Add new set of controllers for this axle
      axlesControllers.add({
        'tyresCount': TextEditingController(text: '0'),
        'minTargetPressure': TextEditingController(text: '0.0'),
        'targetPressure': TextEditingController(text: '0.0'),
        'maxTargetPressure': TextEditingController(text: '0.0'),
      });
    });
    Snackbar.show(ABC.a, "New axle added", success: true);
  }

  Future<void> _updateVehicleData() async {
    // Directly update the mutableVehicle data without setState
    mutableVehicle.vin = vinController.text;

    // Update axles
    for (var i = 0; i < axlesControllers.length; i++) {
      mutableVehicle.axles[i].tyresCount =
          int.tryParse(axlesControllers[i]['tyresCount']!.text) ?? 0;
      mutableVehicle.axles[i].minTargetPressure =
          double.tryParse(axlesControllers[i]['minTargetPressure']!.text) ??
              0.0;
      mutableVehicle.axles[i].targetPressure =
          double.tryParse(axlesControllers[i]['targetPressure']!.text) ?? 0.0;
      mutableVehicle.axles[i].maxTargetPressure =
          double.tryParse(axlesControllers[i]['maxTargetPressure']!.text) ??
              0.0;
    }

    // Update tyres
    for (var i = 0; i < tyresControllers.length; i++) {
      mutableVehicle.tcTyres[i].mountedOn?.positionId =
          int.tryParse(tyresControllers[i]['positionId']!.text);
      mutableVehicle.tcTyres[i].serialNumber =
          tyresControllers[i]['serialNumber']!.text;
      mutableVehicle.tcTyres[i].tcTpmsSensor?['id'] =
          tyresControllers[i]['tpmsSensorId']!.text;
      mutableVehicle.tcTyres[i].pressure =
          double.tryParse(tyresControllers[i]['pressure']!.text);
      mutableVehicle.tcTyres[i].temperature =
          double.tryParse(tyresControllers[i]['temperature']!.text);
    }

    await widget.tcDeviceSdk.bridge
        .setVehicle(_device.id, mutableVehicle.toBridgeTcVehicle());
    if (widget.onVehicleUpdated != null) {
      widget.onVehicleUpdated!();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vehicle data updated")),
      );
    }
  }
}
