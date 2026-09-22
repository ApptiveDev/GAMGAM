import 'package:flutter/material.dart';

import '../../controllers/record_controller.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final _controller = RecordController();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Records')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _Stat(label: 'This month', value: '${_controller.monthlyMeetups}'),
            _Stat(label: 'Arrival', value: _controller.averageArrival),
            _Stat(label: 'Late', value: '${_controller.lateCount}'),
          ]))),
          const SizedBox(height: 24),
          const Text('Past appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ..._controller.completedAppointments.map((appointment) => ListTile(title: Text(appointment.name), subtitle: Text('${appointment.placeName} · Replay map available'), trailing: const Icon(Icons.chevron_right))),
        ]),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.bold)), Text(label)]);
}
