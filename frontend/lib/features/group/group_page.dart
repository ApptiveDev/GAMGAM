import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/gam_colors.dart';
import '../../core/theme/gam_text.dart';
import '../../core/widgets/gam/filter_chips.dart';
import '../../core/widgets/gam/folder_thumbnail.dart';
import '../../core/widgets/gam/gam_buttons.dart';
import '../../core/widgets/gam/gam_icon.dart';
import '../../core/widgets/gam/member_avatars.dart';
import '../../core/widgets/gam/photo_card.dart';
import '../../core/widgets/gam/pink_frame.dart';
import '../../data/models/appointment.dart';
import '../../data/models/group.dart';
import '../../data/repositories/appointment_repository.dart';

/// 폴더 클릭화면 / 그룹 초기화면. 그룹 정보와 그 안의 약속들.
class GroupPage extends StatefulWidget {
  const GroupPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  var _sort = AppointmentSort.basic;
  var _filter = AppointmentFilter.all;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppointmentRepository>();
    final group = repo.findGroup(widget.groupId);
    if (group == null) return const _MissingGroup();
    final all = repo.appointmentsIn(group.id);

    return PinkFrame(
      fadeStart: 0.1075,
      fadeEnd: 0.395,
      child: Stack(children: [
        Column(children: [
          FrameTopBar(
            leading: GamIconButton('ic_arrow_left', tooltip: '뒤로', onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.groups)),
            trailing: GamIconButton('ic_search', tooltip: '검색', onTap: () => context.push(AppRoutes.groupSearch(group.id))),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 11, 20, 140),
              children: [
                Center(child: FolderThumbnail(images: all.map((a) => a.imageAsset).whereType<String>().toList())),
                const SizedBox(height: 24),
                GroupHeader(group: group),
                const SizedBox(height: 16),
                AppointmentFilterBar(
                  sort: _sort,
                  onSort: (s) => setState(() => _sort = s),
                  filter: _filter,
                  onFilter: (f) => setState(() => _filter = f),
                  counts: filterCounts(all),
                ),
                const SizedBox(height: 26),
                AppointmentGrid(children: [
                  for (final a in applyFilter(all, _filter, _sort))
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
          child: SafeArea(child: PinkFab(tooltip: '약속 만들기', onTap: () => context.push(AppRoutes.createAppointment(group.id)))),
        ),
      ]),
    );
  }
}

/// 그룹 이름, 멤버, "활동 중 · N명 참여", 공유·더보기.
class GroupHeader extends StatelessWidget {
  const GroupHeader({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(group.name, style: GamText.title20),
        const SizedBox(height: 16),
        Row(children: [
          MemberAvatars(group.members),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _copyInvite(context, group),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: GamColors.blueChip,
                shape: BoxShape.circle,
                border: Border.all(color: GamColors.blueChipBorder),
              ),
              alignment: Alignment.center,
              child: const GamIcon('ic_plus_small', size: 17),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        MetaLine(leading: const GamIcon('ic_calendar_clock', size: 16), parts: ['활동 중', '${group.members.length}명 참여']),
        const SizedBox(height: 6),
        SizedBox(
          height: 52,
          child: Row(children: [
            GestureDetector(onTap: () => _copyInvite(context, group), child: const GamIcon('ic_share', size: 22)),
            const SizedBox(width: 26),
            const GamIcon('ic_dots_vertical', size: 22),
          ]),
        ),
      ]);

  static void _copyInvite(BuildContext context, Group group) {
    Clipboard.setData(ClipboardData(text: 'https://gamgam.app/group/${group.id}'));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('그룹 초대 링크를 복사했어요')));
  }
}

Map<AppointmentFilter, int> filterCounts(List<Appointment> all) => {
      AppointmentFilter.all: all.length,
      AppointmentFilter.upcoming: all.where((a) => !a.isCompleted).length,
      AppointmentFilter.done: all.where((a) => a.isCompleted).length,
    };

List<Appointment> applyFilter(List<Appointment> all, AppointmentFilter filter, AppointmentSort sort) {
  final shown = switch (filter) {
    AppointmentFilter.all => all.toList(),
    AppointmentFilter.upcoming => all.where((a) => !a.isCompleted).toList(),
    AppointmentFilter.done => all.where((a) => a.isCompleted).toList(),
  };
  final far = DateTime(9999);
  final old = DateTime(2000);
  switch (sort) {
    case AppointmentSort.basic:
      // 약속 전이 먼저(가까운 순), 지난 약속은 뒤로.
      shown.sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return a.isCompleted ? (b.time ?? old).compareTo(a.time ?? old) : (a.time ?? far).compareTo(b.time ?? far);
      });
    case AppointmentSort.name:
      shown.sort((a, b) => a.name.compareTo(b.name));
    case AppointmentSort.recent:
      shown.sort((a, b) => (b.createdAt ?? old).compareTo(a.createdAt ?? old));
  }
  return shown;
}

class _MissingGroup extends StatelessWidget {
  const _MissingGroup();

  @override
  Widget build(BuildContext context) => PinkFrame(
        child: Column(children: [
          FrameTopBar(leading: GamIconButton('ic_arrow_left', tooltip: '뒤로', onTap: () => context.go(AppRoutes.groups))),
          Expanded(child: Center(child: Text('그룹을 찾을 수 없어요.', style: GamText.body16))),
        ]),
      );
}
