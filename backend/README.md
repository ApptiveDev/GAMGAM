# GAMGAM Spring Boot Backend

GAMGAM의 Java 21 기반 Spring Boot 백엔드입니다.

## 기술 구성

- Java 21
- Spring Boot
- Gradle (Kotlin DSL)
- Spring Web MVC
- Bean Validation

## 실행

Windows PowerShell에서 다음을 실행합니다.

```powershell
.\gradlew.bat bootRun
```

기본 주소는 `http://localhost:8080`입니다.

## 테스트

```powershell
.\gradlew.bat test
```

## 기본 API 설정

- API는 `/api/v1` 경로 아래에 추가합니다. 기본 확인 API는 `GET /api/v1/health`입니다.
- 성공 응답은 `{ "success": true, "data": ... }` 형식입니다.
- 검증 및 예외 응답은 `{ "success": false, "code": "...", "message": "...", "fieldErrors": {} }` 형식입니다.
- CORS는 `application-local.yml`에서 로컬 개발 주소를 허용합니다.

## 같은 방 참여자 지도 API

`GET /api/v1/rooms/a-hongdae/map?latitude=37.5563&longitude=126.9236`

내 위도·경도와 방 ID를 전달하면 나와 같은 방에 있는 참여자들의 위치를 반환합니다.
거리로 참여자를 제외하지 않습니다.

| 파라미터 | 필수 | 범위 |
| --- | --- | --- |
| `roomId` (경로) | 예 | 아래 목업 방 ID |
| `latitude` | 예 | -90 ~ 90 |
| `longitude` | 예 | -180 ~ 180 |

인증 연동 전 테스트 사용자 ID는 서버에서 `u-yeeun`(예은)으로 고정합니다. 요청으로 다른 사용자를 지정할 수 없습니다.
이는 실제 로그인 인증이 아니며, 실서비스에서는 인증된 사용자 ID와 실제 방 멤버십을 연결해야 합니다.

| 방 ID | 방 이름 | 참여자 |
| --- | --- | --- |
| `a-hongdae` | 홍대 저녁 모임 | 예은, 도윤, 서아, 민준, 하린 |
| `a-hiking` | 토요일 등산 | 도윤, 예은, 서아 |
| `a-donggi` | 동기 모임 | 예은, 도윤, 서아, 민준 |
| `a-seongsu` | 성수 브런치 | 서아, 예은, 도윤, 하린 |
| `a-board` | 금요일 보드게임 | 서아, 하린 (예은 미참여, 403) |

성공 응답의 `data`에는 `roomId`, `roomName`, `currentUserId`, `participants`가 포함됩니다.
각 참여자는 `id`, `name`, `latitude`, `longitude`, `distanceMeters`, `self`, `mock` 필드를 가집니다.
나는 전달받은 좌표를 그대로 사용하고 `self: true`, `mock: false`로 표시합니다.
클라이언트가 수동 테스트 좌표를 보낼 수도 있으므로 `mock: false`가 GPS 정확도를 보장하는 것은 아닙니다.
친구들은 `self: false`, `mock: true`이며 내 위치 기준 900m~5km에 목업 좌표를 생성합니다.
내 위치를 바꾸면 목업 친구 좌표도 함께 달라집니다. 위치 저장이나 실제 친구 위치 추적은 하지 않습니다.
응답은 나를 먼저, 친구들을 직선거리순으로 제공합니다.

좌표 오류는 HTTP 400과 `VALIDATION_ERROR`, 없는 방은 404와 `ROOM_NOT_FOUND`,
내가 참여하지 않은 방은 403과 `ROOM_ACCESS_DENIED`를 반환합니다.

백엔드 실행 후 PowerShell에서 API를 직접 확인할 수 있습니다.

```powershell
Invoke-RestMethod -Uri 'http://localhost:8080/api/v1/rooms/a-hongdae/map?latitude=37.5563&longitude=126.9236' | ConvertTo-Json -Depth 5
```

## 환경별 설정

- `application.yml`: 공통 설정 및 기본 프로필(`local`)
- `application-local.yml`: 로컬 CORS 설정
- `application-prod.yml`: 운영 CORS 설정

운영 환경에서는 허용할 도메인을 환경 변수로 전달합니다.

```powershell
$env:CORS_ALLOWED_ORIGINS = "https://app.example.com,https://www.example.com"
.\gradlew.bat bootRun --args="--spring.profiles.active=prod"
```
