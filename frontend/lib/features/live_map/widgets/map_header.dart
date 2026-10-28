import 'package:flutter/material.dart';

import 'live_style.dart';

/// 지도 위 상단 오버레이: 왼쪽 닫기, 오른쪽 더보기와 [내 위치 · 목적지] 버튼.
/// 마커를 누르면 그 사람 카드([card])가 더보기 아래에 뜬다.
class MapHeader extends StatelessWidget {
  const MapHeader({
    super.key,
    required this.onClose,
    required this.moreMenu,
    required this.onMyLocation,
    required this.onDestination,
    this.card,
  });

  final VoidCallback onClose;

  /// 더보기 버튼을 눌렀을 때 고를 항목. 고르면 그 항목의 콜백을 부른다.
  final Map<String, VoidCallback> moreMenu;
  final VoidCallback onMyLocation;
  final VoidCallback onDestination;
  final Widget? card;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(children: [
            _RoundButton(icon: 'close', iconSize: 21, padding: 10.5, tooltip: '닫기', onTap: onClose),
            const Spacer(),
            PopupMenuButton<VoidCallback>(
              tooltip: '더보기',
              position: PopupMenuPosition.under,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (action) => action(),
              itemBuilder: (_) => [
                for (final e in moreMenu.entries)
                  PopupMenuItem(value: e.value, child: Text(e.key, style: liveText(14, FontWeight.w500, LiveColors.textStrong))),
              ],
              child: const _RoundButton(icon: 'more', iconSize: 20, padding: 10),
            ),
          ]),
          if (card != null) ...[const SizedBox(height: 18), card!],
          SizedBox(height: card == null ? 32 : 18),
          Container(
            width: 40,
            decoration: _floating(radius: 32),
            child: Column(children: [
              _IconTap(icon: 'my_location', tooltip: '내 위치', onTap: onMyLocation),
              _IconTap(icon: 'destination', tooltip: '목적지', onTap: onDestination),
            ]),
          ),
        ]),
      );
}

/// 지도 위에 떠 있는 흰 요소.
BoxDecoration _floating({required double radius}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: LiveColors.border),
      boxShadow: liveShadow,
    );

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.iconSize, required this.padding, this.tooltip, this.onTap});

  final String icon;
  final double iconSize;
  final double padding;
  final String? tooltip;

  /// 없으면 바깥(PopupMenuButton 등)이 탭을 받는다.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      padding: EdgeInsets.all(padding),
      decoration: _floating(radius: 999),
      child: LiveIcon(icon, size: iconSize),
    );
    if (onTap == null) return circle;
    return Tooltip(message: tooltip ?? '', child: GestureDetector(onTap: onTap, child: circle));
  }
}

class _IconTap extends StatelessWidget {
  const _IconTap({required this.icon, required this.tooltip, required this.onTap});

  final String icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(padding: const EdgeInsets.all(11.5), child: LiveIcon(icon, size: 17)),
        ),
      );
}
