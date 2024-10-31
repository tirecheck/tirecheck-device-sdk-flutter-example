import 'package:flutter/material.dart';
import 'package:tirecheck_device_sdk_flutter/tirecheck_device_sdk.dart';

class VehicleSchemaDisplay extends StatefulWidget {
  final BridgeTcVehicle vehicleData;
  final String Function(num) getPositionInfo;
  final List<BridgeReading> bridgeReadings;

  const VehicleSchemaDisplay({
    Key? key,
    required this.vehicleData,
    required this.getPositionInfo,
    required this.bridgeReadings,
  }) : super(key: key);

  @override
  _VehicleSchemaDisplayState createState() => _VehicleSchemaDisplayState();
}

class _VehicleSchemaDisplayState extends State<VehicleSchemaDisplay> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> axlesWidgets = _buildAxleWidgets();
    final issueTable = _buildIssueTable();

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4.0,
      child: ExpansionTile(
        title: Text('Vehicle Layout',
            style: Theme.of(context).textTheme.titleLarge),
        children: [
          ...axlesWidgets,
          if (issueTable != null) issueTable,
        ],
      ),
    );
  }

  // Extract axle and tyre information to organize into widgets
  List<Widget> _buildAxleWidgets() {
    final List<Widget> axlesWidgets = [];
    BridgeTcTyre? spare1;
    BridgeTcTyre? spare2;

    final axles = <int, List<BridgeTcTyre?>>{};
    for (var tyre in widget.vehicleData.tcTyres) {
      final positionId = tyre.mountedOn?.positionId ?? 0;
      final axle = (positionId / 100).floor();
      final position = (positionId / 10).floor() % 10;
      final maxTyres = positionId % 10;

      if (axle == 0) {
        if (spare1 == null) {
          spare1 = tyre;
        } else {
          spare2 = tyre;
        }
      } else {
        if (!axles.containsKey(axle)) {
          axles[axle] = List.filled(maxTyres, null);
        }
        axles[axle]![position - 1] = tyre;
      }
    }

    if (spare1 != null || spare2 != null) {
      axlesWidgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (spare1 != null) _buildTyreWidget(spare1!, isSpare: true),
            if (spare2 != null) _buildTyreWidget(spare2!, isSpare: true),
          ],
        ),
      );
    }

    axles.entries.forEach((entry) {
      final axle = entry.key;
      final tyres = entry.value;

      axlesWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (tyres.length == 4) ...[
                _buildTyreWidget(tyres[0]), // Left inner tyre
                _buildTyreWidget(tyres[1]), // Left outer tyre
                _buildAxleWidget(axle), // Axle in the center
                _buildTyreWidget(tyres[2]), // Right inner tyre
                _buildTyreWidget(tyres[3]), // Right outer tyre
              ] else ...[
                _buildTyreWidget(tyres[0]), // Left tyre
                _buildAxleWidget(axle), // Axle in the center
                _buildTyreWidget(tyres[1]), // Right tyre
              ]
            ],
          ),
        ),
      );
    });

    return axlesWidgets;
  }

  // Widget to build tyre widget for each axle
  Widget _buildTyreWidget(BridgeTcTyre? tyre, {bool isSpare = false}) {
    final label = tyre != null
        ? widget.getPositionInfo(tyre.mountedOn?.positionId ?? 0)
        : '';
    final tcTpmsId = tyre?.tcTpmsSensor?['id'];
    var sensorReading = null;
    if (tcTpmsId != null && widget.bridgeReadings.length > 0) {
      sensorReading = widget.bridgeReadings
          .where((element) => element.sensorId == tcTpmsId)
          .toList()[0];
    }
    return Container(
      width: 50,
      height: 60,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4.0),
        color: isSpare ? Colors.yellow[100] : Colors.grey[200],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          if (tcTpmsId != null)
            Text(
              tcTpmsId,
              style: const TextStyle(fontSize: 6, fontWeight: FontWeight.bold),
            ),
          if (sensorReading?.pressure?.bar != null)
            Text(
              '${sensorReading.pressure.bar.toStringAsFixed(2)} bar',
              style: const TextStyle(fontSize: 6, fontWeight: FontWeight.bold),
            ),
          if (sensorReading?.temperature?.celsius != null)
            Text(
              '${sensorReading.temperature.celsius.toStringAsFixed(2)} °C',
              style: const TextStyle(fontSize: 6, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  // Widget to build axle representation
  Widget _buildAxleWidget(int axleNumber) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: Text(
        axleNumber.toString(),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Widget to build a DataTable for BridgeTcIssue instances
  Widget? _buildIssueTable() {
    final issues = widget.bridgeReadings
        .where((reading) => reading.pressureIssue != null)
        .map((reading) => {
              'sensorId': reading.sensorId,
              'issueDate': reading.pressureIssue?.date,
              'issueType': reading.pressureIssue?.type,
              'severity': reading.pressureIssue?.severity,
            })
        .toList();

    if (issues.isEmpty) {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Sensor')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Severity')),
          ],
          rows: issues.map((issue) {
            return DataRow(cells: [
              DataCell(Text(issue['sensorId'] as String)),
              DataCell(Text(issue['issueType'] as String)),
              DataCell(Text(issue['severity'] as String)),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
