import 'package:flutter/foundation.dart';

import '../data/mock_appointment_repository.dart';
import '../models/appointment.dart';

class HomeController extends ChangeNotifier {
  HomeController({MockAppointmentRepository? repository}) : _repository = repository ?? const MockAppointmentRepository();

  final MockAppointmentRepository _repository;

  List<Appointment> get upcoming => _repository.appointments.where((appointment) => appointment.status != AppointmentStatus.completed).toList();
  List<Appointment> get past => _repository.appointments.where((appointment) => appointment.status == AppointmentStatus.completed).toList();
  Appointment get closestAppointment => upcoming.first;
}
