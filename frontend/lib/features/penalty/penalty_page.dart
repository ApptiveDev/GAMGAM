import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/dashed_border.dart';
import '../../core/widgets/layout.dart';
import '../../data/repositories/appointment_repository.dart';

/// 04 · 벌칙 정하기 — 벌칙 + 지각 기준 + 참여자 동의
class PenaltyPage extends StatefulWidget {
  const PenaltyPage({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  State<PenaltyPage> createState() => _PenaltyPageState();
}

class _PenaltyPageState extends State<PenaltyPage> {
  static const presets = ['커피 사기', '밥값 더 내기', '다음 약속 총무', '벌칙 없음'];
  static const thresholds = [5, 10, 15];

  late String _penalty;
  late int _threshold;
  final List<String> _custom = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = context.read<AppointmentRepository>().findById(widget.appointmentId);
    _penalty = a?.penalty ?? presets.first;
    _threshold = a?.lateThresholdMinutes ?? 10;
    if (!presets.contains(_penalty)) _custom.add(_penalty);
  }

  Future<void> _addCustom() async {
    final text = await showDialog<String>(context: context, builder: (_) => const _CustomPenaltyDialog());
    if (text == null || text.isEmpty) return;
    setState(() {
      if (!presets.contains(text) && !_custom.contains(text)) _custom.add(text);
      _penalty = text;
    });
  }

  Future<void> _confirm() async {
    final repo = context.read<AppointmentRepository>();
    setState(() => _saving = true);
    await repo.setPenalty(widget.appointmentId, penalty: _penalty, lateThresholdMinutes: _threshold);
    await repo.confirm(widget.appointmentId);
    if (!mounted) return;
    // 방 위에 확정 화면을 올린다. 뒤로가면 확정된 방이 보인다.
    context.go(AppRoutes.confirmed(widget.appointmentId));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppointmentRepository>();
    final a = repo.findById(widget.appointmentId);
    if (a == null) return const Scaffold(body: Center(child: Text('약속을 찾을 수 없어요.')));

    // 정하는 사람(나)은 동의한 것으로 본다.
    final agreed = {...a.penaltyAgreedIds, repo.me.id};

    return Scaffold(
      appBar: const BackAppBar(title: '벌칙 정하기'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        children: [
          const PageTitle('늦으면 어떻게 할까요?', subtitle: '가볍게 웃고 넘길 정도로 정해요.'),
          const SizedBox(height: 24),
          Wrap(spacing: 8, runSpacing: 10, children: [
            for (final p in [...presets, ..._custom]) _PenaltyChip(label: p, selected: _penalty == p, onTap: () => setState(() => _penalty = p)),
            DashedBorder(
              radius: 999,
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: _addCustom,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Text('+ 직접 입력', style: TextStyle(fontSize: 14, color: AppColors.textSub)),
                ),
              ),
            ),
          ]),
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
          const SectionHeader('지각 기준'),
          const Text('약속 시간에서 이만큼 지나면 지각이에요', style: TextStyle(fontSize: 13, color: AppColors.textSub)),
          const SizedBox(height: 14),
          _ThresholdSegment(values: thresholds, selected: _threshold, onChanged: (v) => setState(() => _threshold = v)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
          SectionHeader('참여자 동의', trailing: '${agreed.length} / ${a.participants.length}'),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: agreed.length / a.participants.length,
              minHeight: 5,
              backgroundColor: AppColors.surfaceStrong,
              color: AppColors.point,
            ),
          ),
          const SizedBox(height: 12),
          for (final p in a.participants)
            Opacity(
              opacity: agreed.contains(p.id) ? 1 : 0.5,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  Avatar(p, size: 30),
                  const SizedBox(width: 12),
                  Expanded(child: Text(p.name, style: const TextStyle(fontSize: 15))),
                  Text(
                    agreed.contains(p.id) ? '좋아요' : '확인 중',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: agreed.contains(p.id) ? AppColors.textBody : AppColors.textMuted),
                  ),
                ]),
              ),
            ),
          const SizedBox(height: 8),
          const Text('벌칙은 모두가 동의하면 적용돼요.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
      bottomNavigationBar: BottomCta(children: [
        FilledButton(onPressed: _saving ? null : _confirm, child: Text(_saving ? '확정하는 중…' : '이대로 확정')),
      ]),
    );
  }
}

class _PenaltyChip extends StatelessWidget {
  const _PenaltyChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.point : AppColors.background,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.point : AppColors.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Text(label, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? Colors.white : AppColors.textBody)),
          ),
        ),
      );
}

class _ThresholdSegment extends StatelessWidget {
  const _ThresholdSegment({required this.values, required this.selected, required this.onChanged});

  final List<int> values;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          for (final v in values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: v == selected ? AppColors.background : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: v == selected ? AppColors.point : Colors.transparent, width: 1.5),
                  ),
                  child: Text(
                    '$v분',
                    style: TextStyle(fontSize: 14, fontWeight: v == selected ? FontWeight.w600 : FontWeight.w400, color: v == selected ? AppColors.point : AppColors.textSub),
                  ),
                ),
              ),
            ),
        ]),
      );
}

class _CustomPenaltyDialog extends StatefulWidget {
  const _CustomPenaltyDialog();

  @override
  State<_CustomPenaltyDialog> createState() => _CustomPenaltyDialogState();
}

class _CustomPenaltyDialogState extends State<_CustomPenaltyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('벌칙 직접 입력'),
        content: TextField(controller: _controller, autofocus: true, maxLength: 20, decoration: const InputDecoration(hintText: '예) 노래방 첫 곡 부르기')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(context).pop(_controller.text.trim()), child: const Text('추가')),
        ],
      );
}
