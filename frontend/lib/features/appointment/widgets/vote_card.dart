import 'package:flutter/material.dart';

import '../../../core/theme/gam_colors.dart';
import '../../../core/theme/gam_text.dart';
import '../../../core/widgets/gam/gam_buttons.dart';
import '../../../core/widgets/gam/gam_icon.dart';
import '../../../data/models/place.dart';

/// 약속 상세의 회보라색 카드 (bg #D2D4E0, 테두리 #C3C5D0, radius 10).
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: GamColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GamColors.cardBorder),
        ),
        child: child,
      );
}

/// "시간", "장소" 같은 섹션 제목 + 카드.
class DetailSection extends StatelessWidget {
  const DetailSection({super.key, required this.title, required this.child, this.titlePadding = 10});

  final String title;
  final Widget child;
  final double titlePadding;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: titlePadding), child: Text(title, style: GamText.section16)),
        const SizedBox(height: 16),
        child,
      ]);
}

/// 후보가 아직 없을 때: "언제로 할까요? / 함께 가능한 시간을 찾아보세요. / + 시간 정하기"
class EmptyVoteCard extends StatelessWidget {
  const EmptyVoteCard({super.key, required this.title, required this.subtitle, required this.action, required this.onTap});

  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InfoCard(
        padding: const EdgeInsets.fromLTRB(14, 32, 14, 24),
        child: Column(children: [
          Text(title, style: GamText.section16),
          const SizedBox(height: 10),
          Text(subtitle, style: GamText.meta11),
          const SizedBox(height: 20),
          PillButton(
            action,
            style: PillStyle.light,
            textStyle: GamText.button12,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
            icon: const GamIcon('ic_plus_line', size: 20, color: GamColors.text900),
            onTap: onTap,
          ),
        ]),
      );
}

/// 투표 후보 한 줄의 내용. 시간은 글자만, 장소는 썸네일 + 이름 + "양식 · 도보 8분".
class VoteOptionLabel extends StatelessWidget {
  const VoteOptionLabel.time(String this.text, {super.key}) : place = null;
  const VoteOptionLabel.place(Place this.place, {super.key}) : text = null;

  final String? text;
  final Place? place;

  @override
  Widget build(BuildContext context) {
    final p = place;
    if (p == null) return Text(text!, style: GamText.body13);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      PlaceThumb(p),
      const SizedBox(width: 11),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(p.name, style: GamText.body13),
        const SizedBox(height: 6),
        PlaceMeta(p),
      ]),
    ]);
  }
}

class PlaceThumb extends StatelessWidget {
  const PlaceThumb(this.place, {super.key});

  final Place place;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: SizedBox(
          width: 49,
          height: 48,
          child: place.imageAsset == null
              ? const ColoredBox(color: GamColors.placeholder, child: Icon(Icons.place_outlined, size: 20, color: GamColors.text400))
              : Image.asset(place.imageAsset!, fit: BoxFit.cover),
        ),
      );
}

/// "양식 · 도보 8분"
class PlaceMeta extends StatelessWidget {
  const PlaceMeta(this.place, {super.key});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final parts = place.metaParts;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final (i, part) in parts.indexed) ...[
          if (i > 0) Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Text('·', style: GamText.dot11)),
          Text(part, style: GamText.meta11),
        ],
      ]),
    );
  }
}

/// 투표 후보 목록 카드.
/// 내가 아직 안 골랐으면 동그라미를 눌러 고르고 "투표하기", 골랐으면 득표수와 막대를 보여준다.
class VoteCard extends StatelessWidget {
  const VoteCard({
    super.key,
    required this.rows,
    required this.hasVoted,
    required this.selected,
    required this.onSelect,
    required this.onVote,
    required this.onAdd,
    required this.onClose,
    required this.onRevote,
    required this.pendingVoters,
    required this.participantCount,
  });

  final List<VoteRow> rows;

  /// 내가 이 항목에 투표했는지.
  final bool hasVoted;

  /// 투표 전 고른 후보 id.
  final Set<String> selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onVote;
  final VoidCallback onAdd;
  /// 투표 종료하기. 약속장이 아니면 null이고 버튼을 숨긴다.
  final VoidCallback? onClose;
  final VoidCallback onRevote;
  final int pendingVoters;
  final int participantCount;

  @override
  Widget build(BuildContext context) => InfoCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final (i, row) in rows.indexed)
            _VoteRowView(
              row: row,
              first: i == 0,
              last: i == rows.length - 1,
              showResult: hasVoted,
              selected: selected.contains(row.id),
              onTap: hasVoted ? null : () => onSelect(row.id),
              fraction: participantCount == 0 ? 0 : row.votes / participantCount,
            ),
          GestureDetector(
            onTap: onAdd,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 11),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const GamIcon('ic_plus_line', size: 20),
                const SizedBox(width: 8),
                Text('항목 추가', style: GamText.caption12),
              ]),
            ),
          ),
          const SizedBox(height: 15),
          if (hasVoted) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Row(children: [
                const Icon(Icons.people_outline, size: 16, color: GamColors.text400),
                const SizedBox(width: 6),
                Text(
                  pendingVoters == 0 ? '모두 투표 완료했어요' : '$pendingVoters명이 아직 투표하지 않았어요',
                  style: GamText.meta11.copyWith(color: GamColors.text400),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              if (onClose != null) ...[
                Expanded(child: _CardButton('투표 종료하기', onTap: onClose)),
                const SizedBox(width: 10),
              ],
              Expanded(child: _CardButton('다시 투표하기', onTap: onRevote)),
            ]),
          ] else
            _CardButton('투표하기', onTap: selected.isEmpty ? null : onVote, expand: false),
        ]),
      );
}

class VoteRow {
  const VoteRow({required this.id, required this.label, required this.votes, required this.mine});

  final String id;
  final Widget label;
  final int votes;
  final bool mine;
}

class _VoteRowView extends StatelessWidget {
  const _VoteRowView({
    required this.row,
    required this.first,
    required this.last,
    required this.showResult,
    required this.selected,
    required this.onTap,
    required this.fraction,
  });

  final VoteRow row;
  final bool first;
  final bool last;
  final bool showResult;
  final bool selected;
  final VoidCallback? onTap;
  final double fraction;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.only(top: first ? 0 : 14, bottom: 14),
          decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: GamColors.cardBorder))),
          child: Column(children: [
            Row(crossAxisAlignment: showResult ? CrossAxisAlignment.end : CrossAxisAlignment.center, children: [
              if (!showResult) ...[
                _Radio(selected: selected),
                const SizedBox(width: 12),
              ] else if (row.mine) ...[
                const GamIcon('ic_check', size: 14),
                const SizedBox(width: 5),
              ],
              Expanded(child: Align(alignment: Alignment.centerLeft, child: row.label)),
              if (showResult) Text('${row.votes}명', style: GamText.regular12),
            ]),
            if (showResult) ...[
              const SizedBox(height: 12),
              _VoteBar(fraction: fraction),
            ],
          ]),
        ),
      );
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? GamColors.pink : GamColors.surfaceSoft,
          border: Border.all(color: selected ? GamColors.pinkStrong : const Color(0xFF949494), width: 1.5),
        ),
        child: selected ? const Center(child: GamIcon('ic_check', size: 12)) : null,
      );
}

/// 5px 막대. 회색 바탕 위에 득표 비율만큼 분홍.
class _VoteBar extends StatelessWidget {
  const _VoteBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          width: double.infinity,
          height: 5,
          child: Stack(children: [
            const Positioned.fill(child: ColoredBox(color: GamColors.voteTrack)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0, 1),
              child: const ColoredBox(color: GamColors.pink, child: SizedBox.expand()),
            ),
          ]),
        ),
      );
}

class _CardButton extends StatelessWidget {
  const _CardButton(this.label, {required this.onTap, this.expand = true});

  final String label;
  final VoidCallback? onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) => PillButton(
        label,
        style: PillStyle.card,
        onTap: onTap,
        expand: expand,
        textStyle: GamText.body13,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      );
}

/// 투표를 끝내고 약속장의 확정을 기다리는 카드: "확정대기 중" / 1위 후보 / "확정하기 >". (Figma 1681:16885)
/// [onConfirm]이 없으면(약속장이 아니면) 맨 아래 줄을 숨긴다.
class PendingConfirmCard extends StatelessWidget {
  const PendingConfirmCard({super.key, required this.leader, this.onConfirm});

  /// 1위 후보 내용. 아무도 안 찍었으면 null.
  final Widget? leader;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: GamColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GamColors.cardBorder),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: GamColors.cardBorder))),
            child: Row(children: [
              const GamIcon('ic_pending', size: 20),
              const SizedBox(width: 6),
              Text('확정대기 중', style: GamText.regular13),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 25),
            child: leader == null
                ? Text('아직 아무도 투표하지 않았어요', style: GamText.regular13)
                : Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: GamColors.pink, borderRadius: BorderRadius.circular(28)),
                      child: Text('1위', style: GamText.body13.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    leader!,
                  ]),
          ),
          if (onConfirm != null)
            Material(
              color: GamColors.cardButton,
              child: InkWell(
                onTap: onConfirm,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                  child: Row(children: [
                    Expanded(child: Text('확정하기', style: GamText.body13.copyWith(color: GamColors.text800))),
                    const GamIcon('ic_chevron_right_18', size: 18),
                  ]),
                ),
              ),
            ),
        ]),
      );
}

/// 확정대기 카드 가운데의 시간: "10월 6일 (화)" / "오전 2:03".
class PendingTimeLabel extends StatelessWidget {
  const PendingTimeLabel({super.key, required this.date, required this.time});

  final String date;
  final String time;

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(date, style: GamText.body14),
        ),
        const SizedBox(height: 4),
        Text(time, style: GamText.regular13),
      ]);
}

/// "투표를 종료하시겠습니까?" 확인 창. 종료를 누르면 true. (Figma 1652:28683)
Future<bool> confirmCloseVote(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialog) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 16, 14),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('투표를 종료하시겠습니까?', style: GamText.body14.copyWith(color: GamColors.text900)),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text('취소', style: GamText.body14.copyWith(color: GamColors.pickBlue)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(true),
              child: Text('종료', style: GamText.body14.copyWith(color: GamColors.pickBlue)),
            ),
          ]),
        ]),
      ),
    ),
  );
  return ok ?? false;
}
