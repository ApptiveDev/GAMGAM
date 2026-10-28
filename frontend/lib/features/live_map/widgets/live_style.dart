import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/gam_colors.dart';
import '../../../core/theme/gam_text.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../../core/widgets/gam/member_avatars.dart';
import '../../../data/models/participant.dart';

/// 당일 지도 화면의 색 역할. 값은 [GamColors]를 쓰고, 지도에만 있는 색만 여기서 정한다.
abstract final class LiveColors {
  /// 콕 찌르기 같은 주요 액션 배경. 위 글자는 [onAccent](흰 글자 아님).
  static const accent = GamColors.pink;
  static const onAccent = GamColors.text900;

  /// 쿨다운·등수·편집처럼 누를 수 없거나 덜 중요한 pill.
  static const muted = GamColors.placeholder;
  static const onMuted = GamColors.photoOutline;

  static const textStrong = GamColors.text900;
  static const textBody = GamColors.text800;
  static const textSub = GamColors.text600;
  static const textHint = GamColors.text400;
  static const textFaint = Color(0x99666666);
  static const handle = GamColors.canvas;

  /// 선택된 마커 테두리와 후광.
  static const selected = Color(0xFF6FAEFF);
  static const selectedHalo = Color(0x85BCDAFF);

  /// 지도 위 흰 버튼·카드 테두리.
  static const border = Color(0xFFDBDBDB);
  static const sharingOffOverlay = Color(0xB3DBDBDB);

  /// 시트를 끝까지 올린 전체 화면(767:21626)에서는 덮개가 조금 더 밝다.
  static const sharingOffOverlayLight = Color(0xB3ECECEC);
  static const shadow = Color(0x33212121);
}

/// 당일 지도 화면 글자. [GamText]와 같은 규칙(Pretendard, 자간 -0.3, 행간 1)으로 크기만 자유롭게.
TextStyle liveText(double size, FontWeight weight, Color color) =>
    TextStyle(fontFamily: GamFonts.pretendard, fontSize: size, fontWeight: weight, color: color, letterSpacing: -0.3, height: 1);

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

/// [PhotoAvatar]에 당일 지도 상태를 얹는다. 선택되면 파란 테두리 + 후광,
/// 위치 공유를 끈 사람은 점선 테두리 + 회색으로 덮는다.
class LiveAvatar extends StatelessWidget {
  const LiveAvatar(
    this.participant, {
    super.key,
    required this.size,
    required this.borderWidth,
    this.off = false,
    this.selected = false,
    this.offOverlay = LiveColors.sharingOffOverlay,
  });

  final Participant participant;
  final double size;
  final double borderWidth;
  final bool off;
  final bool selected;
  final Color offOverlay;

  @override
  Widget build(BuildContext context) {
    final photo = PhotoAvatar(participant, size: size, borderWidth: borderWidth);
    if (off) {
      return DashedBorder(
        radius: size / 2,
        color: LiveColors.border,
        child: Stack(children: [
          photo,
          Positioned.fill(child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: offOverlay))),
        ]),
      );
    }
    if (!selected) return photo;
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: LiveColors.selectedHalo, spreadRadius: 5)]),
      child: Stack(children: [
        photo,
        Positioned.fill(
          child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: LiveColors.selected, width: borderWidth))),
        ),
      ]),
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
    final style = GamText.matrix(size, color: LiveColors.textStrong);
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
