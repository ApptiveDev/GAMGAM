import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 웹(설치 전)에서 "앱 설치하러 가기". 기기에 맞는 스토어로 보낸다.
abstract final class AppInstall {
  // TODO: 스토어에 출시되면 주소를 넣고 url_launcher로 연다.
  static const playStoreUrl = '';
  static const appStoreUrl = '';

  static String get storeUrl => switch (defaultTargetPlatform) {
        TargetPlatform.android => playStoreUrl,
        TargetPlatform.iOS => appStoreUrl,
        _ => '',
      };

  static Future<void> open(BuildContext context) async {
    if (storeUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('아직 스토어에 출시 전이에요. 조금만 기다려주세요')));
    }
  }
}
