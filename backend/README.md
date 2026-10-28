# GAMGAM Spring Boot Backend

GAMGAM의 Java 21 기반 Spring Boot 백엔드입니다.

## 기술 구성

- Java 21
- Spring Boot
- Gradle (Kotlin DSL)
- Spring Web MVC
- Bean Validation
- Spring Data JPA
- H2 (로컬)

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

## 약속 API

### 약속 생성

`POST /api/v1/rooms/{roomId}/appointments`

방 멤버가 방 ID와 약속 이름, 템플릿, 시간·장소 정보를 전달하면 해당 방에 약속을 생성하고 공유 링크를 함께 반환합니다.
생성 성공 시 HTTP 201을 반환합니다. 로그인·참여자 연동 전이라 약속 생성자는 저장하지 않습니다.

| 필드 | 필수 | 규칙 |
| --- | --- | --- |
| `name` | 예 | 공백 불가, 최대 50자 |
| `template` | 예 | `ALL`, `TIME_ONLY`, `PLACE_ONLY`, `BOTH` |
| `candidatesTime` | 템플릿에 따라 | 미래 시각 목록 |
| `confirmedTime` | 템플릿에 따라 | 미래 시각 |
| `candidatesPlace` | 템플릿에 따라 | 장소 목록 |
| `confirmedPlace` | 템플릿에 따라 | 장소 |
| `penalty` | 아니오 | 지각 벌칙 |
| `reward` | 아니오 | 보상 |
| `locationSharing` | 아니오 | 위치 공유 시간 설정 |

`template`에 따라 시간·장소를 확정값으로 받을지, 후보 목록으로 받을지가 달라집니다.
조율 대상이면 후보를 2개 이상 보내고 확정값은 비워 둡니다. 이미 정해진 항목이면 확정값을 보내고 후보는 비워 둡니다.

| 템플릿 | 설명 | 시간 | 장소 | 초기 상태 |
| --- | --- | --- | --- | --- |
| `ALL` | 모두 정해짐 | `confirmedTime` | `confirmedPlace` | `CONFIRMED` |
| `TIME_ONLY` | 시간만 조율 | `candidatesTime` (2개 이상) | `confirmedPlace` | `COORDINATING` |
| `PLACE_ONLY` | 장소만 조율 | `confirmedTime` | `candidatesPlace` (2개 이상) | `COORDINATING` |
| `BOTH` | 시간·장소 모두 조율 | `candidatesTime` (2개 이상) | `candidatesPlace` (2개 이상) | `COORDINATING` |

**장소 (`confirmedPlace`, `candidatesPlace` 항목)**

| 필드 | 필수 | 범위 |
| --- | --- | --- |
| `name` | 예 | 공백 불가, 최대 100자 |
| `latitude` | 아니오 | -90 ~ 90 |
| `longitude` | 아니오 | -180 ~ 180 |

좌표는 선택이지만, 보내려면 `latitude`와 `longitude`를 함께 보내야 합니다.

**벌칙 (`penalty`)**

| 필드 | 필수 | 값 |
| --- | --- | --- |
| `description` | 예 | 공백 불가, 최대 100자 |
| `lateThresholdMin` | 예 | `FIVE`(5분), `TEN`(10분), `FIFTEEN`(15분) |
| `target` | 예 | `LATEST_ONLY`(가장 늦은 사람만), `ALL_LATE`(늦은 사람 전체) |

`lateThresholdMin`은 숫자가 아니라 enum 이름을 받습니다.

**보상 (`reward`)**: `description` (필수, 공백 불가, 최대 100자)

**위치 공유 (`locationSharing`)**

| 필드 | 필수 | 범위 | 기본값 |
| --- | --- | --- | --- |
| `startMinutesBefore` | 아니오 | 0 ~ 240 | 30 (약속 30분 전부터 공유 시작) |
| `maxMinutesAfter` | 아니오 | 0 ~ 240 | 30 (약속 30분 후 자동 종료) |

`locationSharing` 전체를 생략하거나 일부 필드만 보내도 빠진 값은 기본값으로 채웁니다.

### 약속 조회

`GET /api/v1/appointments/{id}`

생성 응답의 `id`로 약속 하나를 조회합니다. 해당 방의 멤버만 조회할 수 있으며 응답 형식은 생성 응답과 같습니다.

`GET /api/v1/rooms/{roomId}/appointments`로 해당 방의 약속 목록을 생성 시각 역순으로 조회합니다. 방 멤버만 사용할 수 있습니다.

### 응답

성공 응답의 `data`에는 `id`, `roomId`, `name`, `template`, `candidatesTime`, `confirmedTime`, `candidatesPlace`,
`confirmedPlace`, `penalty`, `reward`, `locationSharing`, `status`, `shareUrl`, `createdAt`이 포함됩니다.

- `id`는 UUID 문자열입니다.
- `status`는 `COORDINATING`(조율 중), `CONFIRMED`(확정), `COMPLETED`(종료) 중 하나입니다.
- `shareUrl`은 `{app.share.base-url}/appointments/{id}` 형식입니다. 로컬 기준 주소는 `http://localhost:3000`입니다.
- 시간은 요청에 어떤 오프셋을 보내든 UTC로 저장하고, 응답은 항상 KST(`+09:00`)로 반환합니다. 시각 자체는 바뀌지 않습니다.
- 사용하지 않는 항목(예: 확정된 약속의 후보 목록)은 `null` 또는 빈 배열입니다.
- 로컬에서는 H2 인메모리 DB를 사용하므로 서버를 재시작하면 데이터가 초기화됩니다.

검증 오류는 HTTP 400과 `VALIDATION_ERROR`(위반 필드는 `fieldErrors`), 읽을 수 없는 요청 본문(잘못된 enum 값, 깨진 JSON 등)은
400과 `BAD_REQUEST`, 없는 약속은 404와 `APPOINTMENT_NOT_FOUND`를 반환합니다.

백엔드 실행 후 PowerShell에서 API를 직접 확인할 수 있습니다. `confirmedTime`은 미래 시각이어야 합니다.

```powershell
$body = @'
{
  "name": "홍대 저녁 모임",
  "template": "ALL",
  "confirmedTime": "2030-01-01T19:00:00+09:00",
  "confirmedPlace": { "name": "연남동", "latitude": 37.5563, "longitude": 126.9236 },
  "penalty": { "description": "커피 사기", "lateThresholdMin": "TEN", "target": "LATEST_ONLY" },
  "reward": { "description": "커피 쿠폰" }
}
'@

$created = Invoke-RestMethod -Method Post -Uri 'http://localhost:8080/api/v1/rooms/demo-room/appointments' `
  -ContentType 'application/json; charset=utf-8' `
  -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
$created | ConvertTo-Json -Depth 5

Invoke-RestMethod -Uri "http://localhost:8080/api/v1/appointments/$($created.data.id)" | ConvertTo-Json -Depth 5
```

### 방 담당자와의 연결 범위

실제 방 생성, 초대 링크 발급/검증, 방 가입은 아직 구현하지 않았습니다. 지도용 `MockRoomRepository`를 실제 방 멤버십으로 사용하지 않습니다.
방 담당자는 `room/RoomAccess.requireMember(roomId, userId)`를 실제 방 조회로 구현하면 됩니다.
없는 방은 `ROOM_NOT_FOUND`, 비멤버는 `ROOM_ACCESS_DENIED`로 거부하는 계약입니다.
운영용 `UnavailableRoomAccess`를 실제 구현으로 교체해야 하며, 연결 전에는 HTTP 503 `ROOM_INTEGRATION_UNAVAILABLE`을 반환합니다.

로컬 프로필에서는 `LocalRoomAccess`가 **`demo-room` 하나만** 제공합니다. 멤버는 `u-yeeun`, `u-doyun`, `u-seoa`, `u-minjun`, `u-harin`입니다.
시드 약속 `demo-hongdae`(투표 가능), `demo-seongsu`(이미 확정)는 이 방에 연결됩니다.
사용자는 로컬에서만 `X-User-Id` 헤더로 선택할 수 있으며 생략 시 `u-yeeun`입니다.
운영에서는 이 헤더를 사용하지 않고 인증된 요청의 `Principal.getName()`을 사용자 ID로 사용합니다. 로그인 담당자의 사용자 ID 규격과 연결해야 합니다.

모든 약속은 방에 속하며 `roomId`는 필수입니다. 기존 `AppointmentController`와 `AppointmentService`에서 방별 생성·조회를 처리합니다.
방 없이 생성하거나 전체 방의 약속을 조회하던 `POST /api/v1/appointments`, `GET /api/v1/appointments`는 제거했습니다.
프런트엔드의 생성·목록 요청도 방 ID를 포함하는 경로로 연결해야 합니다. 방 생성·가입 API는 별도 담당 범위입니다.

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
- `application-local.yml`: 로컬 CORS 설정 및 공유 링크 설정
- `application-prod.yml`: 운영 CORS 설정 및 공유 링크 설정

운영 환경에서는 아래 환경 변수가 **모두 필요**합니다. 하나라도 없으면 애플리케이션이 시작되지 않습니다.

| 환경 변수 | 설명 | 예시 |
|---|---|---|
| `CORS_ALLOWED_ORIGINS` | 허용할 프론트엔드 도메인 (쉼표로 구분) | `https://app.example.com,https://www.example.com` |
| `SHARE_BASE_URL` | 약속 공유 링크의 기준 주소 (프론트엔드 주소 1개) | `https://app.example.com` |

```powershell
$env:CORS_ALLOWED_ORIGINS = "https://app.example.com,https://www.example.com"
$env:SHARE_BASE_URL = "https://app.example.com"
.\gradlew.bat bootRun --args="--spring.profiles.active=prod"
```
