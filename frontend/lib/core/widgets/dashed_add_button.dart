import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'dashed_border.dart';

/// 점선 "+ 무언가 추가하기" 버튼.
class DashedAddButton extends StatelessWidget {
  const DashedAddButton({super.key, required this.label, required this.onTap, this.height = 50});

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) => DashedBorder(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Center(child: Text('+ $label', style: const TextStyle(fontSize: 13, color: AppColors.textSub))),
          ),
        ),
      );
}
