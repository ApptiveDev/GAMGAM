import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_text.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/tags.dart';
import '../../../data/models/appointment.dart';

/// 홈 상단의 "가장 가까운 약속" 큰 카드. 1초마다 카운트다운이 줄어든다.
class ClosestAppointmentCard extends StatefulWidget {
  const ClosestAppointmentCard({super.key, required this.appointment, this.onTap});

  final Appointment appointment;
  final VoidCallback? onTap;

  @override
  State<ClosestAppointmentCard> createState() => _ClosestAppointmentCardState();
}

class _ClosestAppointmentCardState extends State<ClosestAppointmentCard> {
  late final Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    final time = a.time!;
    final remaining = time.difference(_now);
    final withinDay = remaining.inHours < 24;

    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.borderCard, width: 1.5)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (a.isSharingLocation(_now)) ...[
              const Row(children: [
                PointBadge('위치 공유 중', dot: true),
                SizedBox(width: 8),
                Text('오늘 · 약속 2시간 전부터', style: TextStyle(fontSize: 12, color: AppColors.textSub)),
              ]),
              const SizedBox(height: 12),
            ],
            Text(a.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
            const SizedBox(height: 4),
            Text(
              withinDay ? DateText.countdown(remaining) : DateText.dDay(time, now: _now),
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: AppColors.point, height: 1.2, fontFeatures: [FontFeature.tabularFigures()]),
            ),
            Text(withinDay ? '약속까지 남은 시간' : DateText.dateTime(time), style: const TextStyle(fontSize: 13, color: AppColors.textSub)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider()),
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.place?.name ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textTitle)),
                  const SizedBox(height: 2),
                  Text(
                    [DateText.time(time), if (a.place?.description.isNotEmpty ?? false) a.place!.description].join(' · '),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSub),
                  ),
                ]),
              ),
              AvatarStack(a.participants),
            ]),
          ]),
        ),
      ),
    );
  }
}
