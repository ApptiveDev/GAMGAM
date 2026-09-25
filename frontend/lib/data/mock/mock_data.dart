import '../models/appointment.dart';
import '../models/decision_template.dart';
import '../models/participant.dart';
import '../models/place.dart';
import '../models/vote_option.dart';

/// 와이어프레임에 나오는 사람·약속 그대로. 날짜는 실행 시각 기준으로 만든다.
abstract final class MockData {
  static const me = Participant(id: 'u-yeeun', name: '예은');
  static const doyun = Participant(id: 'u-doyun', name: '도윤');
  static const seoa = Participant(id: 'u-seoa', name: '서아');
  static const minjun = Participant(id: 'u-minjun', name: '민준', hasApp: false);
  static const harin = Participant(id: 'u-harin', name: '하린');

  /// 새로 만든 방에 링크로 들어오는 친구들 (목업 연출용).
  static const friends = [doyun, seoa, minjun];

  static const yeonnam = Place(name: '연남동 소금집 델리', description: '홍대입구역 도보 6분');
  static const mangwon = Place(name: '망원 시장 골목', description: '망원역 도보 3분');

  static List<Appointment> appointments(DateTime now) {
    DateTime at(int days, int hour, [int minute = 0]) => DateTime(now.year, now.month, now.day + days, hour, minute);

    return [
      Appointment(
        id: 'a-hongdae',
        name: '홍대 저녁 모임',
        template: DecisionTemplate.voteBoth,
        hostId: me.id,
        inviteCode: 'HONGDAE',
        status: AppointmentStatus.confirmed,
        participants: const [me, doyun, seoa, minjun, harin],
        confirmedTime: now.add(const Duration(hours: 1, minutes: 42)),
        confirmedPlace: const Place(name: '연남동 소금집 델리', description: '홍대입구역 3번 출구'),
        penalty: '커피 사기',
        penaltyAgreedIds: [me.id, doyun.id, seoa.id, minjun.id, harin.id],
      ),
      Appointment(
        id: 'a-hiking',
        name: '토요일 등산',
        template: DecisionTemplate.hostDecides,
        hostId: doyun.id,
        inviteCode: 'HIKING',
        status: AppointmentStatus.confirmed,
        participants: const [doyun, me, seoa],
        confirmedTime: at(6, 8),
        confirmedPlace: const Place(name: '북한산', description: '북한산우이역 2번 출구'),
        penalty: '다음 약속 총무',
        lateThresholdMinutes: 15,
        penaltyAgreedIds: [doyun.id, me.id, seoa.id],
      ),
      Appointment(
        id: 'a-donggi',
        name: '동기 모임',
        template: DecisionTemplate.voteBoth,
        hostId: me.id,
        inviteCode: 'DONGGI',
        participants: const [me, doyun, seoa, minjun],
        timeOptions: [
          TimeOption(id: 't1', value: at(4, 19), voterIds: [me.id, doyun.id]),
          TimeOption(id: 't2', value: at(5, 19, 30), voterIds: [doyun.id]),
        ],
        placeOptions: [
          PlaceOption(id: 'p1', value: yeonnam, voterIds: [me.id, doyun.id]),
          const PlaceOption(id: 'p2', value: mangwon),
        ],
      ),
      Appointment(
        id: 'a-seongsu',
        name: '성수 브런치',
        template: DecisionTemplate.hostDecides,
        hostId: seoa.id,
        inviteCode: 'SEONGSU',
        status: AppointmentStatus.completed,
        participants: const [seoa, me, doyun, harin],
        confirmedTime: at(-13, 11),
        confirmedPlace: const Place(name: '성수 카페거리'),
        penalty: '커피 사기',
        lateCount: 1,
      ),
      // 내가 아직 참여하지 않은 방. 코드 BOARD 로 초대 입장을 시험해볼 수 있다.
      Appointment(
        id: 'a-board',
        name: '금요일 보드게임',
        template: DecisionTemplate.voteTime,
        hostId: seoa.id,
        inviteCode: 'BOARD',
        participants: const [seoa, harin],
        timeOptions: [
          TimeOption(id: 't1', value: at(7, 19), voterIds: [seoa.id]),
          TimeOption(id: 't2', value: at(7, 20), voterIds: [harin.id]),
        ],
        placeOptions: const [PlaceOption(id: 'p1', value: Place(name: '홍대 레드버튼', description: '홍대입구역 도보 4분'))],
      ),
    ];
  }
}
