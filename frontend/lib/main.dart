import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:gamgam/app.dart';

void main() {
  // 웹 주소에서 #을 빼서 http://주소/invite/코드 같은 초대 링크를 바로 열 수 있게 한다. 웹이 아니면 아무 일도 안 한다.
  usePathUrlStrategy();
  runApp(const GamgamApp());
}
