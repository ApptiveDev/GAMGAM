enum ArrivalStatus { atHome, onTheWay, arrivingSoon, arrived, sharingOff }

class Participant {
  const Participant({required this.id, required this.name, required this.initials, required this.status, this.etaMinutes, this.transport = 'walk'});

  final String id;
  final String name;
  final String initials;
  final ArrivalStatus status;
  final int? etaMinutes;
  final String transport;
}
