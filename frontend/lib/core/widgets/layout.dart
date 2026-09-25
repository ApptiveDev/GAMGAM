import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 화면 좌우 여백.
const kPagePadding = EdgeInsets.symmetric(horizontal: 22);

/// 화면 제목 + 보조 설명. ("어떻게 정할까요?" / "나중에 바꿀 수 있어요.")
class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textTitle, height: 1.35)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: const TextStyle(fontSize: 14, color: AppColors.textSub)),
        ],
      ]);
}

/// 섹션 제목 + 오른쪽 보조 문구. ("시간 투표 · 중복 선택 가능")
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textTitle))),
          if (trailing != null) Text(trailing!, style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
        ]),
      );
}

/// 화면 하단에 고정되는 버튼 영역. Scaffold.bottomNavigationBar 에 넣는다.
class BottomCta extends StatelessWidget {
  const BottomCta({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      );
}

/// 뒤로가기 + 작은 제목 앱바. ("< 약속 만들기")
class BackAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BackAppBar({super.key, this.title, this.onBack, this.actions});

  final String? title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textSub),
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: title == null ? null : Text(title!),
        actions: actions,
      );
}
