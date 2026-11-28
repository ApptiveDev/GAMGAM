/// 투표를 열 때 고르는 설정. 시간·장소 투표가 각각 하나씩 가진다.
/// 팀 정책: 누군가 투표한 뒤에는 [multiple]·[anonymous]를 바꿀 수 없다.
/// [allowAdd]가 꺼져도 약속장은 후보를 추가할 수 있다.
class VoteSettings {
  const VoteSettings({this.multiple = false, this.anonymous = false, this.allowAdd = true});

  /// 복수선택.
  final bool multiple;

  /// 익명투표: 투표자 목록을 숨기고 숫자만 보여준다(약속장에게도).
  final bool anonymous;

  /// 선택항목 추가 허용: 참여자도 후보를 더할 수 있다.
  final bool allowAdd;

  VoteSettings copyWith({bool? multiple, bool? anonymous, bool? allowAdd}) => VoteSettings(
        multiple: multiple ?? this.multiple,
        anonymous: anonymous ?? this.anonymous,
        allowAdd: allowAdd ?? this.allowAdd,
      );
}

/// 투표 진행 시간. 시간·장소 투표가 따로 정하고, 투표 설정을 저장한 시점부터 흐른다(백엔드 `PUT /polls/{type}`).
enum VoteDuration {
  min30('30분', Duration(minutes: 30)),
  hour1('1시간', Duration(hours: 1)),
  hour4('4시간', Duration(hours: 4)),
  hour8('8시간', Duration(hours: 8)),
  hour24('24시간', Duration(hours: 24)),
  day3('3일', Duration(days: 3)),
  week1('1주', Duration(days: 7)),
  week2('2주', Duration(days: 14));

  const VoteDuration(this.label, this.duration);

  final String label;
  final Duration duration;
}
