import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/models/poke_note.dart';
import 'note_card.dart';
import 'poke_style.dart';

/// 배율 1일 때 스티커 크기(카드 237 기준). 처음 붙일 때 배율 0.7 → 83, 피그마 917:16458과 같다.
const stickerBaseSize = 118.6;
const stickerInitialScale = 0.7;
const _minScale = 0.3;
const _maxScale = 2.0;

/// 쪽지 한 장: 카드 + 붙인 스티커. 스티커는 카드 밖으로 조금 나갈 수 있어서 자르지 않는다.
class PokeNoteView extends StatelessWidget {
  const PokeNoteView({super.key, required this.note, this.size = NoteCardView.designSize, this.placeholder = true});

  final PokeNote note;
  final double size;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final k = size / NoteCardView.designSize;
    return SizedBox.square(
      dimension: size,
      child: Stack(clipBehavior: Clip.none, children: [
        NoteCardView(card: note.card, text: note.text, size: size, placeholder: placeholder),
        for (final s in note.stickers) _place(s, k, child: StickerImage(PokeStyle.sticker(s.sticker), size: stickerBaseSize * s.scale * k, shadowBlur: 6.6)),
      ]),
    );
  }
}

/// 스티커 가운데를 카드 안 (dx, dy) 위치에 두고 돌린다. [origin]은 카드 왼쪽 위.
Widget _place(PlacedSticker s, double k, {required Widget child, double extra = 0, Offset origin = Offset.zero}) {
  final box = stickerBaseSize * s.scale * k + extra * 2;
  final card = NoteCardView.designSize * k;
  return Positioned(
    left: origin.dx + s.dx * card - box / 2,
    top: origin.dy + s.dy * card - box / 2,
    width: box,
    height: box,
    child: Transform.rotate(angle: s.rotation, child: child),
  );
}

/// 쪽지 화면에서 스티커를 붙이고 고치는 층. 스티커가 카드 밖으로 나가도 누를 수 있게 화면 전체에 깔고,
/// 카드 왼쪽 위 [origin]을 기준으로 놓는다. 빈 곳은 아래로 눌림이 지나간다.
class StickerEditor extends StatelessWidget {
  const StickerEditor({
    super.key,
    required this.origin,
    required this.stickers,
    required this.selectedId,
    required this.onSelect,
    required this.onChanged,
    required this.onDelete,
  });

  final Offset origin;
  final List<PlacedSticker> stickers;
  final int? selectedId;
  final ValueChanged<int?> onSelect;
  final ValueChanged<PlacedSticker> onChanged;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        // 선택한 스티커가 맨 위로.
        for (final s in [...stickers.where((s) => s.id != selectedId), ...stickers.where((s) => s.id == selectedId)])
          _EditableSticker(
            key: ValueKey(s.id),
            origin: origin,
            sticker: s,
            selected: s.id == selectedId,
            onSelect: () => onSelect(s.id),
            onChanged: onChanged,
            onDelete: () => onDelete(s.id),
          ),
      ]);
}

class _EditableSticker extends StatefulWidget {
  const _EditableSticker({
    super.key,
    required this.origin,
    required this.sticker,
    required this.selected,
    required this.onSelect,
    required this.onChanged,
    required this.onDelete,
  });

  final Offset origin;
  final PlacedSticker sticker;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<PlacedSticker> onChanged;
  final VoidCallback onDelete;

  @override
  State<_EditableSticker> createState() => _EditableStickerState();
}

class _EditableStickerState extends State<_EditableSticker> {
  static const _card = NoteCardView.designSize;

  /// 휴지통·배율 표시가 들어갈 위아래 여유.
  static const _chrome = 28.0;

  late PlacedSticker _start;

  /// 모서리 손잡이를 잡았을 때 스티커 가운데에서 손가락까지 (화면 좌표).
  Offset _startVector = Offset.zero;

  PlacedSticker get s => widget.sticker;

  /// 손가락을 처음 댄 곳. 끌기로 인식되기 전에 움직인 거리까지 따라가도록 여기서부터 잰다.
  Offset _startFocal = Offset.zero;

  // 한 손가락 끌기는 옮기기, 두 손가락은 크기·회전까지.
  int _pointers = 1;

  void _scaleStart(ScaleStartDetails d) {
    widget.onSelect();
    _start = s;
    _pointers = d.pointerCount;
    // 두 손가락이면 두 손가락 가운데가 기준.
    if (d.pointerCount > 1) _startFocal = d.focalPoint;
  }

  void _scaleUpdate(ScaleUpdateDetails d) {
    // 손가락 수가 바뀌면 지금 모양에서 다시 잰다. 안 그러면 가운데가 튀어서 스티커가 점프한다.
    if (d.pointerCount != _pointers) {
      _pointers = d.pointerCount;
      _start = s;
      _startFocal = d.focalPoint;
      return;
    }
    final moved = d.focalPoint - _startFocal;
    final next = s.copyWith(dx: _start.dx + moved.dx / _card, dy: _start.dy + moved.dy / _card);
    widget.onChanged(d.pointerCount < 2
        ? next
        : next.copyWith(scale: (_start.scale * d.scale).clamp(_minScale, _maxScale), rotation: _start.rotation + d.rotation));
  }

  /// 스티커 가운데 (화면 좌표). 회전해도 가운데는 그대로다.
  Offset get _center {
    final box = context.findRenderObject()! as RenderBox;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  // 모서리 손잡이: 가운데에서 멀어지면 커지고, 돌리면 돌아간다.
  void _handleStart(DragStartDetails d) {
    _start = s;
    _startVector = d.globalPosition - _center;
  }

  void _handleUpdate(DragUpdateDetails d) {
    final now = d.globalPosition - _center;
    if (_startVector.distance == 0) return;
    widget.onChanged(s.copyWith(
      scale: (_start.scale * now.distance / _startVector.distance).clamp(_minScale, _maxScale),
      rotation: _start.rotation + now.direction - _startVector.direction,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = stickerBaseSize * s.scale;
    final image = StickerImage(PokeStyle.sticker(s.sticker), size: size, shadowBlur: 6.6);
    final body = Listener(
      onPointerDown: (e) => _startFocal = e.position,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSelect,
        onScaleStart: _scaleStart,
        onScaleUpdate: _scaleUpdate,
        child: SizedBox.square(dimension: size, child: image),
      ),
    );
    if (!widget.selected) return _place(s, 1, origin: widget.origin, child: Semantics(button: true, label: '${s.sticker.label} 스티커', child: body));

    return _place(
      s,
      1,
      origin: widget.origin,
      extra: _chrome,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        // 파란 테두리 + 네 모서리 손잡이 (피그마 917:16488). 그림자 여백만큼 바깥으로 넓다.
        IgnorePointer(child: SvgPicture.asset('${PokeStyle.assets}/icons/select_border.svg', width: size * 1.1143, height: size * 1.1143)),
        body,
        for (final corner in const [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight])
          Align(
            alignment: corner,
            child: Padding(
              padding: const EdgeInsets.all(_chrome - 14),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onPanStart: _handleStart,
                onPanUpdate: _handleUpdate,
                child: Semantics(label: '크기·회전 조절', child: const SizedBox.square(dimension: 28)),
              ),
            ),
          ),
        Align(alignment: Alignment.topCenter, child: _TrashButton(onTap: widget.onDelete)),
        Align(alignment: Alignment.bottomCenter, child: _ScaleLabel(s.scale)),
      ]),
    );
  }
}

class _TrashButton extends StatelessWidget {
  const _TrashButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '스티커 삭제',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5.931, vertical: 2.373),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.304),
                boxShadow: const [BoxShadow(color: Color(0x1A212121), blurRadius: 2.373)],
              ),
              child: SvgPicture.asset('${PokeStyle.assets}/icons/trash.svg', width: 11.863, height: 11.863),
            ),
          ),
        ),
      );
}

class _ScaleLabel extends StatelessWidget {
  const _ScaleLabel(this.scale);

  final double scale;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5.931, vertical: 2.373),
        decoration: BoxDecoration(
          color: PokeStyle.selectBlue,
          borderRadius: BorderRadius.circular(8.304),
          boxShadow: const [BoxShadow(color: Color(0x1A212121), blurRadius: 2.373)],
        ),
        child: Text(
          'x ${scale.toStringAsFixed(1)}',
          style: const TextStyle(fontFamily: 'Pretendard', fontSize: 10, height: 1.4, letterSpacing: -0.8, color: Colors.white),
        ),
      );
}
