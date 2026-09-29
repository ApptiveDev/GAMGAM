import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_text.dart';
import '../../core/widgets/dashed_add_button.dart';
import '../../core/widgets/date_time_picker.dart';
import '../../core/widgets/layout.dart';
import '../../data/models/place.dart';
import '../../data/repositories/appointment_repository.dart';
import 'create_appointment_controller.dart';

/// 약속 만들기 2단계 — 시간·장소 정하기.
/// 투표하는 항목은 후보를 여러 개, 직접 정하는 항목은 하나만 받는다.
/// (와이어프레임엔 없는 화면. 02 템플릿과 03 방 사이를 잇는다.)
class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});

  Future<void> _submit(BuildContext context) async {
    final draft = context.read<CreateAppointmentController>();
    final appointment = await draft.submit(context.read<AppointmentRepository>());
    if (!context.mounted) return;
    // 투표가 있으면 방에서 투표부터, 없으면 바로 벌칙 정하기로. (go 라서 뒤로가면 방이 나온다)
    context.go(draft.template.hasVote ? AppRoutes.room(appointment.id) : AppRoutes.penalty(appointment.id));
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<CreateAppointmentController>();
    final t = draft.template;

    return Scaffold(
      appBar: const BackAppBar(title: '약속 만들기'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        children: [
          PageTitle(draft.name, subtitle: t.hasVote ? '투표할 후보를 ${CreateAppointmentController.minVoteOptions}개 이상 넣어주세요.' : '언제, 어디서 만날지 정해주세요.'),
          const SizedBox(height: 28),
          SectionHeader(t.votesTime ? '시간 후보' : '시간', trailing: t.votesTime ? '친구들이 중복으로 고를 수 있어요' : null),
          for (final time in draft.times)
            _OptionRow(title: DateText.dateTime(time), onRemove: () => draft.removeTime(time)),
          if (t.votesTime || draft.times.isEmpty)
            DashedAddButton(
              label: t.votesTime ? '시간 후보 추가' : '날짜·시간 선택',
              onTap: () async {
                final picked = await pickDateTime(context, initial: draft.times.lastOrNull);
                if (picked != null) draft.addTime(picked);
              },
            ),
          const SizedBox(height: 32),
          SectionHeader(t.votesPlace ? '장소 후보' : '장소', trailing: t.votesPlace ? '친구들이 한 곳을 골라요' : null),
          for (final place in draft.places) _OptionRow(title: place.name, onRemove: () => draft.removePlace(place)),
          if (t.votesPlace || draft.places.isEmpty) _PlaceInput(onAdd: draft.addPlace),
        ],
      ),
      bottomNavigationBar: BottomCta(children: [
        FilledButton(
          onPressed: draft.canSubmit ? () => _submit(context) : null,
          child: Text(draft.submitting ? '만드는 중…' : '방 만들기'),
        ),
      ]),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.title, required this.onRemove});

  final String title;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textTitle))),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted), tooltip: '삭제'),
        ]),
      );
}

/// 장소 이름 입력. 지도 검색(카카오 로컬 API 등)이 붙기 전까지는 텍스트로 받는다.
class _PlaceInput extends StatefulWidget {
  const _PlaceInput({required this.onAdd});

  final ValueChanged<Place> onAdd;

  @override
  State<_PlaceInput> createState() => _PlaceInputState();
}

class _PlaceInputState extends State<_PlaceInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    widget.onAdd(Place(name: name));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        onSubmitted: (_) => _add(),
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: '예) 연남동 소금집 델리',
          suffixIcon: TextButton(onPressed: _add, child: const Text('추가')),
        ),
      );
}
