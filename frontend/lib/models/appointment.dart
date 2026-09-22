import 'participant.dart';

enum AppointmentStatus { coordinating, confirmed, completed }

class Appointment {
  const Appointment({required this.id, required this.name, required this.dateTime, required this.placeName, required this.participants, required this.status, required this.penalty, this.locationSharingActive = false});

  final String id;
  final String name;
  final DateTime dateTime;
  final String placeName;
  final List<Participant> participants;
  final AppointmentStatus status;
  final String penalty;
  final bool locationSharingActive;
}
