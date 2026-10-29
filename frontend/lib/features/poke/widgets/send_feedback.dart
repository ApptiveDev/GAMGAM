import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/models/poke_note.dart';
import 'note_card.dart';
import 'poke_style.dart';
import 'sticker_layer.dart';

const _panel = Color(0xFF5E626A);

TextStyle _pretendard(double size, FontWeight weight, Color color) =>
    TextStyle(fontFamily: 'Pretendard', fontSize: size, fontWeight: weight, color: color, height: 1, letterSpacing: -0.3);

/// 보내기 직후 하단 "완료하는 중 · 취소" (피그마 1047:16409). 막대가 다 차면 실제로 보낸다.
class SendingBar extends StatelessWidget {
  const SendingBar({super.key, required this.progress, required this.onCancel});

  final Animation<double> progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Container(
        height: 39,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(10)),
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('완료하는 중', style: _pretendard(14, FontWeight.w500, Colors.white)),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCancel,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Text('취소', style: _pretendard(14, FontWeight.w600, PokeStyle.pink)),
                ),
              ),
            ]),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 37,
            height: 2,
            child: ColoredBox(
              color: const Color(0xFF828282),
              child: AnimatedBuilder(
                animation: progress,
                builder: (context, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.value,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(color: PokeStyle.pink, borderRadius: BorderRadius.horizontal(right: Radius.circular(1))),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
}

/// 상단 "콕 찌르기를 전송했습니다" (피그마 1047:16541). 잠시 뒤 [expanded]로 펼쳐져 "콕 찌르기 보기"가 나온다 (1055:16963).
class SentToast extends StatelessWidget {
  const SentToast({super.key, required this.expanded, required this.onView});

  final bool expanded;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x40212121), blurRadius: 8, offset: Offset(0, 1))],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: IntrinsicWidth(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  SvgPicture.asset('${PokeStyle.assets}/icons/check_circle.svg', width: 22, height: 22),
                  const SizedBox(width: 8),
                  Text('콕 찌르기를 전송했습니다', style: _pretendard(14, FontWeight.w500, Colors.white)),
                ]),
              ),
              if (expanded) ...[
                const SizedBox(height: 10),
                Material(
                  color: const Color(0xFF858990),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: onView,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('콕 찌르기 보기', textAlign: TextAlign.center, style: _pretendard(13, FontWeight.w600, Colors.white)),
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      );
}

/// "콕 찌르기 보기": 방금 보낸 쪽지를 크게 보여준다. 피그마에 화면이 없어서 쪽지 화면과 같은 카드·스티커만 띄운다.
Future<void> showSentNote(BuildContext context, PokeNote note) => showDialog<void>(
      context: context,
      barrierColor: const Color(0x66212121),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NoteCardView.radius),
              boxShadow: const [BoxShadow(color: Color(0x4D212121), blurRadius: 7)],
            ),
            child: PokeNoteView(note: note, placeholder: false),
          ),
        ),
      ),
    );
