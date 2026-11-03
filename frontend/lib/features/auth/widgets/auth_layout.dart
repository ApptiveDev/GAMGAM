import 'package:flutter/material.dart';

import '../../../core/theme/gam_colors.dart';
import '../../../core/theme/gam_text.dart';
import '../../../core/widgets/gam/gam_buttons.dart';
import '../../../core/widgets/gam/gam_icon.dart';
import '../../../core/widgets/gam/pink_frame.dart';

/// 로그인·회원가입 공통 틀. 홈처럼 로고와 도트 글씨 인사말을 위에 두고, 아래에 입력칸과 버튼을 둔다.
/// 키보드가 올라와도 하늘 배경은 그대로 두고 내용만 스크롤한다.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.greeting, required this.message, required this.fields, required this.actions});

  final String greeting;
  final String message;
  final List<Widget> fields;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return PinkFrame(
      fadeStart: 0.3,
      fadeEnd: 0.75,
      resizeToAvoidBottomInset: false,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: EdgeInsets.only(bottom: keyboard),
            child: ConstrainedBox(
              // 내용이 짧으면 버튼을 화면 아래에 붙이고, 길면 그냥 이어서 스크롤한다.
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(17, 4, 17, 0),
                    child: SizedBox(width: 40, height: 40, child: Center(child: GamIcon('logo_gamgam', size: 32))),
                  ),
                  const SizedBox(height: 31),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 23),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(greeting, style: GamText.matrix(40).copyWith(height: 1.2)),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(message, style: GamText.body16.copyWith(color: GamColors.onBlueSoft, height: 1.4)),
                      ),
                      const SizedBox(height: 44),
                      ...fields,
                    ]),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(23, 32, 23, 24),
                  child: Column(children: actions),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// 주요 버튼. 요청 중이면 진행 표시를 띄우고 누를 수 없다.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton(this.label, {super.key, required this.busy, required this.onTap});

  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => PillButton(
        label,
        expand: true,
        onTap: busy ? null : onTap,
        icon: busy ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: GamColors.text400)) : null,
      );
}

/// "아직 계정이 없나요? 가입하기" 같은 아래쪽 링크.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({super.key, required this.question, required this.action, required this.onTap});

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$question  '),
              TextSpan(text: action, style: GamText.button14.copyWith(color: GamColors.text900, decoration: TextDecoration.underline)),
            ]),
            style: GamText.body14.copyWith(color: GamColors.text600),
          ),
        ),
      );
}

/// 서버 에러처럼 칸 하나에 속하지 않는 안내.
class AuthNotice extends StatelessWidget {
  const AuthNotice(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: const Duration(milliseconds: 150),
        child: message == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(message!, textAlign: TextAlign.center, style: GamText.regular12.copyWith(color: GamColors.text800)),
              ),
      );
}
