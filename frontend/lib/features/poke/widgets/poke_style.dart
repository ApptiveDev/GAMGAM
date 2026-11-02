import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../data/models/poke_note.dart';

/// 콕 찌르기 쪽지 화면 공용 값.
abstract final class PokeStyle {
  static const pink = Color(0xFFF8AFFE);
  static const text = Color(0xFF212121);
  static const textBody = Color(0xFF424242);
  static const selectBlue = Color(0xFF0B9EF9);

  static const assets = 'assets/poke';

  /// 쪽지 글씨.
  static TextStyle note(Color color) => TextStyle(fontFamily: 'BMKkubulim', fontSize: 20, height: 1.4, letterSpacing: -0.28, color: color);

  static String sticker(NoteSticker s) => '$assets/stickers/${_stickerFiles[s]}.png';

  static const _stickerFiles = {
    NoteSticker.sunglasses: 'sunglasses',
    NoteSticker.rainbow: 'rainbow',
    NoteSticker.musicalNotes: 'musical_notes',
    NoteSticker.smilingHearts: 'smiling_hearts',
    NoteSticker.ribbon: 'ribbon',
    NoteSticker.clover: 'clover',
    NoteSticker.heartOnFire: 'heart_on_fire',
    NoteSticker.pleading: 'pleading',
    NoteSticker.halo: 'halo',
    NoteSticker.enraged: 'enraged',
    NoteSticker.twoHearts: 'two_hearts',
    NoteSticker.bubbles: 'bubbles',
  };
}

/// 점무늬 종이 바탕. 가장자리는 흰색으로 흐려진다. [fade]는 위·아래 흐려지는 구간(높이 비율).
class DotBackground extends StatelessWidget {
  const DotBackground({super.key, this.topFade = const [0.009, 0.121], this.bottomFade = const [0.873, 0.981], this.shade = true});

  final List<double> topFade;
  final List<double> bottomFade;

  /// 아래쪽을 살짝 어둡게. 화면 바탕에만 있고 시트에는 없다.
  final bool shade;

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: Colors.white),
        Image.asset('${PokeStyle.assets}/dot_bg.png', fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [Colors.white, Color(0x00FFFFFF), Color(0x00FFFFFF), Colors.white],
              stops: [topFade[0], topFade[1], bottomFade[0], bottomFade[1]],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0x00FFFFFF), Color(0x00FFFFFF), Colors.white],
              stops: [0, 0.115, 0.889, 1],
            ),
          ),
        ),
        if (shade)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00212121), Color(0x1A212121)],
                stops: [0.752, 1],
              ),
            ),
          ),
      ]);
}

/// 스티커처럼 흰 테두리 + 그림자를 두른 이미지. 이모지 그림에는 테두리가 없어서 코드로 입힌다.
class StickerImage extends StatelessWidget {
  const StickerImage(this.asset, {super.key, required this.size, this.shadow = const Color(0x59212121), this.shadowBlur = 8});

  final String asset;
  final double size;
  final Color shadow;
  final double shadowBlur;

  @override
  Widget build(BuildContext context) {
    final outline = size * 0.035;
    Widget tinted(Color color) => Image.asset(asset, width: size, height: size, color: color, colorBlendMode: BlendMode.srcIn);
    return SizedBox.square(
      dimension: size,
      child: Stack(clipBehavior: Clip.none, children: [
        Transform.translate(
          offset: Offset(0, size * 0.01),
          child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: shadowBlur / 2, sigmaY: shadowBlur / 2), child: tinted(shadow)),
        ),
        for (var i = 0; i < 16; i++)
          Transform.translate(offset: Offset(math.cos(i * math.pi / 8), math.sin(i * math.pi / 8)) * outline, child: tinted(Colors.white)),
        Image.asset(asset, width: size, height: size),
      ]),
    );
  }
}
