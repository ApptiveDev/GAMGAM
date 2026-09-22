import 'package:flutter/material.dart';

import '../views/app_shell.dart';
import '../views/appointment_create/template_page.dart';

abstract final class AppRouter {
  static const home = '/';
  static const createAppointment = '/appointments/create';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(settings: settings, builder: (_) => const AppShell());
      case createAppointment:
        return MaterialPageRoute(settings: settings, builder: (_) => const TemplatePage());
      default:
        return MaterialPageRoute(settings: settings, builder: (_) => const _UnknownRoutePage());
    }
  }
}

class _UnknownRoutePage extends StatelessWidget {
  const _UnknownRoutePage();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.home, (route) => false),
            child: const Text('Go home'),
          ),
        ),
      );
}
