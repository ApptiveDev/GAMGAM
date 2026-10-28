import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/gam_colors.dart';
import '../../core/theme/gam_text.dart';
import '../../core/widgets/gam/filter_chips.dart';
import '../../core/widgets/gam/gam_buttons.dart';
import '../../core/widgets/gam/gam_icon.dart';
import '../../core/widgets/gam/photo_card.dart';
import '../../core/widgets/gam/pink_frame.dart';
import '../../data/repositories/appointment_repository.dart';
import 'group_page.dart';

/// 검색 돋보기 누른화면 / 키워드 검색 화면 / 키워드 예외처리화면.
class GroupSearchPage extends StatefulWidget {
  const GroupSearchPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupSearchPage> createState() => _GroupSearchPageState();
}

class _GroupSearchPageState extends State<GroupSearchPage> {
  final _query = TextEditingController();
  var _sort = AppointmentSort.basic;
  var _filter = AppointmentFilter.all;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppointmentRepository>();
    final group = repo.findGroup(widget.groupId);
    final keyword = _query.text.trim();
    final all = repo.appointmentsIn(widget.groupId);
    final matched = keyword.isEmpty ? all : all.where((a) => a.name.contains(keyword)).toList();
    final shown = applyFilter(matched, _filter, _sort);

    return PinkFrame(
      fadeStart: 0.1075,
      fadeEnd: 0.395,
      child: Stack(children: [
        Column(children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 14, 0),
              child: Row(children: [
                GamIconButton('ic_arrow_left', tooltip: '뒤로', onTap: () => context.pop()),
                Expanded(child: _SearchField(controller: _query, hint: '${group?.name ?? '그룹'}에서 검색하기')),
              ]),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
              children: [
                AppointmentFilterBar(
                  sort: _sort,
                  onSort: (s) => setState(() => _sort = s),
                  filter: _filter,
                  onFilter: (f) => setState(() => _filter = f),
                  counts: filterCounts(matched),
                  onBlue: true,
                ),
                const SizedBox(height: 26),
                if (shown.isEmpty && keyword.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(children: [
                      Text('$keyword와(과) 일치하는 결과 없음',
                          style: GamText.title20.copyWith(color: GamColors.text800, height: 1.3), textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      Text('철자를 확인하거나 다른 키워드를 사용하세요', style: GamText.body14.copyWith(color: GamColors.text600)),
                    ]),
                  )
                else
                  AppointmentGrid(children: [
                    for (final a in shown)
                      AppointmentGridItem(
                        name: a.name,
                        image: a.imageAsset,
                        voting: a.isCoordinating,
                        onTap: () => context.push(AppRoutes.room(a.id)),
                      ),
                  ]),
              ],
            ),
          ),
        ]),
        Positioned(
          right: 28,
          bottom: 30,
          child: SafeArea(child: PinkFab(tooltip: '약속 만들기', onTap: () => context.push(AppRoutes.createAppointment(widget.groupId)))),
        ),
      ]),
    );
  }
}

/// 하늘색 알약 검색창. 입력이 있으면 오른쪽에 지우기(×).
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) => Container(
        height: 42,
        padding: const EdgeInsets.only(left: 16, right: 10),
        decoration: BoxDecoration(color: GamColors.searchField, borderRadius: BorderRadius.circular(59)),
        child: Row(children: [
          const GamIcon('ic_search_field', size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              style: GamText.body13.copyWith(color: Colors.white),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GamText.body13.copyWith(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(onTap: controller.clear, child: const GamIcon('ic_x', size: 22)),
        ]),
      );
}
