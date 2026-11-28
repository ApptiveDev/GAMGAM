import 'package:flutter/material.dart';

import '../../../core/theme/gam_colors.dart';
import '../../../core/theme/gam_text.dart';
import '../../../core/widgets/gam/gam_icon.dart';
import '../../../data/models/vote_settings.dart';
import 'time_pick_parts.dart';

// 시간·장소 "투표로 정하기" 페이지가 함께 쓰는 부분: 항목 추가 버튼, 투표 설정 줄, 투표 진행 시간 시트.

TextStyle _medium(double size, [Color color = GamColors.text900]) => GamText.body16.copyWith(fontSize: size, color: color);

/// 흰 알약 "+ 항목 추가" 버튼.
class VoteAddButton extends StatelessWidget {
  const VoteAddButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const StadiumBorder(side: BorderSide(color: GamColors.pickCardBorder)),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: 47,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const GamIcon('ic_plus_26', size: 26),
              const SizedBox(width: 8),
              Text('항목 추가', style: _medium(14, GamColors.text500)),
            ]),
          ),
        ),
      );
}

/// 복수선택·익명투표·선택항목 추가 허용·투표 진행 시간.
/// Figma의 "선물 추가하기"는 팀 결정으로 뺐다.
class VoteSettingsSection extends StatelessWidget {
  const VoteSettingsSection({
    super.key,
    required this.settings,
    required this.duration,
    required this.onSettings,
    required this.onDuration,
  });

  final VoteSettings settings;
  final VoteDuration duration;
  final ValueChanged<VoteSettings> onSettings;
  final ValueChanged<VoteDuration> onDuration;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(children: [
          _OptionRow(label: '복수선택', on: settings.multiple, onTap: () => onSettings(settings.copyWith(multiple: !settings.multiple))),
          const SizedBox(height: 14),
          _OptionRow(label: '익명투표', on: settings.anonymous, onTap: () => onSettings(settings.copyWith(anonymous: !settings.anonymous))),
          const SizedBox(height: 14),
          _OptionRow(label: '선택항목 추가 허용', on: settings.allowAdd, onTap: () => onSettings(settings.copyWith(allowAdd: !settings.allowAdd))),
          const SizedBox(height: 14),
          _DurationRow(duration: duration, onTap: () => _pickDuration(context)),
        ]),
      );

  Future<void> _pickDuration(BuildContext context) async {
    final picked = await showModalBottomSheet<VoteDuration>(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: GamColors.sheetBarrier,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => _DurationSheet(selected: duration),
    );
    if (picked != null) onDuration(picked);
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        toggled: on,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Row(children: [
            Expanded(child: Text(label, style: _medium(14))),
            PickCheck(on: on),
          ]),
        ),
      );
}

class _DurationRow extends StatelessWidget {
  const _DurationRow({required this.duration, required this.onTap});

  final VoteDuration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(children: [
          Expanded(child: Text('투표 진행 시간', style: _medium(14))),
          Text(duration.label, style: _medium(14).copyWith(fontWeight: FontWeight.w400)),
          const SizedBox(width: 3),
          const GamIcon('ic_chevron_right_22', size: 22),
        ]),
      );
}

/// "투표 진행 시간" 목록 시트. 고르면 바로 닫힌다. (Figma 1573:23910)
class _DurationSheet extends StatelessWidget {
  const _DurationSheet({required this.selected});

  final VoteDuration selected;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHandle(),
            const SizedBox(height: 18),
            Text('투표 진행 시간', style: _medium(15)),
            const SizedBox(height: 18),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: GamColors.pickPage, borderRadius: BorderRadius.circular(19)),
                child: ListView(shrinkWrap: true, padding: EdgeInsets.zero, children: [
                  for (final (i, d) in VoteDuration.values.indexed)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(d),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 53,
                        decoration: BoxDecoration(
                          border: i == VoteDuration.values.length - 1
                              ? null
                              : const Border(bottom: BorderSide(color: GamColors.pickOptionLine)),
                        ),
                        child: Row(children: [
                          Expanded(child: Text(d.label, style: _medium(15))),
                          PickCheck(on: d == selected, size: 24),
                        ]),
                      ),
                    ),
                ]),
              ),
            ),
          ]),
        ),
      );
}
