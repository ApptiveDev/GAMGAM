# GAMGAM Flutter Frontend

GAMGAM의 모바일/웹 프론트엔드입니다. 폴더 구조와 라우트는 [lib/README.md](lib/README.md)를 보세요.

## 실행

```bash
flutter pub get
flutter run            # 연결된 기기 / 에뮬레이터
flutter run -d chrome  # 웹
flutter test
```

지금은 백엔드 없이 목업 데이터(`lib/data/mock/`)로 동작합니다. 앱을 다시 켜면 초기화됩니다.

## 참고

- 프로젝트 경로에 한글이 있으면 `flutter analyze`(Dart 분석 서버)가 `FormatException`으로 죽습니다.
  분석이 필요하면 영문 경로에 클론해서 돌리세요. `flutter run` / `flutter test`는 영향 없습니다.
