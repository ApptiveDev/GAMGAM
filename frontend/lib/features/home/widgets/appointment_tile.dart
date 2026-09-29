import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_text.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../../core/widgets/tags.dart';
import '../../../data/models/appointment.dart';

/// 예정된 약속 한 줄. 조율 중이면 미투표 인원을 보여준다.
class AppointmentTile extends StatelessWidget {
  const AppointmentTile({super.key, required this.appointment, this.onTap});

  final Appointment appointment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final time = a.time;
    final subtitle = a.isCoordinating
        ? (a.pendingVoterCount > 0 ? '${a.pendingVoterCount}명이 아직 투표하지 않았어요' : '모두 투표했어요')
        : [if (time != null) '${DateText.date(time)} · ${DateText.time(time)}', if (a.place != null) a.place!.name].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const ImagePlaceholder(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(a.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textTitle))),
                    if (a.isCoordinating) ...[const SizedBox(width: 6), const OutlineTag('조율 중')],
                  ]),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
                ]),
              ),
              if (a.isConfirmed && time != null)
                Text(DateText.dDay(time), style: const TextStyle(fontSize: 12, color: AppColors.textMuted))
              else
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 지난 약속 한 줄. 점선 + 흐리게.
class PastAppointmentTile extends StatelessWidget {
  const PastAppointmentTile({super.key, required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final info = [
      if (a.time != null) '${a.time!.month}월 ${a.time!.day}일',
      '${a.participants.length}명',
      if (a.lateCount > 0) '지각 ${a.lateCount}명',
    ].join(' · ');

    return Opacity(
      opacity: 0.75,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DashedBorder(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.name, style: const TextStyle(fontSize: 15, color: AppColors.textBody)),
                const SizedBox(height: 3),
                Text(info, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
