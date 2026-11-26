import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/gam_colors.dart';

/// 새 디자인의 화면 바탕: 분홍 테두리 6px 안에 둥근(30) 화면.
/// [background]가 sky면 위쪽에 하늘색 그라데이션 이미지를 깔고 아래로 갈수록 회보라색으로 흐려진다.
class PinkFrame extends StatelessWidget {
  const PinkFrame({
    super.key,
    required this.child,
    this.background = FrameBackground.sky,
    this.fadeStart = 0,
    this.fadeEnd = 0.22,
    this.resizeToAvoidBottomInset = true,
    this.scrollWith,
  });

  final Widget child;

  /// 지정하면 하늘 배경이 화면에 고정되지 않고 이 스크롤을 따라 함께 위로 올라간다.
  final ScrollController? scrollWith;
  final FrameBackground background;

  /// 하늘색이 회보라색으로 바뀌는 구간 (화면 높이 1013 기준 비율). Figma "배경색상2" 그라데이션 값.
  final double fadeStart;
  final double fadeEnd;

  /// 키보드가 올라오면 화면을 줄일지. 배경이 움직이면 안 되는 화면은 끈다.
  final bool resizeToAvoidBottomInset;

  static const inset = 6.0;
  static const radius = 30.0;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: background == FrameBackground.sky ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: GamColors.pink,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          body: Padding(
            padding: const EdgeInsets.all(inset),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(fit: StackFit.expand, children: [
                switch (background) {
                  FrameBackground.white => const ColoredBox(color: Colors.white),
                  FrameBackground.plain => const ColoredBox(color: GamColors.pickPage),
                  FrameBackground.sky => SkyBackground(fadeStart: fadeStart, fadeEnd: fadeEnd, scrollWith: scrollWith),
                },
                child,
              ]),
            ),
          ),
        ),
      );
}

/// [plain]은 시간 정하기처럼 회색 바탕 화면.
enum FrameBackground { sky, white, plain }

/// 하늘 그라데이션 이미지. 화면이 길어도 위쪽 768만 하늘색이고 나머지는 회보라색이다.
/// Figma는 이 위에 흐림(blur)을 걸지만 바탕이 매끈한 그라데이션이라 결과가 같아서 생략한다.
class SkyBackground extends StatelessWidget {
  const SkyBackground({super.key, this.fadeStart = 0, this.fadeEnd = 0.22, this.scrollWith});

  final double fadeStart;
  final double fadeEnd;

  /// [PinkFrame.scrollWith] 참고.
  final ScrollController? scrollWith;

  @override
  Widget build(BuildContext context) {
    final sky = _sky();
    final scroll = scrollWith;
    return Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: GamColors.canvas),
      if (scroll == null)
        sky
      else
        // 하늘 부분만 스크롤만큼 위로 옮긴다. 회보라 바탕은 그대로라 아래가 비지 않는다.
        // 맨 위에서 당겨 늘어날 때(음수)는 내리지 않아 위쪽 빈틈이 생기지 않게 한다.
        AnimatedBuilder(
          animation: scroll,
          child: sky,
          builder: (context, child) {
            final offset = scroll.hasClients && scroll.positions.length == 1 ? scroll.offset : 0.0;
            return Transform.translate(offset: Offset(0, -offset.clamp(0.0, double.infinity)), child: child);
          },
        ),
    ]);
  }

  Widget _sky() => Stack(fit: StackFit.expand, children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Image.asset('assets/figma/home_bg.png', fit: BoxFit.fitWidth, alignment: Alignment.topCenter),
        ),
        if (fadeEnd > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1013,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [Color(0x00D7D9E6), GamColors.canvas],
                  stops: [fadeStart, fadeEnd],
                ),
              ),
            ),
          ),
      ]);
}

/// 화면 맨 위 상단 바 높이 (상태바 아래 뒤로가기 줄).
class FrameTopBar extends StatelessWidget {
  const FrameTopBar({super.key, this.leading, this.trailing, this.middle});

  final Widget? leading;
  final Widget? middle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: SizedBox(
          height: 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(children: [
              if (leading != null) leading!,
              if (middle != null) Expanded(child: middle!) else const Spacer(),
              if (trailing != null) trailing!,
            ]),
          ),
        ),
      );
}
