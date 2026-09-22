import 'package:flutter/material.dart';

class TemplatePage extends StatelessWidget {
  const TemplatePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create appointment')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('How should we decide?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...['I decide everything', 'Vote on time', 'Vote on place', 'Vote on both'].map((label) => Card(child: ListTile(title: Text(label), trailing: const Icon(Icons.chevron_right)))),
            const Spacer(),
            const TextField(decoration: InputDecoration(labelText: 'Appointment name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            FilledButton(onPressed: () {}, child: const Text('Next')),
          ]),
        ),
      );
}
