import 'package:flutter/foundation.dart';

import '../models/app_info.dart';

class HomeController extends ChangeNotifier {
  HomeController({AppInfo? appInfo})
      : _appInfo = appInfo ??
            const AppInfo(
              name: 'GAMGAM',
              message: 'GAMGAM Flutter app is ready.',
            );

  final AppInfo _appInfo;

  AppInfo get appInfo => _appInfo;
}
