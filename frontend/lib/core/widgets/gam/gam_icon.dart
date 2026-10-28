import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Figma에서 받은 SVG 아이콘. 색을 바꿔야 할 때만 [color]를 준다.
class GamIcon extends StatelessWidget {
  const GamIcon(this.name, {super.key, this.size = 24, this.color});

  /// assets/figma/ 안의 파일 이름 (확장자 제외).
  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/figma/$name.svg',
        width: size,
        height: size,
        colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      );
}

/// 아이콘만 있는 터치 영역. 손가락으로 누르기 쉽게 44 이상으로 잡는다.
class GamIconButton extends StatelessWidget {
  const GamIconButton(this.name, {super.key, required this.onTap, this.size = 24, this.color, this.tooltip});

  final String name;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox.square(dimension: 44, child: Center(child: GamIcon(name, size: size, color: color))),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
