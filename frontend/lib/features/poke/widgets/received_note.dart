import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/live_location.dart';
import 'sticker_layer.dart';

/// 08 · 콕 찌르기 (받는 쪽). 노란 봉투가 떨어져 통통 튄 뒤, 열리면서 쪽지 카드가 된다.
/// 디자이너 애니메이션 예시(피그마 994:15509, 약 1.25초)를 따른다. 아무 데나 누르면 닫힌다.
class ReceivedNoteOverlay extends StatefulWidget {
  const ReceivedNoteOverlay({super.key, required this.poke, required this.onClose});

  final Poke poke;
  final VoidCallback onClose;

  @override
  State<ReceivedNoteOverlay> createState() => _ReceivedNoteOverlayState();
}

class _ReceivedNoteOverlayState extends State<ReceivedNoteOverlay> with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 1250);

  late final _t = AnimationController(vsync: this, duration: _total)..forward();

  // 구간은 전체 1.25초에 대한 비율.
  late final _dim = CurvedAnimation(parent: _t, curve: const Interval(0, 0.08, curve: Curves.easeOut));
  late final _straighten = CurvedAnimation(parent: _t, curve: const Interval(0, 0.4, curve: Curves.easeOut));
  late final _open = CurvedAnimation(parent: _t, curve: const Interval(0.8, 1, curve: Curves.easeOutCubic));

  /// 봉투 가운데가 멈출 자리에서 얼마나 떨어져 있는지. 영상에서 잰 값:
  /// 0.3초 동안 떨어져 살짝 지나치고(+25), 위로 튀었다가(-45), 작게 출렁이며(+4, +17) 0.7초에 멈춘다.
  late final _drop = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeIn)), weight: 0.3),
    TweenSequenceItem(tween: _bounce(1, 2, Curves.easeOut), weight: 0.1),
    TweenSequenceItem(tween: _bounce(2, 3, Curves.easeInOut), weight: 0.1),
    TweenSequenceItem(tween: _bounce(3, 4, Curves.easeInOut), weight: 0.1),
    TweenSequenceItem(tween: _bounce(4, 5, Curves.easeOut), weight: 0.1),
  ]).animate(CurvedAnimation(parent: _t, curve: const Interval(0, 0.56)));

  /// [_drop] 값은 구간 번호(0~5). 실제 거리는 [_offsetAt]에서 바꾼다.
  static Animatable<double> _bounce(double from, double to, Curve curve) => Tween<double>(begin: from, end: to).chain(CurveTween(curve: curve));

  static const _bounces = [25.0, -45.0, 4.0, 17.0, 0.0];

  /// 구간 번호 → 멈출 자리 기준 거리. 0은 화면 위([start]).
  static double _offsetAt(double step, double start) {
    if (step <= 1) return start + (_bounces[0] - start) * step;
    final i = step.floor().clamp(1, 4);
    return _bounces[i - 1] + (_bounces[i] - _bounces[i - 1]) * (step - i);
  }

  var _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 봉투가 떨어지는 1초 동안 카드 그림을 미리 풀어 둔다. 안 그러면 열리는 순간 그림이 비어 그림자만 회색으로 보인다.
    if (!_precached) {
      _precached = true;
      precachePokeNote(context, widget.poke.note);
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final envelopeCenterY = size.height * 0.495;
    final cardCenterY = size.height * 0.436;

    return Semantics(
      label: '${widget.poke.from.name}님이 보낸 쪽지',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onClose,
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final open = _open.value;
            // 화면 위에서 떨어져 가운데에 멈춘다. 열릴 때는 아래로 빠지며 사라진다.
            final envelopeY = envelopeCenterY + _offsetAt(_drop.value, -_Envelope.height - envelopeCenterY) + 40 * open;
            return Stack(children: [
              Positioned.fill(child: ColoredBox(color: Color.fromRGBO(33, 33, 33, 0.6 * _dim.value))),
              if (open < 1)
                Positioned(
                  left: (size.width - _Envelope.width) / 2,
                  top: envelopeY - _Envelope.height / 2,
                  child: Opacity(
                    opacity: 1 - open,
                    child: Transform.rotate(angle: (1 - _straighten.value) * -15 * math.pi / 180, child: const _Envelope()),
                  ),
                ),
              if (open > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: cardCenterY - 237 / 2,
                  child: Center(
                    child: Opacity(
                      opacity: open,
                      child: Transform.scale(
                        scale: 0.85 + 0.15 * open,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(27),
                            boxShadow: const [BoxShadow(color: Color(0x4D212121), blurRadius: 14)],
                          ),
                          child: PokeNoteView(note: widget.poke.note, placeholder: false),
                        ),
                      ),
                    ),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }
}

/// 노란 봉투 + 빨간 봉인. 디자인 영상에서 잰 크기·색.
class _Envelope extends StatelessWidget {
  const _Envelope();

  static const width = 139.0;
  static const height = 91.0;

  @override
  Widget build(BuildContext context) => const SizedBox(width: width, height: height, child: CustomPaint(painter: _EnvelopePainter()));
}

class _EnvelopePainter extends CustomPainter {
  const _EnvelopePainter();

  static const _body = Color(0xFFF0D973);
  static const _flap = Color(0xFFEBC94B);
  static const _seal = Color(0xFFD0423F);

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6));
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(Offset.zero & size, Paint()..color = _body);
    // 위 덮개: 양 모서리에서 가운데(높이 48%)로 내려오는 삼각형.
    final tip = Offset(size.width / 2, size.height * 0.48);
    canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(tip.dx, tip.dy)
          ..close(),
        Paint()..color = _flap);
    canvas.restore();
    canvas.drawCircle(Offset(tip.dx, tip.dy + size.height * 0.1), 10, Paint()..color = _seal);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
