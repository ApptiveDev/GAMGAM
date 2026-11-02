import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/models/poke_note.dart';
import 'note_card.dart';
import 'poke_style.dart';

enum NoteTab { card, text, emoji }

/// 쪽지 화면 하단 패널. 닫혀 있으면 탭 카드만, 탭을 누르면 그 탭의 시트가 올라온다.
class NoteSheet extends StatelessWidget {
  const NoteSheet({super.key, required this.tab, required this.onTab, required this.onClose, this.onSwipe, this.expanded = false, this.child});

  /// 디자인 기준 높이 (손잡이 3 + 간격 6 + 패널).
  static const closedHeight = 126.0;
  static const openHeight = 429.0;
  static const expandedHeight = 670.0;

  final NoteTab? tab;
  final ValueChanged<NoteTab> onTab;
  final VoidCallback onClose;

  /// 손잡이·탭 쪽을 위(true)나 아래(false)로 밀었을 때.
  final ValueChanged<bool>? onSwipe;

  /// 이모지 시트를 끝까지 올린 상태.
  final bool expanded;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final open = tab != null;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: (open ? (expanded ? expandedHeight : openHeight) : closedHeight) + bottom,
      child: Column(children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragEnd: (d) => onSwipe?.call((d.primaryVelocity ?? 0) < 0),
          child: SizedBox(
            width: double.infinity,
            child: Column(children: [
              SvgPicture.asset('${PokeStyle.assets}/icons/${open ? 'handle' : 'handle_closed'}.svg', width: 33, height: 3),
              const SizedBox(height: 6),
            ]),
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [BoxShadow(color: Color(0x4D212121), blurRadius: 14)],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              const Positioned.fill(child: DotBackground(topFade: [0.275, 0.356], bottomFade: [0.903, 0.981], shade: false)),
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                GestureDetector(
                  onVerticalDragEnd: (d) => onSwipe?.call((d.primaryVelocity ?? 0) < 0),
                  child: Padding(padding: const EdgeInsets.all(12), child: _TabBar(selected: tab, onTab: onTab)),
                ),
                if (open && child != null) Expanded(child: child!),
              ]),
              if (open)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
                    alignment: Alignment.centerRight,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00FFFFFF), Color(0x9CFFFFFF), Colors.white],
                        stops: [0, 0.588, 0.962],
                      ),
                    ),
                    child: Semantics(
                      button: true,
                      label: '닫기',
                      child: GestureDetector(
                        onTap: onClose,
                        child: SvgPicture.asset('${PokeStyle.assets}/icons/circle_x.svg', width: 41, height: 41),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// ✉️ 카드 디자인 · 💬 문구 · 😎 이모지. 고른 탭은 분홍 빛으로.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onTab});

  final NoteTab? selected;
  final ValueChanged<NoteTab> onTab;

  static const _icons = {
    NoteTab.card: ('${PokeStyle.assets}/icons/envelope.png', -10.18, '카드 디자인'),
    NoteTab.text: ('${PokeStyle.assets}/icons/speech_balloon.png', 13.93, '문구'),
    NoteTab.emoji: ('${PokeStyle.assets}/stickers/sunglasses.png', -10.29, '이모지'),
  };

  @override
  Widget build(BuildContext context) => Container(
        height: 93,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [BoxShadow(color: Color(0x1A212121), blurRadius: 10, offset: Offset(0, 6))],
        ),
        child: Row(children: [
          for (final t in NoteTab.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: t == selected,
                label: _icons[t]!.$3,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTab(t),
                  child: _TabCell(asset: _icons[t]!.$1, degrees: _icons[t]!.$2, selected: t == selected),
                ),
              ),
            ),
        ]),
      );
}

class _TabCell extends StatelessWidget {
  const _TabCell({required this.asset, required this.degrees, required this.selected});

  final String asset;
  final double degrees;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = Center(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Transform.rotate(
          angle: degrees * math.pi / 180,
          child: StickerImage(
            asset,
            size: 62,
            shadow: selected ? const Color(0x80FFFFFF) : const Color(0x33212121),
            shadowBlur: 4,
          ),
        ),
      ),
    );
    if (!selected) return icon;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFBC6FF)),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 2)],
        gradient: const LinearGradient(
          begin: Alignment(-0.78, -1),
          end: Alignment(0.78, 1),
          colors: [Color(0xFFF59AFE), PokeStyle.pink],
          stops: [0.175, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const RadialGradient(
            radius: 0.7,
            colors: [Color(0xC4F147FF), Color(0x62F57BFF), Color(0x00F8AFFE)],
            stops: [0.288, 0.644, 1],
          ),
        ),
        child: icon,
      ),
    );
  }
}

/// 카드 디자인 시트: 디자인 6종이 사진처럼 흩어져 있다 (피그마 882:21547).
class CardPicker extends StatelessWidget {
  const CardPicker({super.key, required this.onPick});

  final ValueChanged<NoteCard> onPick;

  /// (왼쪽, 위, 감싸는 상자 크기, 회전, 썸네일 크기, 흰 테두리)
  static const _layout = {
    NoteCard.airmail: (4.54, 0.0, Size(82.098, 79.688), 10.39, Size(71, 68), 6.0),
    NoteCard.grid: (107.0, 9.0, Size(85.259, 83.068), -13.9, Size(71, 68), 6.0),
    NoteCard.check: (212.0, 0.0, Size(93.312, 91.89), 25.41, Size(71, 68), 6.0),
    NoteCard.flower: (0.0, 116.0, Size(86.485, 84.388), -15.37, Size(71, 68), 7.0),
    NoteCard.heart: (113.0, 121.0, Size(79.575, 77.01), 7.8, Size(71, 68), 6.0),
    NoteCard.music: (222.0, 121.0, Size.square(78.286), -9.5, Size.square(68), 6.0),
  };

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.only(top: 42, bottom: 90),
        child: Center(
          child: SizedBox(
            width: 300,
            height: 200,
            child: Stack(clipBehavior: Clip.none, children: [
              for (final MapEntry(key: card, value: (left, top, box, degrees, size, border)) in _layout.entries)
                Positioned(
                  left: left,
                  top: top,
                  width: box.width,
                  height: box.height,
                  child: Center(
                    child: Transform.rotate(
                      angle: degrees * math.pi / 180,
                      child: Semantics(
                        button: true,
                        label: card.label,
                        child: GestureDetector(
                          onTap: () => onPick(card),
                          child: Container(
                            width: size.width,
                            height: size.height,
                            padding: EdgeInsets.all(border),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Color(0x33212121), blurRadius: 8)],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12 - border),
                              child: NoteCardThumbnail(card),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      );
}

/// 문구 시트: 프리셋 6개, 2열 (피그마 884:21894).
class PhrasePicker extends StatelessWidget {
  const PhrasePicker({super.key, required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 32, 22, 90),
        child: Column(children: [
          for (var row = 0; row < notePhrases.length; row += 2) ...[
            if (row > 0) const SizedBox(height: 26),
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final (i, phrase) in notePhrases.sublist(row, math.min(row + 2, notePhrases.length)).indexed) ...[
                  if (i > 0) const SizedBox(width: 24),
                  Expanded(child: _PhraseTile(phrase, onTap: () => onPick(phrase))),
                ],
              ]),
            ),
          ],
        ]),
      );
}

class _PhraseTile extends StatelessWidget {
  const _PhraseTile(this.phrase, {required this.onTap});

  final String phrase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: phrase.replaceAll('\n', ' '),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 6),
              boxShadow: const [BoxShadow(color: Color(0x33212121), blurRadius: 4)],
            ),
            child: ExcludeSemantics(child: Text(phrase, textAlign: TextAlign.center, style: PokeStyle.note(PokeStyle.text))),
          ),
        ),
      );
}

/// 이모지 시트: 스티커 12종, 3열. 사진처럼 하나씩 기울어져 있다 (피그마 917:3294).
class EmojiPicker extends StatelessWidget {
  const EmojiPicker({super.key, required this.onPick});

  final ValueChanged<NoteSticker> onPick;

  static const _tilts = [-19.9, 31.96, 37.68, 16.19, -21.47, 18.79, -40.23, 17.13, -36.99, 0.0, 22.65, -16.24];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.only(top: 29, bottom: 90),
        child: Center(
          // 3열 = 103 × 3
          child: SizedBox(
            width: 309,
            child: Wrap(
              runSpacing: 6,
              children: [
                for (final (i, sticker) in NoteSticker.values.indexed)
                  Semantics(
                    button: true,
                    label: sticker.label,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onPick(sticker),
                      child: SizedBox.square(
                        dimension: 103,
                        child: Center(
                          child: Transform.rotate(
                            angle: _tilts[i] * math.pi / 180,
                            child: StickerImage(PokeStyle.sticker(sticker), size: 86, shadowBlur: 8.24),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
