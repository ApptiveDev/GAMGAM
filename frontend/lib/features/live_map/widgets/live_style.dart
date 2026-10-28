import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../../data/models/participant.dart';

/// 당일 지도 화면 글자. Pretendard, 자간 -0.3, 행간 1.
TextStyle liveText(double size, FontWeight weight, Color color) =>
    TextStyle(fontFamily: 'Pretendard', fontSize: size, fontWeight: weight, color: color, letterSpacing: -0.3, height: 1);

/// 지도 위에 떠 있는 흰 요소의 그림자.
const liveShadow = [BoxShadow(color: LiveColors.shadow, blurRadius: 2)];

/// 당일 지도 아이콘 (assets/icons/live_map).
class LiveIcon extends StatelessWidget {
  const LiveIcon(this.name, {super.key, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset('assets/icons/live_map/$name.svg', width: size, height: size);
}

/// 프로필 원. 프로필 이미지가 생기기 전까지 이름 첫 글자를 보여준다.
/// 위치 공유를 끈 사람은 점선 테두리 + 회색으로 덮는다.
class LiveAvatar extends StatelessWidget {
  const LiveAvatar(this.participant, {super.key, required this.size, required this.borderWidth, this.off = false, this.selected = false});

  final Participant participant;
  final double size;
  final double borderWidth;
  final bool off;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final label = Text(participant.initial, style: liveText(size * 0.36, FontWeight.w600, off ? LiveColors.textHint : LiveColors.textBody));
    if (off) {
      return DashedBorder(
        radius: size / 2,
        color: LiveColors.border,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: LiveColors.sharingOffOverlay),
          child: label,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: selected ? LiveColors.selected : LiveColors.outline, width: borderWidth),
        boxShadow: selected ? const [BoxShadow(color: LiveColors.selectedHalo, spreadRadius: 5)] : null,
      ),
      child: label,
    );
  }
}

/// "8:88:88" 도트 타이머. Matrix Sans Screen은 숫자 1만 폭이 좁아서
/// 숫자마다 같은 폭 칸에 넣어 초가 바뀔 때 글자가 흔들리지 않게 한다.
class DotTimer extends StatelessWidget {
  const DotTimer(this.text, {super.key, this.size = 32});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontFamily: 'MatrixSansScreen', fontSize: size, color: LiveColors.textStrong, letterSpacing: -0.3, height: 1);
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final c in text.characters)
            c == ':' ? Text(c, style: style) : SizedBox(width: size * 0.6, child: Text(c, style: style, textAlign: TextAlign.center)),
        ]),
      ),
    );
  }
}

/// 콕 찌르기·쿨다운·등수·편집에 쓰는 둥근 버튼.
class LivePill extends StatelessWidget {
  const LivePill({super.key, required this.label, required this.background, required this.foreground, this.onTap, this.minWidth = 0});

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final double minWidth;

  @override
  Widget build(BuildContext context) => Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: BoxConstraints(minWidth: minWidth),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(label,
                textAlign: TextAlign.center,
                style: liveText(13, FontWeight.w400, foreground).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        ),
      );
}
