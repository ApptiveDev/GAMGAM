import '../models/appointment.dart';
import '../models/arrival_result.dart';
import '../models/location_share_setting.dart';
import '../models/participant.dart';
import '../models/poll.dart';
import '../models/poke.dart';

class MockAppointmentRepository {
  const MockAppointmentRepository();

  List<Appointment> get appointments => [
        Appointment(id: 'appointment-1', name: 'Saturday brunch', dateTime: DateTime(2026, 9, 26, 12), placeName: 'Seongsu Cafe Street', status: AppointmentStatus.confirmed, penalty: 'Late by 10 minutes: buy coffee', locationSharingActive: true, participants: const [
          Participant(id: 'u1', name: 'Yejun', initials: 'YJ', status: ArrivalStatus.atHome, etaMinutes: 40),
          Participant(id: 'u2', name: 'Mina', initials: 'MN', status: ArrivalStatus.onTheWay, etaMinutes: 18, transport: 'subway'),
          Participant(id: 'u3', name: 'Jisoo', initials: 'JS', status: ArrivalStatus.onTheWay, etaMinutes: 25, transport: 'car'),
        ]),
        Appointment(id: 'appointment-2', name: 'Team dinner', dateTime: DateTime(2026, 9, 29, 19, 30), placeName: 'Euljiro 3-ga', status: AppointmentStatus.coordinating, penalty: 'No penalty', participants: const [
          Participant(id: 'u1', name: 'Yejun', initials: 'YJ', status: ArrivalStatus.atHome),
          Participant(id: 'u4', name: 'Hana', initials: 'HN', status: ArrivalStatus.sharingOff),
        ]),
        Appointment(id: 'appointment-3', name: 'Han River picnic', dateTime: DateTime(2026, 9, 7, 15), placeName: 'Yeouido Hangang Park', status: AppointmentStatus.completed, penalty: 'Late by 5 minutes: next meetup organizer', participants: const [
          Participant(id: 'u1', name: 'Yejun', initials: 'YJ', status: ArrivalStatus.arrived),
          Participant(id: 'u2', name: 'Mina', initials: 'MN', status: ArrivalStatus.arrived),
        ]),
      ];

  RoomPoll get roomPoll => const RoomPoll(
        timeOptions: [PollOption(label: 'Sep 29, 7:30 PM', voterIds: ['u1', 'u4'], voteCount: 2), PollOption(label: 'Sep 30, 7:00 PM', voterIds: ['u2'], voteCount: 1)],
        placeOptions: [PollOption(label: 'Euljiro 3-ga', voterIds: ['u1', 'u2'], voteCount: 2), PollOption(label: 'Ikseon-dong', voterIds: ['u4'], voteCount: 1)],
        pendingCount: 2,
      );

  List<LocationShareSetting> get locationShareOptions => const [
        LocationShareSetting(level: LocationShareLevel.off, title: 'Off', description: 'Friends only see that you have not left yet.'),
        LocationShareSetting(level: LocationShareLevel.basic, title: 'Basic (recommended)', description: 'Shows your ETA, never your home address.'),
        LocationShareSetting(level: LocationShareLevel.closeFriends, title: 'Close friends', description: 'Shows your home location on the map.'),
      ];

  PokeNotification get latestPoke => const PokeNotification(
        senderName: 'Yejun',
        message: PokeMessage.hurryUp,
        cooldownMinutes: 5,
      );

  List<ArrivalResult> get arrivalResults => const [
        ArrivalResult(participantId: 'u2', rank: 1, lateMinutes: 0),
        ArrivalResult(participantId: 'u1', rank: 2, lateMinutes: 0),
        ArrivalResult(
          participantId: 'u3',
          rank: 3,
          lateMinutes: 12,
          penalty: 'Buy coffee',
        ),
      ];
}
