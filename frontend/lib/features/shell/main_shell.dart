import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/gam_colors.dart';
import '../../core/theme/gam_text.dart';
import '../../core/widgets/gam/folder_thumbnail.dart';
import '../../core/widgets/gam/gam_buttons.dart';
import '../../core/widgets/gam/pink_frame.dart';
import '../../data/repositories/appointment_repository.dart';

/// 하단 탭: 홈 / 그룹 / 내정보. 바는 화면 위에 떠 있고 오른쪽 "+"는 탭마다 하는 일이 다르다.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final index = shell.currentIndex;
    return Scaffold(
      body: Stack(children: [
        shell,
        Positioned(
          left: 0,
          right: 0,
          bottom: PinkFrame.inset + 29,
          child: SafeArea(
            top: false,
            child: Center(
              child: GamBottomBar(
                currentIndex: index,
                onTab: (i) => shell.goBranch(i, initialLocation: i == index),
                onAdd: switch (index) {
                  0 => () => pickGroupThenCreate(context),
                  1 => () => context.push(AppRoutes.createGroup),
                  _ => null,
                },
                addTooltip: index == 1 ? '그룹 만들기' : '약속 만들기',
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// 홈의 "+": 약속은 그룹 안에서만 만들 수 있으므로 그룹부터 고른다.
Future<void> pickGroupThenCreate(BuildContext context) async {
  final groups = context.read<AppointmentRepository>().myGroups;
  if (groups.isEmpty) {
    context.push(AppRoutes.createGroup);
    return;
  }
  final groupId = await showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('어느 그룹에 만들까요?', style: GamText.section16.copyWith(fontSize: 18)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final g = groups[i];
                final images = sheet.read<AppointmentRepository>().appointmentsIn(g.id).map((a) => a.imageAsset).whereType<String>().toList();
                return GestureDetector(
                  onTap: () => Navigator.of(sheet).pop(g.id),
                  child: Column(children: [
                    FolderThumbnail(images: images, width: 120),
                    const SizedBox(height: 12),
                    Text(g.name, style: GamText.name15.copyWith(fontSize: 14)),
                  ]),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: PillButton(
              '새 그룹 만들기',
              style: PillStyle.light,
              textStyle: GamText.button12,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              onTap: () => Navigator.of(sheet).pop(''),
            ),
          ),
        ]),
      ),
    ),
    backgroundColor: GamColors.surface,
  );
  if (groupId == null || !context.mounted) return;
  context.push(groupId.isEmpty ? AppRoutes.createGroup : AppRoutes.createAppointment(groupId));
}
