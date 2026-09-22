# GAMGAM

친구들과 약속 시간과 장소를 조율하고, 약속 당일에는 위치 공유와 도착 현황을 확인하는 서비스입니다.

## 프로젝트 구성

| 영역 | 경로 | 기술 |
| --- | --- | --- |
| Frontend | `frontend/` | Flutter, Dart, Material 3 |
| Backend | `backend/` | Java 21, Spring Boot, Gradle |

## 주요 기능 기획

- 가장 가까운 약속, 예정/지난 약속 목록
- 약속 생성 템플릿: 전체 결정 / 시간 투표 / 장소 투표 / 시간·장소 투표
- 방 초대, 시간·장소 투표, 미응답자 표시 및 약속 확정
- 지각 벌칙 및 지각 기준 합의
- 방별 위치 공유 범위 설정과 당일 도착 현황 지도
- 콕 찌르기 알림, 도착 순위·지각 결과, 지난 약속 기록과 통계

## Frontend

### 실행

Flutter SDK와 Android 개발 환경을 설치한 뒤 실행합니다.

```powershell
cd frontend
flutter pub get
flutter run
```

연결된 Android 기기나 에뮬레이터가 없으면 웹에서 확인할 수 있습니다.

```powershell
flutter run -d chrome
```

### 구조

Flutter는 MVC 형태로 구성합니다.

```text
frontend/lib/
├─ data/
│  └─ mock_appointment_repository.dart  # API 연동 전 목업 데이터
├─ models/                              # 약속, 참여자, 투표, 위치 공유, 콕 찌르기, 도착 결과
├─ controllers/                         # 화면 상태·표시 데이터 제어
├─ routes/
│  └─ app_router.dart                   # 화면 경로 중앙 관리
├─ views/                               # 화면 UI
├─ app.dart                             # MaterialApp 설정
└─ main.dart                            # 앱 실행 진입점
```

현재 구현된 목업 화면은 홈, 약속 만들기 템플릿 선택, 기록 탭입니다. 목업 데이터에는 예정/지난 약속, 참여자 상태와 ETA, 시간·장소 투표, 위치 공유 단계, 벌칙, 콕 찌르기, 도착 결과가 포함됩니다.

### 라우팅

경로는 `lib/routes/app_router.dart`에서 관리합니다.

```dart
Navigator.of(context).pushNamed(AppRouter.createAppointment);
```

새 화면은 `AppRouter`에 경로 상수를 추가한 후 `onGenerateRoute`에 등록합니다.

## Backend

### 실행

```powershell
cd backend
.\gradlew.bat bootRun
```

서버 기본 주소는 `http://localhost:8080`입니다.

### 테스트

```powershell
.\gradlew.bat test
```

Spring Web MVC와 Bean Validation을 포함한 Java 21 Spring Boot 프로젝트이며, 기본 패키지는 `com.gamgam.backend`입니다.

## 개발 순서 제안

1. 목업 데이터를 실제 Spring Boot API로 교체합니다.
2. 약속 생성부터 투표·확정까지의 화면과 API를 연결합니다.
3. 인증, 초대 링크, 푸시 알림을 추가합니다.
4. 지도·위치 권한·실시간 위치 공유 기능을 구현합니다.
