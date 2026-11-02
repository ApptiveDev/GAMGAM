import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/gam_colors.dart';
import '../../core/theme/gam_text.dart';
import '../../core/widgets/gam/folder_thumbnail.dart';
import '../../core/widgets/gam/gam_icon.dart';
import '../../core/widgets/gam/pink_frame.dart';
import '../../data/models/group.dart';
import '../../data/repositories/appointment_repository.dart';

/// 네비게이션바 → 폴더(방) 화면. 내 그룹을 폴더 모양으로 두 줄씩 보여준다.
class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final _scroll = ScrollController();

  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  /// 폴더 판이 시작하는 높이와, 판 안에서 첫 줄까지의 여백 (Figma 177, 117).
  static const _panelTop = 177.0;
  static const _panelLead = 117.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppointmentRepository>();
    final groups = repo.myGroups;
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    final fade = (1 - offset / 160).clamp(0.0, 1.0);

    return PinkFrame(
      fadeEnd: 0,
      child: Stack(children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              controller: _scroll,
              child: Padding(
                padding: const EdgeInsets.only(top: _panelTop),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight - _panelTop),
                  child: Stack(children: [
                    const Positioned.fill(top: 267, child: ColoredBox(color: GamColors.canvas)),
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 267,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00D7D9E6), GamColors.canvas],
                            stops: [85 / 267, 1],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, _panelLead, 20, 150),
                      child: _GroupGrid(groups: groups),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
        IgnorePointer(
            child: SafeArea(
          bottom: false,
          child: Opacity(
            opacity: fade,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 4, 17, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  SizedBox(width: 40, height: 40, child: Center(child: GamIcon('logo_gamgam', size: 32))),
                  GamIcon('ic_more_vertical', size: 22),
                ]),
                const SizedBox(height: 31),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 151, child: Text('My Groups', style: GamText.matrix(40).copyWith(height: 1.2))),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(_weekdays[DateTime.now().weekday - 1], style: GamText.body16.copyWith(color: GamColors.onBlueSoft)),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        )),
      ]),
    );
  }
}

class _GroupGrid extends StatelessWidget {
  const _GroupGrid({required this.groups});

  final List<Group> groups;

  @override
  Widget build(BuildContext context) {
    final rows = <List<Group>>[
      for (var i = 0; i < groups.length; i += 2) groups.sublist(i, (i + 2).clamp(0, groups.length)),
    ];
    // 폴더 두 개(149 + 20 + 149)를 한 묶음으로 화면 가운데에 둔다.
    return Center(
      child: SizedBox(
        width: 318,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const SizedBox(height: 40),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final (j, g) in row.indexed) ...[
                if (j > 0) const SizedBox(width: 20),
                _GroupTile(group: g),
              ],
            ]),
          ],
        ]),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentRepository>().appointmentsIn(group.id);
    final images = appointments.map((a) => a.imageAsset).whereType<String>().toList();
    return GestureDetector(
      onTap: () => context.push(AppRoutes.group(group.id)),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 149,
        child: Column(children: [
          FolderThumbnail(images: images, width: 149),
          const SizedBox(height: 20),
          SizedBox(
            width: 109,
            child: Text(group.name, style: GamText.name15, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(color: GamColors.countPill, borderRadius: BorderRadius.circular(22)),
            child: Text('약속 ${appointments.length}건', style: GamText.body13.copyWith(color: GamColors.text500)),
          ),
        ]),
      ),
    );
  }
}
