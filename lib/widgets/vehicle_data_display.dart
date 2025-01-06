import 'package:flutter/material.dart';
import 'package:tirecheck_device_sdk_flutter/tirecheck_device_sdk.dart';

class VehicleDataWidget extends StatelessWidget {
  final BridgeTcVehicle vehicleData;
  final String Function(num) getPositionInfo;

  const VehicleDataWidget({
    Key? key,
    required this.vehicleData,
    required this.getPositionInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4.0,
      child: ExpansionTile(
        title:
            Text('Vehicle Data', style: Theme.of(context).textTheme.titleLarge),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vehicle Information',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8.0),
                Text('VIN: ${vehicleData.vin}',
                    style: Theme.of(context).textTheme.bodyLarge),
                Text('Number of Axles: ${vehicleData.axles.length}',
                    style: Theme.of(context).textTheme.bodyLarge),
                const Divider(height: 20.0, thickness: 1.0),
                for (var i = 0; i < vehicleData.axles.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Axle ${i + 1}:',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4.0),
                        Text(
                            'Target Pressure: ${vehicleData.axles[i].targetPressure}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('Is Steer: ${vehicleData.axles[i].isSteer}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('Is Spare: ${vehicleData.axles[i].isSpare}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('Is Drive: ${vehicleData.axles[i].isDrive}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('Is Lift: ${vehicleData.axles[i].isLift}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                            'Spaces Below: ${vehicleData.axles[i].spacesBelow}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                            'Max Target Pressure: ${vehicleData.axles[i].maxTargetPressure}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                            'Min Target Pressure: ${vehicleData.axles[i].minTargetPressure}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('Num of tyres: ${vehicleData.axles[i].tyresCount}',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                for (var tyre in vehicleData.tcTyres)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Mounted On: ${getPositionInfo(tyre.mountedOn?.positionId ?? 0)}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('Tyre Serial Number: ${tyre.serialNumber}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('Temperature: ${tyre.temperature}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('Pressure: ${tyre.pressure}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('TPMS Sensor: ${tyre.tcTpmsSensor?.id}',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on Map<String, String>? {
  get id => null;
}
