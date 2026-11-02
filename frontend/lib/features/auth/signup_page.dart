import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../data/api/api_client.dart';
import '../../data/api/auth_controller.dart';
import 'auth_messages.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_layout.dart';

/// 회원가입. 가입하면 같은 정보로 바로 로그인하고, 라우터가 홈으로 보낸다.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key, this.from});

  /// 로그인한 뒤 돌아갈 주소. 초대 링크로 들어왔을 때만 있다.
  final String? from;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  var _busy = false;

  /// 한 번 제출해 본 뒤부터 칸 아래 에러를 보여 준다.
  var _tried = false;
  String? _serverError;

  /// 이미 가입된 이메일. 이메일 칸 아래에 보여 주고, 이메일을 고치면 지운다.
  String? _takenEmail;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _email, _password]) {
      c.addListener(() => setState(() => _serverError = null));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _password]) {
      c.dispose();
    }
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? get _nameError => _tried ? AuthRules.name(_name.text) : null;
  String? get _emailError {
    if (_takenEmail != null && _takenEmail == _email.text.trim()) return authErrorMessage(const ApiException(409, null, null));
    return _tried ? AuthRules.email(_email.text) : null;
  }

  String? get _passwordError => _tried ? AuthRules.password(_password.text) : null;
  bool get _filled => _name.text.trim().isNotEmpty && _email.text.trim().isNotEmpty && _password.text.isNotEmpty;
  bool get _valid => AuthRules.name(_name.text) == null && AuthRules.email(_email.text) == null && AuthRules.password(_password.text) == null;

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _tried = true);
    if (!_valid) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final email = _email.text.trim();
    try {
      await context.read<AuthController>().signup(email: email, password: _password.text, name: _name.text.trim());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.statusCode == 409) {
          _takenEmail = email;
        } else {
          _serverError = authErrorMessage(e);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _serverError = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AutofillGroup(
        child: AuthLayout(
          greeting: 'Nice to\nmeet you.',
          message: '감감에서 쓸 이름과\n로그인할 이메일을 알려 주세요.',
          fields: [
            AuthField(
              controller: _name,
              label: '이름',
              hint: '친구들이 부를 이름',
              error: _nameError,
              maxLength: 30,
              autofillHints: const [AutofillHints.nickname],
              onSubmitted: (_) => _emailFocus.requestFocus(),
            ),
            AuthField(
              controller: _email,
              focusNode: _emailFocus,
              label: '이메일',
              hint: 'gamgam@email.com',
              error: _emailError,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            AuthField(
              controller: _password,
              focusNode: _passwordFocus,
              label: '비밀번호',
              hint: '8자 이상',
              error: _passwordError,
              obscure: true,
              maxLength: 64,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
          actions: [
            AuthNotice(_serverError),
            AuthSubmitButton('가입하기', busy: _busy, onTap: _filled ? _submit : null),
            const SizedBox(height: 8),
            AuthSwitchLink(
              question: '이미 계정이 있나요?',
              action: '로그인',
              onTap: () => context.go(AppRoutes.loginFrom(widget.from)),
            ),
          ],
        ),
      );
}
