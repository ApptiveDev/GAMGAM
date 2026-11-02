import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../data/api/auth_controller.dart';
import 'auth_messages.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_layout.dart';

/// 로그인. 성공하면 라우터가 알아서 홈(또는 [from]의 초대 화면)으로 보낸다.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.from});

  /// 로그인한 뒤 돌아갈 주소. 초대 링크로 들어왔을 때만 있다.
  final String? from;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  var _busy = false;

  /// 한 번 제출해 본 뒤부터 칸 아래 에러를 보여 준다.
  var _tried = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    for (final c in [_email, _password]) {
      c.addListener(() => setState(() => _serverError = null));
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? get _emailError => _tried ? AuthRules.email(_email.text) : null;
  String? get _passwordError => _tried && _password.text.isEmpty ? '비밀번호를 입력해 주세요' : null;
  bool get _filled => _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _tried = true);
    if (AuthRules.email(_email.text) != null || _password.text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await context.read<AuthController>().login(_email.text.trim(), _password.text);
    } catch (e) {
      if (mounted) setState(() => _serverError = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AutofillGroup(
        child: AuthLayout(
          greeting: 'Hello,\nthere.',
          message: '다시 만나서 반가워요.\n이메일로 로그인해 주세요.',
          fields: [
            AuthField(
              controller: _email,
              label: '이메일',
              hint: 'gamgam@email.com',
              error: _emailError,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email, AutofillHints.username],
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            AuthField(
              controller: _password,
              focusNode: _passwordFocus,
              label: '비밀번호',
              hint: '비밀번호',
              error: _passwordError,
              obscure: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
          actions: [
            AuthNotice(_serverError),
            AuthSubmitButton('로그인', busy: _busy, onTap: _filled ? _submit : null),
            const SizedBox(height: 8),
            AuthSwitchLink(
              question: '아직 계정이 없나요?',
              action: '가입하기',
              onTap: () => context.go(AppRoutes.signupFrom(widget.from)),
            ),
          ],
        ),
      );
}
