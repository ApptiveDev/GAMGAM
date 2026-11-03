import 'package:flutter/material.dart';

import '../../../core/theme/gam_colors.dart';
import '../../../core/theme/gam_text.dart';

/// 로그인 입력칸. 이름 입력 화면처럼 테두리 없이 밑줄만 있고, 포커스되면 밑줄이 흰색이 된다.
/// [error]가 있으면 칸 아래에 작게 보여 준다.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.error,
    this.focusNode,
    this.keyboardType,
    this.autofillHints,
    this.obscure = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? error;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  /// 비밀번호 칸. 오른쪽 눈 버튼으로 가리기·보기를 바꾼다.
  final bool obscure;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late var _hidden = widget.obscure;

  static final _text = GamText.title24.copyWith(fontSize: 17, fontWeight: FontWeight.w500);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(widget.label, style: GamText.caption12.copyWith(color: GamColors.onBlueSoft)),
          ),
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            autofillHints: widget.autofillHints,
            obscureText: _hidden,
            autocorrect: !widget.obscure && widget.keyboardType != TextInputType.emailAddress,
            enableSuggestions: !widget.obscure,
            textInputAction: widget.textInputAction,
            onSubmitted: widget.onSubmitted,
            maxLength: widget.maxLength,
            cursorColor: Colors.white,
            style: _text,
            decoration: InputDecoration(
              counterText: '',
              hintText: widget.hint,
              hintStyle: _text.copyWith(color: Colors.white.withValues(alpha: 0.45)),
              contentPadding: const EdgeInsets.fromLTRB(2, 12, 2, 10),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: GamColors.nameUnderline, width: 1.3)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 1.3)),
              suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              suffixIcon: widget.obscure
                  ? IconButton(
                      tooltip: _hidden ? '비밀번호 보기' : '비밀번호 가리기',
                      onPressed: () => setState(() => _hidden = !_hidden),
                      icon: Icon(_hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: GamColors.onBlueSoft),
                    )
                  : null,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.topLeft,
            child: widget.error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
                    child: Text(widget.error!, style: GamText.regular12.copyWith(color: Colors.white)),
                  ),
          ),
        ]),
      );
}
