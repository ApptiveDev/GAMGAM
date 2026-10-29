/// 08 · 콕 찌르기 쪽지. 카드 디자인 + 문구 + 붙인 스티커.
library;

/// 쪽지 카드 디자인 6종. 순서는 고르는 시트에 보이는 순서.
enum NoteCard {
  airmail('항공우편'),
  grid('모눈'),
  check('체크'),
  flower('꽃'),
  heart('하트'),
  music('음표');

  const NoteCard(this.label);

  final String label;
}

/// 이모지 스티커 12종. 순서는 이모지 시트에 보이는 순서.
enum NoteSticker {
  sunglasses('선글라스'),
  rainbow('무지개'),
  musicalNotes('음표'),
  smilingHearts('하트 얼굴'),
  ribbon('리본'),
  clover('네잎클로버'),
  heartOnFire('불타는 하트'),
  pleading('글썽이는 얼굴'),
  halo('천사'),
  enraged('화난 얼굴'),
  twoHearts('하트'),
  bubbles('비눗방울');

  const NoteSticker(this.label);

  final String label;
}

/// 문구 시트의 프리셋.
const notePhrases = [
  '도착하면\n연락 줘!',
  '너 지금\n납치됐어?',
  '어디쯤이야?',
  '보고싶다\n친구야~',
  '잼처럼\n발라주겠다~',
  '분노 R아서\nP하셈',
];

/// 쪽지에 붙인 스티커 하나. 위치는 카드 크기에 대한 비율(0~1)이라 화면 크기와 상관없다.
class PlacedSticker {
  const PlacedSticker({required this.id, required this.sticker, this.dx = 0.5, this.dy = 0.5, this.scale = 1, this.rotation = 0});

  final int id;
  final NoteSticker sticker;

  /// 스티커 가운데의 카드 안 위치 (왼쪽 위 0,0 ~ 오른쪽 아래 1,1).
  final double dx;
  final double dy;

  /// 기본 크기 대비 배율. 편집 중에 "x0.7"처럼 보여준다.
  final double scale;

  /// 라디안.
  final double rotation;

  PlacedSticker copyWith({double? dx, double? dy, double? scale, double? rotation}) => PlacedSticker(
        id: id,
        sticker: sticker,
        dx: dx ?? this.dx,
        dy: dy ?? this.dy,
        scale: scale ?? this.scale,
        rotation: rotation ?? this.rotation,
      );
}

class PokeNote {
  const PokeNote({this.card = NoteCard.airmail, this.text, this.stickers = const []});

  final NoteCard card;

  /// 고른 문구. 없으면 카드에 "텍스트를 선택해주세요"가 흐리게 보인다.
  final String? text;
  final List<PlacedSticker> stickers;

  /// 문구나 스티커가 하나라도 있어야 보낼 수 있다.
  bool get canSend => text != null || stickers.isNotEmpty;

  PokeNote copyWith({NoteCard? card, String? text, List<PlacedSticker>? stickers}) =>
      PokeNote(card: card ?? this.card, text: text ?? this.text, stickers: stickers ?? this.stickers);
}
