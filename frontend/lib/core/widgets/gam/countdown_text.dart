import 'dart:async';

import 'package:flutter/material.dart';

import '../../utils/date_text.dart';

/// [target]까지 남은 시간을 1초마다 다시 그린다. "1:42:08", 하루가 넘으면 "D-6".
class CountdownText extends StatefulWidget {
  const CountdownText({super.key, required this.target, required this.style});

  final DateTime target;
  final TextStyle style;

  /// 남은 시간 문구. 24시간 미만은 시:분:초, 그 이상은 D-day.
  static String format(DateTime target, DateTime now) {
    final remaining = target.difference(now);
    if (remaining.inHours >= 24) return DateText.dDay(target, now: now);
    return DateText.countdown(remaining);
  }

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(CountdownText.format(widget.target, DateTime.now()), style: widget.style, maxLines: 1),
      );
}
