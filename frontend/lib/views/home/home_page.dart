import 'package:flutter/material.dart';

import '../../controllers/home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.controller});

  final HomeController? controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? HomeController();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final appInfo = _controller.appInfo;

        return Scaffold(
          appBar: AppBar(title: Text(appInfo.name)),
          body: Center(
            child: Text(
              appInfo.message,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        );
      },
    );
  }
}
