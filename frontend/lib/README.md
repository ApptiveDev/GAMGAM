# lib 구조

```
lib/
├─ main.dart / app.dart        앱 진입점. 테마·라우터·Repository를 여기서 꽂는다
├─ core/                       기능과 상관없이 어디서나 쓰는 것
│  ├─ router/                  app_routes.dart(경로 상수) · app_router.dart(go_router 설정)
│  ├─ theme/                   app_colors.dart(디자인 토큰) · app_theme.dart
│  ├─ widgets/                 Avatar, DashedBorder, BottomCta, PageTitle, 태그/뱃지 …
│  └─ utils/                   date_text.dart (한국어 날짜 문구, D-day, 카운트다운)
├─ data/
│  ├─ models/                  Appointment, Participant, Place, VoteOption, DecisionTemplate
│  ├─ repositories/            AppointmentRepository(인터페이스) + Mock 구현
│  └─ mock/                    와이어프레임 목업 데이터
└─ features/                   화면 = 폴더 하나. 그 화면에서만 쓰는 위젯은 features/<화면>/widgets/
   ├─ shell/                   하단 탭 (홈 / 기록 / 내정보)
   ├─ home/                    01 홈
   ├─ appointment_create/      02 템플릿 + 시간·장소 입력 (+ draft 컨트롤러)
   ├─ room/                    03 방 — 초대 링크, 시간·장소 투표
   ├─ penalty/                 04 벌칙 정하기
   ├─ confirmed/               05 확정 완료 + 공유
   ├─ invite/                  초대 링크(/invite/:code)로 입장
   ├─ records/ · profile/      탭
   └─ location_setting/ · live_map/ · arrival/   핵심기능 #2 자리 (06~09)
```

## 라우트

| 경로 | 화면 | 비고 |
|---|---|---|
| `/` · `/records` · `/profile` | 하단 탭 | `StatefulShellRoute` — 탭마다 스택 유지 |
| `/appointments/new` | 02 템플릿 + 이름 | 생성 플로우는 `ShellRoute`로 묶여 draft를 공유 |
| `/appointments/new/details` | 시간·장소 입력 | "방 만들기" → 투표 있으면 방, 없으면 벌칙으로 |
| `/appointments/:id` | 03 방 | |
| `/appointments/:id/penalty` | 04 벌칙 | 방장만 진입 ("확정하기") |
| `/appointments/:id/confirmed` | 05 확정 | |
| `/appointments/:id/location-setting` · `live` · `arrival` | 06 · 07~08 · 09 | 핵심기능 #2, 지금은 Placeholder |
| `/invite/:code` | 초대 입장 | 웹 딥링크 겸용. 목업 코드: `BOARD` |

## 규칙

- **경로 문자열 직접 쓰지 않기** → `AppRoutes.room(id)` 처럼 `app_routes.dart` 사용.
- **색·간격 하드코딩 대신 `AppColors`** 사용. 포인트 컬러(`AppColors.point`)는 CTA·카운트다운·선택 상태에만.
- **화면은 `AppointmentRepository`만 안다.** `context.watch<AppointmentRepository>()`로 읽고, 쓰기는 `context.read`로.
  백엔드 API가 나오면 `ApiAppointmentRepository`를 만들어 `app.dart`에서 교체하면 된다.
- 여러 화면에 걸친 입력값은 플로우 단위 컨트롤러(`ChangeNotifier`)로. 예: `CreateAppointmentController`.
- 문구는 친근한 "~해요"체. 늦는 사람을 비난하는 표현은 쓰지 않는다.
