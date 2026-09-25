import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/decision_template.dart';

class TemplateCard extends StatelessWidget {
  const TemplateCard({super.key, required this.template, required this.selected, required this.onTap});

  final DecisionTemplate template;
  final bool selected;
  final VoidCallback onTap;

  static const _icons = {
    DecisionTemplate.hostDecides: Icons.check_circle_outline,
    DecisionTemplate.voteTime: Icons.schedule,
    DecisionTemplate.votePlace: Icons.place_outlined,
    DecisionTemplate.voteBoth: Icons.how_to_vote_outlined,
  };

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.pointSoft : AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? AppColors.point : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: selected ? AppColors.point : AppColors.surfaceStrong, borderRadius: BorderRadius.circular(9)),
                child: Icon(_icons[template], size: 20, color: selected ? Colors.white : AppColors.textMuted),
              ),
              const Spacer(),
              Text(template.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
              const SizedBox(height: 3),
              Text(template.description, style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
            ]),
          ),
        ),
      );
}
