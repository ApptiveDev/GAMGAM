import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/layout.dart';
import '../../data/models/decision_template.dart';
import 'create_appointment_controller.dart';
import 'widgets/template_card.dart';

/// 02 · 약속 만들기 — 템플릿 선택 + 이름
class TemplatePage extends StatefulWidget {
  const TemplatePage({super.key});

  @override
  State<TemplatePage> createState() => _TemplatePageState();
}

class _TemplatePageState extends State<TemplatePage> {
  static const _nameSuggestions = ['저녁 모임', '주말 나들이', '스터디'];

  late final _nameController = TextEditingController(text: context.read<CreateAppointmentController>().name);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _fillName(String name) {
    _nameController.text = name;
    context.read<CreateAppointmentController>().setName(name);
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<CreateAppointmentController>();

    return Scaffold(
      appBar: const BackAppBar(title: '약속 만들기'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        children: [
          const PageTitle('어떻게 정할까요?', subtitle: '나중에 바꿀 수 있어요.'),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final t in DecisionTemplate.values)
                TemplateCard(template: t, selected: draft.template == t, onTap: () => draft.selectTemplate(t)),
            ],
          ),
          const SizedBox(height: 28),
          const Text('약속 이름', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            onChanged: draft.setName,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: '예) 홍대 저녁 모임'),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final s in _nameSuggestions)
              ActionChip(
                label: Text(s),
                onPressed: () => _fillName(s),
                shape: const StadiumBorder(side: BorderSide(color: AppColors.border)),
                backgroundColor: AppColors.background,
                labelStyle: const TextStyle(color: AppColors.textSub, fontSize: 13),
              ),
          ]),
        ],
      ),
      bottomNavigationBar: BottomCta(children: [
        FilledButton(
          onPressed: draft.canGoToDetails ? () => context.push(AppRoutes.createDetails) : null,
          child: const Text('다음'),
        ),
      ]),
    );
  }
}
