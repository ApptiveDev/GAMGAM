import 'package:flutter/foundation.dart';

import '../data/mock_appointment_repository.dart';
import '../models/appointment.dart';

class RecordController extends ChangeNotifier {
  RecordController({MockAppointmentRepository? repository}) : _repository = repository ?? const MockAppointmentRepository();

  final MockAppointmentRepository _repository;
  List<Appointment> get completedAppointments => _repository.appointments.where((appointment) => appointment.status == AppointmentStatus.completed).toList();
  int get monthlyMeetups => 3;
  String get averageArrival => '4 min early';
  int get lateCount => 1;
}
