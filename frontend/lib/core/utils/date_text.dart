/// 화면에 쓰는 한국어 날짜·시간 문구.
abstract final class DateText {
  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  /// 오후 7:00
  static String time(DateTime date) {
    final period = date.hour < 12 ? '오전' : '오후';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$period $hour:${date.minute.toString().padLeft(2, '0')}';
  }

  /// 9월 24일 (목)
  static String date(DateTime date) => '${date.month}월 ${date.day}일 (${_weekdays[date.weekday - 1]})';

  /// 9월 24일 (목) 오후 7:00
  static String dateTime(DateTime date) => '${DateText.date(date)} ${time(date)}';

  /// 오늘 기준 남은 날짜. 오늘이면 D-day.
  static String dDay(DateTime date, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final days = _dateOnly(date).difference(today).inDays;
    if (days == 0) return 'D-day';
    return days > 0 ? 'D-$days' : 'D+${-days}';
  }

  /// 1:42:08
  static String countdown(Duration remaining) {
    if (remaining.isNegative) return '0:00:00';
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
}
