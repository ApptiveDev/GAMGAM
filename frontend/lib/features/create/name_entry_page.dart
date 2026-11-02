import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/gam_colors.dart';
import '../../core/theme/gam_text.dart';
import '../../core/widgets/gam/gam_buttons.dart';
import '../../core/widgets/gam/pink_frame.dart';
import '../../data/repositories/appointment_repository.dart';

/// 그룹 폴더(방) 생성화면 / 그룹 → + 버튼 → 약속 생성화면.
/// 이름 하나만 받는 화면이라 약속 이름 "변경"에도 같이 쓴다.
class NameEntryPage extends StatefulWidget {
  const NameEntryPage.group({super.key})
      : _kind = _Kind.group,
        groupId = null,
        appointmentId = null;

  const NameEntryPage.appointment({super.key, required String this.groupId})
      : _kind = _Kind.appointment,
        appointmentId = null;

  const NameEntryPage.rename({super.key, required String this.appointmentId})
      : _kind = _Kind.rename,
        groupId = null;

  final _Kind _kind;
  final String? groupId;
  final String? appointmentId;

  @override
  State<NameEntryPage> createState() => _NameEntryPageState();
}

enum _Kind { group, appointment, rename }

class _NameEntryPageState extends State<NameEntryPage> {
  late final TextEditingController _name;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final current = widget._kind == _Kind.rename ? context.read<AppointmentRepository>().findById(widget.appointmentId!)?.name : null;
    _name = TextEditingController(text: current)..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _title => switch (widget._kind) {
        _Kind.group => '그룹 이름을 지정하세요',
        _Kind.appointment || _Kind.rename => '약속 이름을 지정하세요',
      };

  String get _hint => widget._kind == _Kind.group ? '앱티브' : '토요일 등산';

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final repo = context.read<AppointmentRepository>();
    switch (widget._kind) {
      case _Kind.group:
        final group = await repo.createGroup(name);
        if (mounted) context.pushReplacement(AppRoutes.group(group.id));
      case _Kind.appointment:
        final appointment = await repo.createAppointment(groupId: widget.groupId!, name: name);
        if (mounted) context.pushReplacement(AppRoutes.room(appointment.id));
      case _Kind.rename:
        await repo.rename(widget.appointmentId!, name);
        if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) => PinkFrame(
        fadeStart: 0.082,
        fadeEnd: 0.464,
        child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 19),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_title, style: GamText.title20.copyWith(color: GamColors.onBlueTitle)),
                  const SizedBox(height: 54),
                  TextField(
                    controller: _name,
                    autofocus: true,
                    maxLength: 50,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    style: GamText.title24,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: _hint,
                      hintStyle: GamText.title24.copyWith(color: Colors.white.withValues(alpha: 0.45)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: GamColors.nameUnderline, width: 1.3)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 1.3)),
                    ),
                  ),
                  const SizedBox(height: 58),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    PillButton('취소', style: PillStyle.outline, onTap: () => context.pop()),
                    const SizedBox(width: 20),
                    PillButton(
                      widget._kind == _Kind.rename ? '변경' : '만들기',
                      onTap: _name.text.trim().isEmpty || _saving ? null : _submit,
                    ),
                  ]),
                ]),
              ),
            ),
        ),
      );
}
