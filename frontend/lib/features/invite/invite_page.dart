import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/layout.dart';
import '../../data/repositories/appointment_repository.dart';

/// 초대 링크(/invite/:code)로 들어왔을 때. 약속 미리보기 → 참여하기 → 방.
class InvitePage extends StatefulWidget {
  const InvitePage({super.key, required this.code});

  final String code;

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  bool _joining = false;

  void _close() => context.canPop() ? context.pop() : context.go(AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppointmentRepository>();
    final a = repo.findByInviteCode(widget.code);

    if (a == null) {
      return Scaffold(
        appBar: BackAppBar(onBack: _close),
        body: const Padding(padding: kPagePadding, child: PageTitle('초대 코드를 찾을 수 없어요', subtitle: '링크가 맞는지 친구에게 다시 확인해주세요.')),
      );
    }

    final host = a.participants.where((p) => p.id == a.hostId).firstOrNull;
    final alreadyIn = a.hasMember(repo.me.id);

    return Scaffold(
      appBar: BackAppBar(onBack: _close),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        children: [
          PageTitle('${host?.name ?? '친구'}님이\n약속에 초대했어요', subtitle: a.isCoordinating ? '들어가서 시간·장소 투표에 참여해보세요.' : null),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderCard, width: 1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
              const SizedBox(height: 8),
              Text(
                a.isCoordinating ? '시간·장소 조율 중' : [if (a.time != null) DateText.dateTime(a.time!), if (a.place != null) a.place!.name].join(' · '),
                style: const TextStyle(fontSize: 13, color: AppColors.textSub),
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider()),
              Row(children: [
                AvatarStack(a.participants, max: 4),
                const SizedBox(width: 10),
                Text('${a.participants.length}명 참여 중', style: const TextStyle(fontSize: 13, color: AppColors.textSub)),
              ]),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: BottomCta(children: [
        FilledButton(
          onPressed: _joining
              ? null
              : () async {
                  if (!alreadyIn) {
                    setState(() => _joining = true);
                    await repo.join(a.id);
                  }
                  if (context.mounted) context.go(AppRoutes.room(a.id));
                },
          child: Text(alreadyIn ? '방으로 가기' : '참여하기'),
        ),
      ]),
    );
  }
}
