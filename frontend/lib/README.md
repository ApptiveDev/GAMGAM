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
│  ├─ models/                  Appointment, Participant, Place, VoteOption, DecisionTemplate,
│  │                           GeoPoint, live_location.dart(공유 범위·당일 현황·콕 찌르기)
│  ├─ repositories/            AppointmentRepository · LiveLocationRepository(인터페이스) + Mock 구현
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
   ├─ location_setting/        06 위치 공유 설정 (방별 공개 범위)
   ├─ live_map/                07 당일 지도 + 08 콕 찌르기. 지도 SDK는 widgets/live_map_view.dart에서만 쓴다
   └─ arrival/                 09 도착 완료 (시상대 · 지각 · 정산)
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
| `/appointments/:id/location-setting` | 06 위치 공유 설정 | `?next=live`면 고른 뒤 당일 지도로. 내정보 탭에서 들어오면 돌아간다 |
| `/appointments/:id/live` | 07 당일 지도 · 08 콕 찌르기 | `openLiveMap()`으로 연다 — 공개 범위를 아직 안 골랐으면 06을 먼저 거친다 |
| `/appointments/:id/arrival` | 09 도착 완료 | 모두 도착하면 지도에서 자동으로 넘어온다 |
| `/invite/:code` | 초대 입장 | 웹 딥링크 겸용. 목업 코드: `BOARD` |

## 규칙

- **경로 문자열 직접 쓰지 않기** → `AppRoutes.room(id)` 처럼 `app_routes.dart` 사용.
- **색·간격 하드코딩 대신 `AppColors`** 사용. 포인트 컬러(`AppColors.point`)는 CTA·카운트다운·선택 상태에만.
- **화면은 `AppointmentRepository`만 안다.** `context.watch<AppointmentRepository>()`로 읽고, 쓰기는 `context.read`로.
  백엔드 API가 나오면 `ApiAppointmentRepository`를 만들어 `app.dart`에서 교체하면 된다.
- **당일 위치는 `LiveLocationRepository`만 안다.** 목업은 1초 = 1분으로 흘러가는 시뮬레이션(약속 42분 전 → 약 1분 뒤 전원 도착).
  위치 저장·실시간 구독(WebSocket)·푸시가 나오면 구현체만 교체한다. 콕 찌르기 쿨다운(5분)은 실제 시간으로 센다.
- **지도는 `LiveMapView` 안에서만.** 지금은 flutter_map + OpenStreetMap 공개 타일(개발용). 카카오맵 등으로 바꿀 때 이 파일만 고친다.
- **위치는 약속 2시간 전부터 도착할 때까지만** 공유된다. 이 규칙을 문구로 반복해서 안심시킨다.
- 여러 화면에 걸친 입력값은 플로우 단위 컨트롤러(`ChangeNotifier`)로. 예: `CreateAppointmentController`.
- 문구는 친근한 "~해요"체. 늦는 사람을 비난하는 표현은 쓰지 않는다.
