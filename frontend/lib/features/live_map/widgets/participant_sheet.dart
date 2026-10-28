import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../data/models/live_location.dart';
import 'arrival_status.dart';
import 'live_style.dart';

/// 07 하단 시트 — 도착 현황 + 콕 찌르기.
/// 남은 시간과 프로필 줄이 보이는 높이가 기본이고, 끝까지 올리면 지도를 덮는 전체 화면(767:21626)이 된다.
/// 전체 화면에서는 손잡이 대신 ←가 보이고, 누르면 기본 높이로 내려간다.
class ParticipantSheet extends StatefulWidget {
  const ParticipantSheet({
    super.key,
    required this.session,
    required this.meId,
    required this.cooldownOf,
    required this.onPoke,
    required this.onShowResult,
    this.statusMessages = const {},
  });

  static const initialSize = 0.4;

  final LiveSession session;
  final String meId;
  final Duration Function(String participantId) cooldownOf;
  final ValueChanged<LiveParticipant> onPoke;
  final VoidCallback onShowResult;
  final Map<String, String> statusMessages;

  @override
  State<ParticipantSheet> createState() => _ParticipantSheetState();
}

class _ParticipantSheetState extends State<ParticipantSheet> {
  final _controller = DraggableScrollableController();

  /// 시트 안 목록. 접을 때 맨 위(남은 시간)로 되돌린다.
  ScrollController? _scroll;

  /// 이 높이부터 전체 화면 모양으로 서서히 바뀐다.
  static const _morphFrom = 0.9;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _collapse() {
    const duration = Duration(milliseconds: 250);
    if (_scroll?.hasClients ?? false) _scroll!.jumpTo(0);
    _controller.animateTo(ParticipantSheet.initialSize, duration: duration, curve: Curves.easeOutCubic);
  }

  /// 고정된 맨 위 영역을 끌어도 시트가 따라 움직이게.
  void _dragHeader(DragUpdateDetails d, double screenHeight) => _controller.jumpTo((_controller.size - d.delta.dy / screenHeight).clamp(0.14, 1.0));

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: ParticipantSheet.initialSize,
      minChildSize: 0.14,
      maxChildSize: 1,
      snap: true,
      snapSizes: const [ParticipantSheet.initialSize],
      builder: (context, scroll) {
        _scroll = scroll;
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final size = _controller.isAttached ? _controller.size : ParticipantSheet.initialSize;
            final t = ((size - _morphFrom) / (1 - _morphFrom)).clamp(0.0, 1.0);
            final full = size > 0.999;
            // 기본: 위 20 + 손잡이 3 + 20. 전체 화면: 상태바 + ← 줄 50 + 20.
            final headerHeight = lerpDouble(43, media.padding.top + 70, t)!;

            return DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20 * (1 - t))),
                boxShadow: [BoxShadow(color: LiveColors.shadow.withValues(alpha: 0.2 * (1 - t)), blurRadius: 7.9)],
              ),
              child: Column(children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (d) => _dragHeader(d, media.size.height),
                  child: SizedBox(
                    height: headerHeight,
                    width: double.infinity,
                    child: Stack(children: [
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: 1 - t,
                          child: Center(
                            child: Container(
                              width: 42,
                              height: 3,
                              decoration: BoxDecoration(color: LiveColors.handle, borderRadius: BorderRadius.circular(2)),
                            ),
                          ),
                        ),
                      ),
                      if (t > 0)
                        Positioned(
                          top: headerHeight - 70 + 13,
                          left: 20,
                          child: Opacity(
                            opacity: t,
                            child: IgnorePointer(
                              ignoring: !full,
                              child: Tooltip(
                                message: '지도 보기',
                                child: GestureDetector(onTap: _collapse, child: const LiveIcon('arrow_left', size: 24)),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      ArrivalStatusPanel(
                        session: widget.session,
                        meId: widget.meId,
                        cooldownOf: widget.cooldownOf,
                        onPoke: widget.onPoke,
                        onShowResult: widget.onShowResult,
                        statusMessages: widget.statusMessages,
                        full: full,
                      ),
                    ],
                  ),
                ),
              ]),
            );
          },
        );
      },
    );
  }
}
