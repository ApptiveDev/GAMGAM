import 'package:flutter/material.dart';

import '../../theme/gam_colors.dart';
import '../../theme/gam_text.dart';
import 'gam_icon.dart';

/// 그룹 상세의 "기본순 ⌄ | 전체 7 | 약속 전 5 | 약속 완료 2" 줄.
/// 검색 화면에서는 파란 배경 위라 [onBlue]로 색을 바꾼다.
class AppointmentFilterBar extends StatelessWidget {
  const AppointmentFilterBar({
    super.key,
    required this.sort,
    required this.onSort,
    required this.filter,
    required this.onFilter,
    required this.counts,
    this.onBlue = false,
  });

  final AppointmentSort sort;
  final ValueChanged<AppointmentSort> onSort;
  final AppointmentFilter filter;
  final ValueChanged<AppointmentFilter> onFilter;
  final Map<AppointmentFilter, int> counts;
  final bool onBlue;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(children: [
          PopupMenuButton<AppointmentSort>(
            initialValue: sort,
            onSelected: onSort,
            color: GamColors.surface,
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            itemBuilder: (_) => [
              for (final s in AppointmentSort.values) PopupMenuItem(value: s, child: Text(s.label, style: GamText.body13)),
            ],
            child: Container(
              height: 33,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: onBlue ? GamColors.searchSortBorder : GamColors.sortBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(sort.label, style: GamText.chip11),
                const SizedBox(width: 5),
                GamIcon(onBlue ? 'ic_chevron_down_blue' : 'ic_chevron_down', size: 13),
              ]),
            ),
          ),
          for (final f in AppointmentFilter.values) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onFilter(f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: f == filter ? GamColors.pink : (onBlue ? GamColors.searchChip : GamColors.chipIdle),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  '${f.label}  ${counts[f] ?? 0}',
                  style: GamText.chip11.copyWith(
                    color: f == filter ? GamColors.text900 : (onBlue ? GamColors.searchChipText : GamColors.text400),
                  ),
                ),
              ),
            ),
          ],
        ]),
      );
}

enum AppointmentSort {
  basic('기본순'),
  name('이름순'),
  recent('최근 만든 순');

  const AppointmentSort(this.label);
  final String label;
}

enum AppointmentFilter {
  all('전체'),
  upcoming('약속 전'),
  done('약속 완료');

  const AppointmentFilter(this.label);
  final String label;
}
