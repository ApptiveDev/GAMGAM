import 'package:flutter/material.dart';

import '../../theme/gam_colors.dart';
import '../../theme/gam_text.dart';
import 'gam_icon.dart';

/// 흰 테두리 안에 사진이 들어간 폴라로이드 카드. 약속 썸네일에 쓴다.
/// 기준 크기는 86×116 (padding 5, radius 11), 약속 상세는 122×133 처럼 크기만 바꿔 쓴다.
class PhotoCard extends StatelessWidget {
  const PhotoCard({super.key, required this.image, this.width = 86, this.height = 116});

  final String? image;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scale = width / 86;
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(5 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11 * scale),
        border: Border.all(color: GamColors.cardOutline, width: scale.clamp(1, 1.4)),
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5 * scale),
          border: Border.all(color: GamColors.photoOutline, width: scale.clamp(1, 1.4)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5 * scale),
          child: SizedBox.expand(
            child: image == null
                ? const ColoredBox(color: GamColors.placeholder)
                : Image.asset(image!, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

/// 홈·그룹 상세의 약속 한 칸: 사진 카드 + 이름 (+ 투표 중이면 분홍 점).
class AppointmentGridItem extends StatelessWidget {
  const AppointmentGridItem({super.key, required this.name, required this.image, required this.onTap, this.voting = false});

  final String name;
  final String? image;
  final bool voting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 86,
          height: 148,
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            PhotoCard(image: image),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                child: Text(name, style: GamText.name15, maxLines: 1, overflow: TextOverflow.visible, softWrap: false),
              ),
              if (voting) ...[
                const SizedBox(width: 2),
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: GamColors.pink, shape: BoxShape.circle),
                ),
              ],
            ]),
          ]),
        ),
      );
}

/// 약속 그리드 마지막의 "+" 카드. 누르면 약속을 만든다.
class AddAppointmentItem extends StatelessWidget {
  const AddAppointmentItem({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 86,
          height: 148,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 86,
              height: 116,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: GamColors.cardOutline),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: GamColors.placeholder,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: GamColors.photoOutline),
                ),
                alignment: Alignment.center,
                child: const GamIcon('ic_fab_plus', size: 24),
              ),
            ),
          ),
        ),
      );
}

/// 3열 그리드. 디자인은 308 폭에 86짜리 3개를 양끝 정렬, 줄 간격 40.
class AppointmentGrid extends StatelessWidget {
  const AppointmentGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[];
    for (var i = 0; i < children.length; i += 3) {
      rows.add(children.sublist(i, (i + 3).clamp(0, children.length)));
    }
    return Column(children: [
      for (final (i, row) in rows.indexed) ...[
        if (i > 0) const SizedBox(height: 40),
        Row(
          mainAxisAlignment: row.length == 3 ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
          children: [
            for (final (j, child) in row.indexed) ...[
              if (j > 0 && row.length < 3) const SizedBox(width: 25),
              child,
            ],
          ],
        ),
      ],
    ]);
  }
}
