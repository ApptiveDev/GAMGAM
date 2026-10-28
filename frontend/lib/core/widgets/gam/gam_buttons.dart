import 'package:flutter/material.dart';

import '../../theme/gam_colors.dart';
import '../../theme/gam_text.dart';
import 'gam_icon.dart';

/// 둥근 알약 버튼. 분홍(주요)·테두리(취소)·회색(카드 안) 세 가지.
class PillButton extends StatelessWidget {
  const PillButton(
    this.label, {
    super.key,
    required this.onTap,
    this.style = PillStyle.pink,
    this.padding = const EdgeInsets.symmetric(horizontal: 21, vertical: 17),
    this.textStyle,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onTap;
  final PillStyle style;
  final EdgeInsets padding;
  final TextStyle? textStyle;
  final Widget? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final (Color? fill, Color? border) = switch (style) {
      PillStyle.pink => (GamColors.pink, null),
      PillStyle.outline => (null, GamColors.outlineButton),
      PillStyle.card => (GamColors.cardButton, null),
      PillStyle.light => (GamColors.surfaceSoft, GamColors.photoOutline),
      PillStyle.white => (Colors.white.withValues(alpha: 0.85), GamColors.photoOutline),
    };
    final text = (textStyle ?? GamText.button14).copyWith(color: disabled ? GamColors.text400 : null);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(40),
          border: border == null ? null : Border.all(color: border, width: 1.3),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(label, style: text),
          ],
        ),
      ),
    );
  }
}

enum PillStyle { pink, outline, card, light, white }

/// 오른쪽 아래 분홍 "+" 버튼 (55×55).
class PinkFab extends StatelessWidget {
  const PinkFab({super.key, required this.onTap, this.tooltip});

  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final fab = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14.964),
        decoration: const BoxDecoration(
          color: GamColors.pink,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x40212121), blurRadius: 2)],
        ),
        child: const GamIcon('ic_fab_plus', size: 24.939),
      ),
    );
    return tooltip == null ? fab : Tooltip(message: tooltip!, child: fab);
  }
}

/// 홈·그룹·내정보 하단 바: 흰 알약 안 탭 아이콘 3개 + 오른쪽 분홍 "+".
class GamBottomBar extends StatelessWidget {
  const GamBottomBar({super.key, required this.currentIndex, required this.onTab, required this.onAdd, this.addTooltip});

  final int currentIndex;
  final ValueChanged<int> onTab;
  final VoidCallback? onAdd;
  final String? addTooltip;

  static const _tabs = [
    ('ic_nav_home', '홈'),
    ('ic_nav_folder', '그룹'),
    ('ic_nav_user', '내정보'),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 308,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              width: 233.182,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28.68),
                boxShadow: const [BoxShadow(color: Color(0x40212121), blurRadius: 2)],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (final (i, (icon, label)) in _tabs.indexed)
                  Semantics(
                    label: label,
                    selected: i == currentIndex,
                    button: true,
                    child: GestureDetector(
                      onTap: () => onTab(i),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 44,
                        height: 54.866,
                        child: Center(
                          child: GamIcon(icon, size: 24.939, color: i == currentIndex ? const Color(0xFF030409) : const Color(0xFFDBDBDB)),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
            if (onAdd != null) PinkFab(onTap: onAdd!, tooltip: addTooltip),
          ]),
        ),
      );
}
