import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';

/// 앱 안에서 초대 코드를 직접 입력해 방에 들어가기.
Future<void> showJoinByCodeDialog(BuildContext context) async {
  final code = await showDialog<String>(context: context, builder: (_) => const _JoinByCodeDialog());
  if (code == null || code.isEmpty || !context.mounted) return;
  context.push(AppRoutes.invite(code));
}

class _JoinByCodeDialog extends StatefulWidget {
  const _JoinByCodeDialog();

  @override
  State<_JoinByCodeDialog> createState() => _JoinByCodeDialogState();
}

class _JoinByCodeDialogState extends State<_JoinByCodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim().toUpperCase());

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('초대 코드로 참여'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: '예) BOARD'),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          TextButton(onPressed: _submit, child: const Text('참여하기')),
        ],
      );
}
