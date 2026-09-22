import 'package:flutter/material.dart';

import '../../controllers/home_controller.dart';
import '../../models/appointment.dart';
import '../../routes/app_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.controller});

  final HomeController? controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? HomeController();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final closest = _controller.closestAppointment;
          return Scaffold(
            appBar: AppBar(title: const Text('My appointments')),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pushNamed(AppRouter.createAppointment),
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            ),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Coming up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _ClosestAppointmentCard(appointment: closest),
                const SizedBox(height: 28),
                const Text('Scheduled', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._controller.upcoming.skip(1).map(_AppointmentTile.new),
                const SizedBox(height: 24),
                const Text('Past appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._controller.past.map(_AppointmentTile.new),
              ],
            ),
          );
        },
      );
}

class _ClosestAppointmentCard extends StatelessWidget {
  const _ClosestAppointmentCard({required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (appointment.locationSharingActive) const Chip(label: Text('Location sharing active')),
            Text(appointment.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${appointment.placeName} · Sep 26, 12:00 PM'),
            const SizedBox(height: 16),
            const Text('5 days left', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(spacing: 6, children: appointment.participants.map((participant) => CircleAvatar(radius: 16, child: Text(participant.initials))).toList()),
          ]),
        ),
      );
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile(this.appointment);
  final Appointment appointment;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(appointment.name),
        subtitle: Text('${appointment.placeName} · ${appointment.participants.length} people'),
        trailing: Icon(appointment.status == AppointmentStatus.completed ? Icons.check_circle_outline : Icons.chevron_right),
      );
}
