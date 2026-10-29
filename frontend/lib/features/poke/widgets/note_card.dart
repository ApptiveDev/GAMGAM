import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/models/poke_note.dart';

const _cards = 'assets/poke/cards';

/// 쪽지 카드. 디자인 기준 237×237로 그리고, 다른 크기는 [size]에 맞춰 통째로 줄이거나 늘린다.
/// 배경과 글자는 피그마처럼 따로 그린다. 스티커는 카드 밖으로 나갈 수 있어서 여기서 그리지 않는다.
class NoteCardView extends StatelessWidget {
  const NoteCardView({super.key, required this.card, this.text, this.size = designSize, this.placeholder = true});

  static const designSize = 237.0;
  static const radius = 27.0;

  final NoteCard card;
  final String? text;
  final double size;

  /// 문구가 없을 때 "텍스트를 선택해주세요"를 흐리게 보여줄지. 시트의 작은 미리보기에서는 끈다.
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final style = _textStyles[card]!;
    final empty = text == null;
    final label = Text(
      empty ? '텍스트를\n선택해주세요' : text!,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'BMKkubulim',
        fontSize: 20,
        height: 1.4,
        letterSpacing: -0.28,
        color: empty ? const Color(0x29212121) : style.color,
      ),
    );

    return SizedBox.square(
      dimension: size,
      child: FittedBox(
        child: SizedBox.square(
          dimension: designSize,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(fit: StackFit.expand, children: [
              _background(card),
              if (!empty || placeholder)
                // 꽃 카드는 줄 노트 선 위에 글자가 오도록 위에서부터 놓는다.
                style.top == null ? Center(child: label) : Positioned(top: style.top, left: 0, right: 0, child: label),
            ]),
          ),
        ),
      ),
    );
  }

  static const _textStyles = {
    NoteCard.airmail: _CardText(Color(0xFF212121)),
    NoteCard.grid: _CardText(Color(0xFF212121)),
    NoteCard.check: _CardText(Colors.white),
    NoteCard.flower: _CardText(Color(0xFF212121), top: 78.8),
    NoteCard.heart: _CardText(Color(0xFFEA71A6)),
    NoteCard.music: _CardText(Color(0xFF756354)),
  };

  static Widget _background(NoteCard card) => switch (card) {
        NoteCard.airmail => Image.asset('$_cards/airmail.png', fit: BoxFit.cover),
        NoteCard.heart => Image.asset('$_cards/heart.png', fit: BoxFit.cover),
        NoteCard.grid => const _Paper(),
        NoteCard.check => const _Paper(pattern: '$_cards/check.png'),
        NoteCard.flower => const _FlowerBackground(),
        NoteCard.music => const _MusicBackground(),
      };
}

/// 카드 디자인 시트의 작은 썸네일. 항공우편·모눈·체크는 피그마에서 썸네일용 그림을 따로 쓴다.
class NoteCardThumbnail extends StatelessWidget {
  const NoteCardThumbnail(this.card, {super.key});

  final NoteCard card;

  @override
  Widget build(BuildContext context) => switch (card) {
        NoteCard.airmail => Image.asset('$_cards/thumb_airmail.png', fit: BoxFit.cover),
        NoteCard.grid => const _Sprite('$_cards/paper.png', width: 5.2632, height: 7.4472, left: -0.8161, top: -5.9859),
        NoteCard.check => Image.asset('$_cards/thumb_check.png', fit: BoxFit.fill),
        _ => FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: NoteCardView(card: card, placeholder: false)),
      };
}

class _CardText {
  const _CardText(this.color, {this.top});

  final Color color;

  /// 없으면 가운데. 있으면 카드 위에서부터의 거리.
  final double? top;
}

/// 모눈·체크: 노란 바탕 + 종이 질감 (+ 체크무늬).
class _Paper extends StatelessWidget {
  const _Paper({this.pattern});

  final String? pattern;

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: Color(0xFFFFF69D)),
        Image.asset('$_cards/paper.png', fit: BoxFit.cover),
        if (pattern != null) Image.asset(pattern!, fit: BoxFit.cover),
      ]);
}

/// 피그마 레이어 하나. (left, top)에 놓인 [box] 가운데에 [inner] 크기 그림을 뒤집고 돌려 놓는다.
/// 회전한 레이어는 [box]가 돌아간 그림을 감싸는 상자다.
class _Layer extends StatelessWidget {
  const _Layer(this.left, this.top, this.box, this.inner, this.child, {this.degrees = 0, this.flipY = false});

  final double left;
  final double top;
  final Size box;
  final Size inner;
  final Widget child;
  final double degrees;
  final bool flipY;

  @override
  Widget build(BuildContext context) => Positioned(
        left: left,
        top: top,
        width: box.width,
        height: box.height,
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: Transform.rotate(
            angle: degrees * math.pi / 180,
            child: Transform.flip(flipY: flipY, child: SizedBox.fromSize(size: inner, child: child)),
          ),
        ),
      );
}

/// 여러 그림이 모인 이미지에서 일부만 보이게. 비율은 피그마 값(이미지 크기·위치를 레이어 크기에 대한 배수로).
class _Sprite extends StatelessWidget {
  const _Sprite(this.asset, {required this.width, required this.height, required this.left, required this.top});

  final String asset;
  final double width;
  final double height;
  final double left;
  final double top;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => Stack(clipBehavior: Clip.hardEdge, children: [
          Positioned(
            left: c.maxWidth * left,
            top: c.maxHeight * top,
            width: c.maxWidth * width,
            height: c.maxHeight * height,
            child: Image.asset(asset, fit: BoxFit.fill),
          ),
        ]),
      );
}

/// 이미지 모양(투명도)대로 칠한 단색. 마스크 이미지는 레이어보다 클 수 있고, 왼쪽 위에 맞춘다.
class _Mask extends StatelessWidget {
  const _Mask(this.asset, this.color, this.maskSize);

  final String asset;
  final Color color;
  final Size maskSize;

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned(
          left: 0,
          top: 0,
          width: maskSize.width,
          height: maskSize.height,
          child: Image.asset(asset, fit: BoxFit.fill, color: color, colorBlendMode: BlendMode.srcIn),
        ),
      ]);
}

class _Box extends StatelessWidget {
  const _Box(this.size, {required this.radius, this.borderColor, this.borderWidth = 0});

  final double size;
  final double radius;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: borderColor == null ? null : Border.all(color: borderColor!, width: borderWidth),
          ),
        ),
      );
}

/// 음표 카드 (피그마 865:7161).
class _MusicBackground extends StatelessWidget {
  const _MusicBackground();

  static const _m = '$_cards/music';

  @override
  Widget build(BuildContext context) => const Stack(children: [
        Positioned.fill(child: ColoredBox(color: Color(0xFFFFF69D))),
        _Box(203.672, radius: 21.293),
        _Box(189.785, radius: 17.336, borderColor: Color(0xFFFCF79B), borderWidth: 4.698),
        _Layer(104.16, 73.05, Size.square(188.081), Size.square(152.832), _Mask('$_m/0d03e.png', Color(0xFFC1DEDA), Size.square(188.081)), degrees: 15.48),
        _Layer(-2.48, 162.89, Size.square(74.028), Size.square(54), _Mask('$_m/d1a1f.png', Color(0xFFDAE7BC), Size.square(74.028)), degrees: 59.22),
        _Layer(163.63, 0, Size(56.708, 63.833), Size(35.552, 53.328), _Mask('$_m/d24f0.png', Color(0xFFF5CDD8), Size(56.708, 63.833)), degrees: -28.53),
      ]);
}

/// 꽃 카드 (피그마 865:7124). 레이어 순서가 곧 겹치는 순서다.
class _FlowerBackground extends StatelessWidget {
  const _FlowerBackground();

  static const _f = '$_cards/flower';
  static const _cover = BoxFit.cover;

  @override
  Widget build(BuildContext context) => Stack(children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFFFDFFE0))),
        _Layer(-1.89, 49.86, const Size.square(41.011), const Size.square(30.455), Image.asset('$_f/881e6.png', fit: _cover), degrees: 117.22, flipY: true),
        _Layer(190.63, 1.306, const Size.square(56.644), const Size.square(42.063), Image.asset('$_f/881e6.png', fit: _cover), degrees: 62.78),
        _Layer(16.66, 7.409, const Size(23.573, 28.081), const Size(16.042, 23.91), Image.asset('$_f/c66c3.png', fit: _cover), degrees: -21.1),
        _Layer(9.26, 24.073, const Size(21.611, 17.927), const Size(12.419, 18.51), Image.asset('$_f/c66c3.png', fit: _cover), degrees: -70.32),
        _Layer(6.48, 39.811, const Size(19.063, 14.229), const Size(11.744, 17.503), Image.asset('$_f/b9ca3.png', fit: _cover), degrees: -81.4),
        _Layer(5.55, 168.494, const Size(31.198, 21.786), const Size(20.26, 30.196), Image.asset('$_f/6bf3d.png', fit: _cover), degrees: -92.95),
        const _Layer(3.70, 168.49, Size(34.063, 39.511), Size(33.328, 38.883), _Sprite('$_f/f6f77.png', width: 3.2452, height: 5, left: -1.1221, top: -3.5143),
            degrees: 1.09, flipY: true),
        const _Layer(0, 102.76, Size(41.327, 45.466), Size(33.328, 38.883), _Sprite('$_f/f6f77.png', width: 3.2452, height: 5, left: -2.116, top: -2.2719),
            degrees: 166.8, flipY: true),
        const _Layer(
            12.96, 132.39, Size(21.293, 22.219), Size(21.293, 22.219), _Sprite('$_f/7b6d8.png', width: 3.9474, height: 6.6298, left: -2.6689, top: 0.0055)),
        _Layer(200.89, 157.38, const Size(34.254, 49.992), const Size(34.254, 49.992), Image.asset('$_f/67246.png', fit: _cover)),
        const _Box(189.785, radius: 12.077, borderColor: Color(0xFFC47D68), borderWidth: 0.863),
        const _Layer(
            12.04, 40.733, Size(19.242, 20.367), Size(19.242, 20.367), _Sprite('$_f/7b6d8.png', width: 3.9474, height: 6.6298, left: -1.5382, top: -2.5912)),
        const _Box(179.602, radius: 7.771, borderColor: Color(0xFFC47D68), borderWidth: 1.71),
        const _Layer(
            185.72, 29.626, Size(38.883, 40.734), Size(38.883, 40.734), _Sprite('$_f/7b6d8.png', width: 3.9474, height: 6.6298, left: -0.3216, top: -1.3204),
            flipY: true),
        const _Layer(
            17.59, 20.336, Size(38.883, 40.734), Size(38.883, 40.734), _Sprite('$_f/7b6d8.png', width: 3.9474, height: 6.6298, left: -1.4969, top: -5.3596),
            degrees: 180),
        const _Layer(
            37.03, 44.441, Size(21.293, 22.219), Size(21.293, 22.219), _Sprite('$_f/7b6d8.png', width: 3.9474, height: 6.6298, left: -2.6689, top: 0.0055)),
        const _Layer(
            14.81, 70.355, Size(11.109, 12.035), Size(11.109, 12.035), _Sprite('$_f/f6f77.png', width: 3.771, height: 6.8182, left: -1.3668, top: -1.7386)),
        const _Layer(
            200.07, 20.123, Size(17.948, 18.997), Size(17.948, 18.997), _Sprite('$_f/f6f77.png', width: 3.771, height: 6.8182, left: -1.3668, top: -1.7386)),
        Center(child: SvgPicture.asset('$_f/lines.svg', width: 135.164, height: 83.3203)),
        const _Layer(194.88, 74.18, Size.square(48.141), Size.square(48.141), _Bloom(dot: 'dot_small', dots: _smallDots, withLeaf: true)),
        const _Layer(86.14, -5.29, Size.square(64.722), Size.square(53.554), _Bloom(dot: 'dot_large', dots: _largeDots), degrees: 103.71),
        _Layer(198.48, 117.254, const Size(25.202, 26.676), const Size(25.202, 26.676), Image.asset('$_f/cc4cc.png', fit: BoxFit.fill),
            degrees: 180, flipY: true),
        const _Layer(
            138.82, 13.423, Size(19.242, 20.367), Size(19.242, 20.367), _Sprite('$_f/7b6d8.png', width: 3.9474, height: 6.6298, left: -1.5382, top: -2.5912)),
      ]);

  /// 꽃 그림 위 꽃술 점 세 개. 위치는 꽃 크기에 대한 비율.
  static const _smallDots = [Offset(28.59 / 48.141, 40.49 / 48.141), Offset(22.78 / 48.141, 43.75 / 48.141), Offset(19.29 / 48.141, 37.63 / 48.141)];
  static const _largeDots = [Offset(31.81 / 53.554, 45.04 / 53.554), Offset(25.34 / 53.554, 48.67 / 53.554), Offset(21.46 / 53.554, 41.86 / 53.554)];
}

/// 꽃(f2716) + 꽃술 점. 작은 꽃에는 잎(f05bc)이 붙어 있다.
class _Bloom extends StatelessWidget {
  const _Bloom({required this.dot, required this.dots, this.withLeaf = false});

  final String dot;
  final List<Offset> dots;
  final bool withLeaf;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final s = c.maxWidth;
        final dotSize = dot == 'dot_small' ? 1.852 : 2.06;
        return Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(child: Image.asset('${_FlowerBackground._f}/f2716.png', fit: BoxFit.cover)),
          for (final d in dots)
            Positioned(
              left: s * d.dx,
              top: s * d.dy,
              child: SvgPicture.asset('${_FlowerBackground._f}/$dot.svg', width: dotSize, height: dotSize),
            ),
          if (withLeaf)
            Positioned(
                left: 1.35, top: s - 38.84 - 16.145, width: 15.253, height: 16.145, child: Image.asset('${_FlowerBackground._f}/f05bc.png', fit: BoxFit.fill)),
        ]);
      });
}
