import '../models/appointment.dart';
import '../models/decision_template.dart';
import '../models/geo_point.dart';
import '../models/group.dart';
import '../models/participant.dart';
import '../models/place.dart';
import '../models/vote_option.dart';

/// 디자인 시안에 나오는 그룹·약속 그대로. 날짜는 실행 시각 기준으로 만든다.
/// 사람·약속 id(a-hongdae 등)는 당일 지도 목업과 테스트가 함께 쓰므로 바꾸지 않는다.
abstract final class MockData {
  static const _profiles = 'assets/images/profiles';
  static const _appointments = 'assets/images/appointments';
  static const _places = 'assets/images/places';

  static const me = Participant(id: 'u-yeeun', name: '예은', avatarAsset: '$_profiles/p1.jpg');
  static const doyun = Participant(id: 'u-doyun', name: '도윤', avatarAsset: '$_profiles/p2.jpg');
  static const seoa = Participant(id: 'u-seoa', name: '서아', avatarAsset: '$_profiles/p3.jpg');
  static const minjun = Participant(id: 'u-minjun', name: '민준', hasApp: false, avatarAsset: '$_profiles/p4.jpg');
  static const harin = Participant(id: 'u-harin', name: '하린', avatarAsset: '$_profiles/p5.jpg');
  static const jiwon = Participant(id: 'u-jiwon', name: '지원', avatarAsset: '$_profiles/p3.jpg');
  static const taemin = Participant(id: 'u-taemin', name: '태민', avatarAsset: '$_profiles/p4.jpg');
  static const yuna = Participant(id: 'u-yuna', name: '유나', avatarAsset: '$_profiles/p2.jpg');

  /// 새로 만든 방에 링크로 들어오는 친구들 (목업 연출용).
  static const friends = [doyun, seoa, minjun];

  /// 새 약속에 돌아가며 붙이는 기본 썸네일.
  static const appointmentImages = [
    '$_appointments/hiking.jpg',
    '$_appointments/donggi.jpg',
    '$_appointments/brunch.jpg',
    '$_appointments/meat.jpg',
    '$_appointments/jeju.jpg',
    '$_appointments/picnic.jpg',
    '$_appointments/morning.jpg',
  ];

  static const darak = Place(
    name: '성수다락',
    category: '양식',
    walkMinutes: 8,
    imageAsset: '$_places/darak.jpg',
    address: '대한민국 서울특별시 성동구 뚝섬로9길 20, 2층',
    location: GeoPoint(37.5447, 127.0557),
  );
  static const nanpo = Place(
    name: '난포',
    category: '한식',
    walkMinutes: 11,
    imageAsset: '$_places/nanpo.jpg',
    address: '대한민국 서울특별시 성동구 성수이로 66',
    location: GeoPoint(37.5432, 127.0560),
  );

  /// 장소 정하기·추천 장소 목업. 실제로는 현재 위치 기준 주변 장소가 들어온다.
  static const nearbyPlaces = [
    (darak, {'친구와 식사', '데이트', '최근 추가한 장소'}),
    (nanpo, {'선배와 식사', '가족', '친구와 식사'}),
    (Place(name: '소금집 델리', category: '양식', walkMinutes: 6, imageAsset: '$_places/darak.jpg', address: '서울특별시 마포구 동교로 205'), {'데이트', '친구와 식사'}),
    (Place(name: '대성갈비', category: '한식', walkMinutes: 4, imageAsset: '$_places/nanpo.jpg', address: '서울특별시 성동구 왕십리로 115'), {'동료', '술 한잔', '선배와 식사'}),
    (Place(name: '카페 어니언', category: '카페', walkMinutes: 9, imageAsset: '$_places/darak.jpg', address: '서울특별시 성동구 아차산로9길 8'), {'카페', '데이트', '회의'}),
    (Place(name: '서울숲 잔디광장', category: '공원', walkMinutes: 12, imageAsset: '$_places/nanpo.jpg', address: '서울특별시 성동구 뚝섬로 273'), {'피크닉', '가족'}),
    (Place(name: '성수 막걸리집', category: '주점', walkMinutes: 7, imageAsset: '$_places/nanpo.jpg', address: '서울특별시 성동구 연무장길 41'), {'술 한잔', '동료'}),
    (Place(name: '위워크 성수', category: '공유오피스', walkMinutes: 5, imageAsset: '$_places/darak.jpg', address: '서울특별시 성동구 성수이로 77'), {'회의', '동료'}),
  ];

  static const placeCategories = ['선배와 식사', '동료', '친구와 식사', '최근 추가한 장소', '데이트', '술 한잔', '카페', '피크닉', '가족', '회의'];

  /// 당일 상태 메시지 (도착 현황 말풍선). 상태 메시지 기능이 생기면 서버 값으로 바꾼다.
  static const statusMessages = {
    'u-yeeun': '이몸 도착 완료',
    'u-doyun': '오는 길에 음료 사줄사람 사례해드림',
    'u-minjun': 'ㅃㄹ 와라',
  };

  static List<Group> groups(DateTime now) => [
        Group(id: 'g-aptive', name: '앱티브', members: const [me, doyun, seoa, minjun, harin, jiwon, taemin], createdAt: now.subtract(const Duration(days: 40))),
        Group(id: 'g-jamong', name: '자몽살구클럽', members: const [me, doyun, seoa, minjun, harin, jiwon, taemin, yuna], createdAt: now.subtract(const Duration(days: 30))),
        Group(id: 'g-band', name: '밴드부', members: const [me, harin, jiwon], createdAt: now.subtract(const Duration(days: 20))),
        Group(id: 'g-test', name: 'test', members: const [me], createdAt: now.subtract(const Duration(days: 1))),
      ];

  static List<Appointment> appointments(DateTime now) {
    DateTime at(int days, int hour, [int minute = 0]) => DateTime(now.year, now.month, now.day + days, hour, minute);
    DateTime made(int daysAgo) => now.subtract(Duration(days: daysAgo));

    return [
      // 자몽살구클럽 — 곧 시작하는 약속. 홈 카운트다운과 당일 지도가 이 약속을 쓴다.
      Appointment(
        id: 'a-hongdae',
        name: '홍대 저녁 모임',
        groupId: 'g-jamong',
        imageAsset: '$_appointments/picnic.jpg',
        createdAt: made(9),
        template: DecisionTemplate.voteBoth,
        hostId: me.id,
        inviteCode: 'HONGDAE',
        status: AppointmentStatus.confirmed,
        participants: const [me, doyun, seoa, minjun, harin, jiwon, taemin, yuna],
        confirmedTime: now.add(const Duration(hours: 1, minutes: 42)),
        confirmedPlace: const Place(
          name: '연남동 소금집 델리',
          description: '홍대입구역 3번 출구',
          address: '대한민국 서울특별시 마포구 동교로 205',
          location: GeoPoint(37.5617, 126.9221),
        ),
        penalty: '커피 사기',
        penaltyAgreedIds: [me.id, doyun.id, seoa.id, minjun.id, harin.id],
      ),
      // 앱티브 — 약속 전 5, 약속 완료 2.
      Appointment(
        id: 'a-hiking',
        name: '토요일 등산',
        groupId: 'g-aptive',
        imageAsset: '$_appointments/hiking.jpg',
        createdAt: made(8),
        template: DecisionTemplate.hostDecides,
        hostId: doyun.id,
        inviteCode: 'HIKING',
        status: AppointmentStatus.confirmed,
        participants: const [doyun, me, seoa, harin],
        confirmedTime: at(6, 8),
        confirmedPlace: const Place(
          name: '북한산',
          description: '북한산우이역 2번 출구',
          address: '대한민국 서울특별시 강북구 삼양로181길 45',
          location: GeoPoint(37.6630, 127.0125),
        ),
        penalty: '다음 약속 총무',
        lateThresholdMinutes: 15,
        penaltyAgreedIds: [doyun.id, me.id, seoa.id],
      ),
      Appointment(
        id: 'a-donggi',
        name: '동기 모임',
        groupId: 'g-aptive',
        imageAsset: '$_appointments/donggi.jpg',
        createdAt: made(7),
        template: DecisionTemplate.voteBoth,
        hostId: me.id,
        inviteCode: 'DONGGI',
        participants: const [me, doyun, seoa, minjun, harin],
        timeOptions: [
          TimeOption(id: 't1', value: at(4, 19), voterIds: [doyun.id, seoa.id, minjun.id, harin.id]),
          TimeOption(id: 't2', value: at(5, 17), voterIds: [me.id]),
        ],
        placeOptions: [
          PlaceOption(id: 'p1', value: darak, voterIds: [doyun.id, seoa.id]),
          PlaceOption(id: 'p2', value: nanpo, voterIds: [minjun.id]),
        ],
      ),
      Appointment(
        id: 'a-seongsu',
        name: '성수 브런치',
        groupId: 'g-aptive',
        imageAsset: '$_appointments/brunch.jpg',
        createdAt: made(6),
        template: DecisionTemplate.voteBoth,
        hostId: seoa.id,
        inviteCode: 'SEONGSU',
        participants: const [seoa, me, doyun, harin],
      ),
      Appointment(
        id: 'a-meat',
        name: '퇴근 후 고기',
        groupId: 'g-aptive',
        imageAsset: '$_appointments/meat.jpg',
        createdAt: made(5),
        template: DecisionTemplate.voteBoth,
        hostId: me.id,
        inviteCode: 'MEAT',
        status: AppointmentStatus.confirmed,
        participants: const [me, doyun, minjun, taemin],
        confirmedTime: at(2, 19, 30),
        confirmedPlace: nanpo,
      ),
      Appointment(
        id: 'a-jeju',
        name: '제주 여행',
        groupId: 'g-aptive',
        imageAsset: '$_appointments/jeju.jpg',
        createdAt: made(4),
        template: DecisionTemplate.voteBoth,
        hostId: harin.id,
        inviteCode: 'JEJU',
        participants: const [harin, me, seoa, jiwon],
        timeOptions: [
          TimeOption(id: 't1', value: at(24, 9), voterIds: [harin.id, seoa.id]),
          TimeOption(id: 't2', value: at(31, 9), voterIds: [jiwon.id]),
        ],
      ),
      Appointment(
        id: 'a-picnic',
        name: '한강 피크닉',
        groupId: 'g-aptive',
        imageAsset: '$_appointments/picnic.jpg',
        createdAt: made(20),
        template: DecisionTemplate.hostDecides,
        hostId: me.id,
        inviteCode: 'PICNIC',
        status: AppointmentStatus.completed,
        participants: const [me, doyun, seoa],
        confirmedTime: at(-10, 14),
        confirmedPlace: const Place(name: '반포 한강공원', address: '서울특별시 서초구 신반포로11길 40'),
      ),
      Appointment(
        id: 'a-morning',
        name: '목요일아침',
        groupId: 'g-aptive',
        imageAsset: '$_appointments/morning.jpg',
        createdAt: made(15),
        template: DecisionTemplate.hostDecides,
        hostId: doyun.id,
        inviteCode: 'MORNING',
        status: AppointmentStatus.completed,
        participants: const [doyun, me],
        confirmedTime: at(-3, 8),
        confirmedPlace: const Place(name: '카페 어니언', address: '서울특별시 성동구 아차산로9길 8'),
        lateCount: 1,
      ),
      // 밴드부
      Appointment(
        id: 'a-band',
        name: '합주 연습',
        groupId: 'g-band',
        imageAsset: '$_appointments/morning.jpg',
        createdAt: made(3),
        template: DecisionTemplate.voteTime,
        hostId: harin.id,
        inviteCode: 'BAND',
        participants: const [harin, me, jiwon],
        timeOptions: [
          TimeOption(id: 't1', value: at(3, 20), voterIds: [harin.id]),
          TimeOption(id: 't2', value: at(4, 20), voterIds: [jiwon.id]),
        ],
        confirmedPlace: const Place(name: '홍대 합주실', address: '서울특별시 마포구 어울마당로 65'),
      ),
      // 내가 아직 참여하지 않은 방. 코드 BOARD 로 초대 입장을 시험해볼 수 있다.
      Appointment(
        id: 'a-board',
        name: '금요일 보드게임',
        groupId: 'g-jamong',
        imageAsset: '$_appointments/brunch.jpg',
        createdAt: made(2),
        template: DecisionTemplate.voteTime,
        hostId: seoa.id,
        inviteCode: 'BOARD',
        participants: const [seoa, harin],
        timeOptions: [
          TimeOption(id: 't1', value: at(7, 19), voterIds: [seoa.id]),
          TimeOption(id: 't2', value: at(7, 20), voterIds: [harin.id]),
        ],
        placeOptions: const [PlaceOption(id: 'p1', value: Place(name: '홍대 레드버튼', description: '홍대입구역 도보 4분', location: GeoPoint(37.5548, 126.9225)))],
      ),
    ];
  }
}
