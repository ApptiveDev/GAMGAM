import 'package:flutter/material.dart';

/// 날짜 → 시간 순서로 고르는 기본 피커. 취소하면 null.
Future<DateTime?> pickDateTime(BuildContext context, {DateTime? initial}) async {
  final now = DateTime.now();
  final base = initial ?? DateTime(now.year, now.month, now.day + 1, 19);
  final date = await showDatePicker(
    context: context,
    initialDate: base,
    firstDate: DateTime(now.year, now.month, now.day),
    lastDate: now.add(const Duration(days: 365)),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(base));
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
