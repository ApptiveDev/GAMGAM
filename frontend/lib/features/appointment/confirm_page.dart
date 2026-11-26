import 'package:flutter/material.dart';

import '../../core/theme/gam_colors.dart';
import '../../core/theme/gam_text.dart';
import '../../core/widgets/gam/gam_icon.dart';
import '../../core/widgets/gam/pink_frame.dart';

/// 확정하기 페이지의 후보 하나.
class ConfirmOption<T> {
  const ConfirmOption({required this.value, required this.label, required this.text, this.votes = 0});

  final T value;

  /// 줄에 보이는 내용(시간 글자, 장소 썸네일+이름).
  final Widget label;

  /// 아래 버튼의 "…로 확정"에 들어가는 글자.
  final String text;
  final int votes;
}

/// 확정하기 페이지를 연다. 확정 버튼을 누르면 고른 값, 뒤로 가면 null. (Figma 1720:17857 · 선택해제 1720:17980)
/// 처음엔 1위 후보를 골라 둔다. [onDirect]로 "다른 … 직접 정하기"를 하면 그 값이 새 줄로 들어가고 골라진다.
Future<T?> openConfirmPage<T>(
  BuildContext context, {
  required List<ConfirmOption<T>> options,
  required int participantCount,
  required String directLabel,
  required Future<ConfirmOption<T>?> Function(BuildContext context) onDirect,
  bool Function(T a, T b)? same,
}) =>
    Navigator.of(context).push<T>(MaterialPageRoute(
      builder: (_) => ConfirmPage<T>(
        options: options,
        participantCount: participantCount,
        directLabel: directLabel,
        onDirect: onDirect,
        same: same,
      ),
    ));

class ConfirmPage<T> extends StatefulWidget {
  const ConfirmPage({
    super.key,
    required this.options,
    required this.participantCount,
    required this.directLabel,
    required this.onDirect,
    this.same,
  });

  final List<ConfirmOption<T>> options;
  final int participantCount;
  final String directLabel;
  final Future<ConfirmOption<T>?> Function(BuildContext context) onDirect;

  /// 같은 후보인지. 비우면 ==.
  final bool Function(T a, T b)? same;

  @override
  State<ConfirmPage<T>> createState() => _ConfirmPageState<T>();
}

class _ConfirmPageState<T> extends State<ConfirmPage<T>> {
  late final List<ConfirmOption<T>> _options = [...widget.options];

  /// 득표가 가장 많은 후보(같으면 먼저 올라온 것). 아무도 안 찍었으면 없음.
  late final ConfirmOption<T>? _leader = _options.fold<ConfirmOption<T>?>(
    null,
    (best, o) => o.votes > 0 && (best == null || o.votes > best.votes) ? o : best,
  );
  late ConfirmOption<T>? _picked = _leader;

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    return PinkFrame(
      background: FrameBackground.white,
      child: Column(children: [
        FrameTopBar(
          leading: GamIconButton('ic_arrow_left_dark', tooltip: '뒤로', onTap: () => Navigator.of(context).pop()),
          middle: Padding(padding: const EdgeInsets.only(left: 2), child: Text('확정하기', style: GamText.body16)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 26, 24, 24),
            children: [
              for (final (i, o) in _options.indexed)
                _OptionRow(
                  option: o,
                  leader: identical(o, _leader),
                  selected: identical(o, picked),
                  first: i == 0,
                  last: i == _options.length - 1,
                  fraction: widget.participantCount == 0 ? 0 : o.votes / widget.participantCount,
                  // 고른 줄을 다시 누르면 선택을 푼다(Figma 선택해제).
                  onTap: () => setState(() => _picked = identical(o, picked) ? null : o),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _direct,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const GamIcon('ic_plus_24', size: 24),
                      const SizedBox(width: 8),
                      Text(widget.directLabel, style: GamText.body14.copyWith(color: GamColors.text600)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
        _ConfirmBar(
          label: picked == null ? '확정할 항목을 선택해주세요' : '${picked.text}로 확정',
          onTap: picked == null ? null : () => Navigator.of(context).pop(picked.value),
        ),
      ]),
    );
  }

  Future<void> _direct() async {
    final added = await widget.onDirect(context);
    if (added == null || !mounted) return;
    setState(() {
      final isSame = widget.same ?? (T a, T b) => a == b;
      final same = _options.where((o) => isSame(o.value, added.value)).firstOrNull;
      if (same != null) {
        _picked = same;
      } else {
        _options.add(added);
        _picked = added;
      }
    });
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.leader,
    required this.selected,
    required this.first,
    required this.last,
    required this.fraction,
    required this.onTap,
  });

  final ConfirmOption<T> option;
  final bool leader;
  final bool selected;
  final bool first;
  final bool last;
  final double fraction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.only(top: first ? 0 : 20, bottom: last ? 0 : 20),
            decoration: BoxDecoration(
              border: last ? null : const Border(bottom: BorderSide(color: GamColors.surface)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GamIcon(selected ? 'ic_check_circle_on' : 'ic_radio_off_light', size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      if (leader) ...[const RankChip(), const SizedBox(width: 6)],
                      Expanded(child: Align(alignment: Alignment.centerLeft, child: option.label)),
                      const SizedBox(width: 8),
                      Text('${option.votes}명', style: GamText.regular12),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  _Bar(fraction: fraction, on: selected),
                ]),
              ),
            ]),
          ),
        ),
      );
}

/// 분홍 "1위" 칩.
class RankChip extends StatelessWidget {
  const RankChip({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: GamColors.pink, borderRadius: BorderRadius.circular(28)),
        child: Text('1위', style: GamText.body13.copyWith(fontWeight: FontWeight.w600)),
      );
}

/// 5px 둥근 막대. 고른 줄은 분홍, 아니면 회보라.
class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.on});

  final double fraction;
  final bool on;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          height: 5,
          child: Stack(children: [
            const Positioned.fill(child: ColoredBox(color: GamColors.pickPage)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0, 1),
              child: ColoredBox(color: on ? GamColors.pink : GamColors.card, child: const SizedBox.expand()),
            ),
          ]),
        ),
      );
}

/// 맨 아래 흰 띠와 "…로 확정" 버튼. 고른 게 없으면 회색.
class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F0F5))),
        ),
        padding: EdgeInsets.fromLTRB(20, 26, 20, 26 + MediaQuery.paddingOf(context).bottom),
        child: Material(
          color: onTap == null ? GamColors.card : GamColors.pink,
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GamText.body16.copyWith(fontSize: 15, color: onTap == null ? GamColors.text300 : GamColors.text900),
                ),
              ),
            ),
          ),
        ),
      );
}
