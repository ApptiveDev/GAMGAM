# 화면 연동 API

첨부된 GAMGAM 화면(홈, 모임 폴더, 약속 상세, 시간/장소 투표, 추천 장소,
지도, 도착 현황, 카드 꾸미기)에 대한 계약입니다. 기존 로그인·생성·확정 API는
[README.md](README.md)에 있으며 이 문서는 추가 동작과 화면 연결 순서를 설명합니다.

## 공통

- 기본 경로: `/api/v1`. 로그인/가입/health 외에는 JWT Bearer 토큰이 필요합니다.
- 성공: `{"success":true,"data":...}`. 오류: `{"success":false,"code":"...","message":"...","fieldErrors":{}}`.
- enum은 대문자입니다. `TIME`, `PLACE`, `FRIENDS` 등.
- 후보와 참여자는 화면 인덱스 대신 응답의 UUID를 사용합니다.
- 날짜 요청은 오프셋을 포함한 ISO 8601, 응답 시간은 KST(+09:00) 또는 UTC Instant입니다.
- UI의 달력 펼치기, 시간 휠, 바텀시트, 메뉴 표시, 선택 전 임시 상태는 프론트가 관리합니다.
- API 명세: 서버 실행 후 `/v3/api-docs`, Swagger UI `/swagger-ui/index.html`.

## 홈과 모임 폴더

| Method | 경로 | 용도 |
| --- | --- | --- |
| GET | `/home` | 내 방들의 약속 카드, 다음 약속, 카운트다운 |
| GET | `/rooms/{roomId}/dashboard` | 해당 모임의 약속 카드와 상태별 개수 |
| PATCH | `/rooms/{roomId}` | 방 소유자가 이름/대표 이미지 변경 |
| GET | `/rooms/{roomId}/members` | 멤버 ID, 이름, 소유자 여부, 아바타 |
| GET | `/rooms/{roomId}/invite` | 방 멤버가 초대 코드/링크 조회(최초 발급 포함) |
| POST | `/rooms/{roomId}/invite/rotate` | 방 소유자가 기존 코드를 폐기하고 새 코드 발급 |
| POST | `/rooms/join` | `{"inviteCode":"UUID"}`로 방 가입, 재요청은 중복 가입하지 않음 |

목록 쿼리: `filter=ALL|UPCOMING|COMPLETED`, `sort=NEWEST|TIME|NAME`,
`query=검색어`, `page=0`, `size=20`(1~100).

`UPCOMING`은 완료 전 약속(조율 중 포함), `COMPLETED`는 명시적으로 완료한 약속입니다.
다음 약속은 미래의 확정된 약속 중 가장 가까운 약속입니다.
응답은 `serverTime`, `nextAppointment`, `secondsUntilNext`, `totalCount`,
`upcomingCount`, `completedCount`, `page`, `size`, `items`입니다.
`totalCount`는 검색/필터 적용 개수, 나머지 두 개수는 모임 또는 내 전체 목록 기준입니다.

방 변경 본문: `{"name":"앱티브","coverImageUrl":"https://..."}`.
`coverImageUrl` 생략은 기존 값을 유지합니다.
초대 링크의 웹/앱 라우트는 프론트에서 구현하고, 코드로 가입 API를 호출합니다.

## 약속 꾸미기와 이미지

| Method | 경로 | 용도 |
| --- | --- | --- |
| POST | `/media` | multipart `file`, PNG/JPEG 최대 5MB 업로드, 201 |
| GET | `/media/{id}` | 인증된 이미지 다운로드, 바이너리 응답 |
| PUT | `/appointments/{id}/appearance` | 약속 호스트가 커버/카드 문구/스타일 교체 |
| PATCH | `/auth/me` | 기존 이름 변경에 선택적인 `avatarUrl` 추가 |

업로드 응답: `id`, `url`, `contentType`, `size`. `url`을 커버 또는 아바타 필드에 저장합니다.
이미지는 DB에 저장되며, 파일 내용을 디코딩/재인코딩하여 검증합니다.
최대 한 변 8192px, 총 1600만 픽셀입니다. 업로더 또는 이미지가 실제로 연결된 약속/방을
조회할 수 있는 사용자만 다운로드할 수 있습니다. 이미지 GET에도 Authorization 헤더가 필요합니다.
커버/아바타/장소 사진을 연결할 때도 기존 이미지 접근 권한을 검사하므로, 알게 된 URL을
다른 약속에 붙이는 방법으로 비공개 이미지에 접근할 수 없습니다.

```json
{
  "coverImageUrl": "https://api.example.com/api/v1/media/UUID",
  "cardText": "토요일에 만나요!",
  "cardStyle": "LETTER"
}
```

appearance는 전체 교체이므로 null/생략으로 해당 값을 지울 수 있습니다.
`cardStyle`은 최대 30자의 프론트 스타일 식별자, `cardText`는 최대 1000자입니다.
약속 상세/목록에도 이 필드들을 반환합니다. 프로필 변경은 기존 계약대로 `name`이 필수이며,
`avatarUrl`을 생략하면 기존 아바타를 유지합니다. 업로드 기능을 쓰려면 `MEDIA_BASE_URL`을
클라이언트에서 접근할 수 있는 API 서버 주소로 설정합니다.

## 시간·장소 투표 폼

1. 기존 `POST /rooms/{roomId}/appointments`에 이름을 보내 빈 약속을 생성합니다.
2. 후보를 추가합니다. 시간은 `/appointments/{id}/time-candidates`, 장소는 `place-candidates`입니다.
3. 폼의 체크 버튼을 누르면 해당 종류의 `/appointments/{id}/polls/{type}`을 PUT합니다.
4. 상세 화면은 `GET /appointments/{id}/votes`의 후보·내 선택·득표 수·poll 설정을 사용합니다.

| Method | 경로 (`/appointments/{id}` 뒤) | 용도 |
| --- | --- | --- |
| PUT | `/polls/{type}` | 투표 설정 저장 및 마감시간 시작 |
| POST | `/polls/{type}/close` | 호스트의 해당 투표 조기 종료 |
| POST | `/polls/{type}/gift/draw` | 종료/확정 후 선물 당첨자 결정 |
| PUT | `/time-candidates/{candidateId}` | 호스트가 후보 시간 수정 |
| DELETE | `/time-candidates/{candidateId}` | 호스트가 시간 후보 삭제 |
| PUT | `/place-candidates/{candidateId}` | 호스트가 장소 후보 수정 |
| DELETE | `/place-candidates/{candidateId}` | 호스트가 장소 후보 삭제 |

설정 요청:

```json
{
  "multipleSelection": false,
  "anonymous": false,
  "allowAddingOptions": true,
  "durationMinutes": 30,
  "giftDescription": "커피 한 잔",
  "giftMethod": "RANDOM",
  "winnerCount": 1
}
```

- 필수: 세 boolean 및 `durationMinutes`.
- 기간: 30, 60, 240, 480, 1440, 4320, 10080, 20160분.
- 선물이 없으면 마지막 세 필드는 모두 생략합니다. 선물 방식은 `RANDOM` 또는 `FIRST_COME`.
- 기존 데이터/API와의 호환을 위해 설정이 없는 투표는 기존처럼 복수선택/후보추가 허용,
  비익명, 기한 없음입니다. 새 UI에서는 표시한 기본값(false/false/true/30)을 명시적으로 PUT해야 합니다.
- 시간과 장소의 마감/설정은 독립적입니다. 설정 저장 이후 `endsAt`이 지나면 읽기에서도 `CLOSED`가
  반환되고 쓰기가 거절됩니다. 별도 스케줄러 지연 없이 요청 시각 기준으로 적용됩니다.
- 표가 있으면 설정 변경은 409 `POLL_HAS_VOTES`. 종료된 투표는 설정 변경/후보 변경/재투표 불가입니다.
- `다시 투표하기`는 열린 투표에서 기존 PUT `/votes/time` 또는 `/votes/place`로 내 선택을 교체합니다.
  빈 `candidateIds`는 해당 종류 선택을 취소합니다. 종료 후 새 라운드를 여는 기능은 아닙니다.
- 익명일 때 옵션의 `voterIds`와 약속 상세/목록의 `timeVotes` 또는 `placeVotes`를 숨깁니다.
  `voteCount`와 `votedByMe`는 유지합니다. 참여자 목록은 모임 참여 표시를 위해 유지합니다.
- 수정/삭제는 호스트만 가능합니다. 실제로 수정한 후보에 붙은 표만 취소하고 다른 후보의 표는 유지합니다.
  마지막 표를 잃은 일반 참여자는 기존 참여 정책에 따라 제거됩니다. 같은 값으로 저장하면 표를 유지합니다.
- 참여자의 후보 추가는 `allowAddingOptions`가 true일 때만 가능합니다. 호스트도 마감 뒤에는 추가할 수 없습니다.
- 선물 추첨은 현재 해당 종류에 투표한 사용자별 한 번씩 추첨합니다. 선착순은 현재 남아 있는 첫 표의
  등록 순서입니다. 취소/선택 변경은 선착순 우선순위를 잃지만, 동일한 선택을 PUT 재전송하면 유지합니다.
  당첨자 수가 유권자 수보다 많으면 전원 선정합니다.
  재요청은 저장된 당첨자를 반환합니다. 실제 상품 결제/발송은 포함하지 않습니다.

투표 응답에 `timePoll`, `placePoll`이 추가됩니다:
`multipleSelection`, `anonymous`, `allowAddingOptions`, `state`, `startedAt`, `endsAt`,
`giftDescription`, `giftMethod`, `winnerCount`, `winnerIds`.
상태는 `EMPTY`, `OPEN`, `CLOSED`, `CONFIRMED`입니다.

## 투표 종료 및 확정

종료는 후보 결과를 고정하고, 확정은 호스트가 기존 `/confirm/time`, `/confirm/place`에
`{"candidateId":"UUID"}`를 보내 수행합니다. 시간·장소가 모두 정해지면 `CONFIRMED`입니다.
동점이면 UI에서 호스트에게 선택을 요청합니다. 자동 최다득표 확정은 하지 않습니다.
종료 전에도 기존 계약처럼 호스트가 직접 확정할 수 있습니다. 과거 시간 후보는 확정할 수 없습니다.

확정 대기 카드의 1위는 `voteCount` 내림차순으로 표시하고, 동점은 후보 등록 순서를 유지합니다.
일부만 확정된 약속은 `COORDINATING`이며 나머지 투표는 계속 진행할 수 있습니다.

## 장소 검색과 추천

| Method | 경로 | 용도 |
| --- | --- | --- |
| GET | `/places/search` | 카카오 키워드/주소 검색 |
| POST | `/places/saved` | 개인 장소 저장 |
| GET | `/places/saved` | 내가 저장한 장소 |
| DELETE | `/places/saved/{id}` | 본인의 저장 장소 삭제 |
| GET | `/places/recommendations` | 개인 저장 장소 추천 |
| GET | `/appointments/{id}/recommendations` | 개인 장소 + 같은 방의 장소 기록 추천 |
| GET | `/appointments/{id}/weather` | 확정 장소의 현재 날씨 |

검색 쿼리: `query` 필수, `address=false`(주소 검색은 true), `page=1`(1~45),
`size=15`(1~15), 선택적인 `latitude`와 `longitude`(둘 다 필요).
검색 결과는 `items`, `page`, `hasNext`, `attribution`입니다.

장소는 기존 `name`, `latitude`, `longitude` 외에 `address`, `category`, `imageUrl`,
`providerId`, `mapUrl`을 지원합니다. 검색 결과를 그대로 후보에 넣을 수 있습니다.
카카오는 이 API에서 장소 사진을 제공하지 않으므로 `imageUrl`은 null일 수 있습니다.

저장 요청: `{"place":{...장소...},"context":"FRIENDS"}`.
추천 쿼리: `context=ALL|SENIOR|COLLEAGUES|FRIENDS|RECENT`, `query`, `latitude`, `longitude`,
`limit=20`(1~100), `refresh=false`.
맥락별 추천은 사용자가 해당 맥락으로 저장한 장소를 사용합니다. ALL/RECENT에서는 접근 가능한
같은 방의 장소 기록도 포함합니다. RECENT는 개인 저장 최신순 뒤에 약속 생성 최신순 기록을 추가해 중복 제거합니다. 두 출처를 통합한 시각순 정렬은 아닙니다. 좌표가 있으면 RECENT 외 맥락은 거리순입니다.
`refresh=true`는 후보를 섞습니다. 저장/기록이 없다면 빈 목록이며 목업 장소를 삽입하지 않습니다.
추천의 `estimatedWalkMinutes`는 직선거리와 80m/분으로 계산한 참고값이며 도로 경로 기반 ETA가 아닙니다.

외부 연동:

- `KAKAO_REST_API_KEY`: [카카오 Local 공식 API](https://developers.kakao.com/docs/ko/local/dev-guide).
- `WEATHER_ENABLED=true`: [Open-Meteo 현재 날씨 API](https://open-meteo.com/en/docs). 운영 사용 시 제공자의 이용 조건에 맞는 호스트/계정을 설정합니다.
- 날씨 응답: `temperatureCelsius`, WMO `weatherCode`, `observedAt`, `attribution`.
- 검색 키 누락, 날씨 비활성, 외부 장애/시간 초과는 503 `PROVIDER_UNAVAILABLE`.
- HTTP 연결 3초/요청 5초 제한. API 키/외부 오류 본문은 클라이언트에 노출하지 않습니다.
- `app.places.base-url`, `app.weather.base-url`은 운영자 설정 및 테스트 서버 교체용입니다.

## 지도와 도착 현황

| Method | 경로 (`/appointments/{id}` 뒤) | 용도 |
| --- | --- | --- |
| GET | `/map?latitude=...&longitude=...` | 신선한 공유 위치 조회 |
| PUT | `/location` | 내 위치 갱신, 기존 위치 본문과 동일 |
| DELETE | `/location` | 내 위치 공유 즉시 해제, 시간창 밖에서도 가능 |
| GET | `/attendance` | 모든 약속 참여자의 이동/도착/상태/위치 요약 |
| PUT | `/attendance/me` | 본인 상태 갱신 |
| POST | `/members/{memberId}/poke` | 대상 참여자에게 콕 찌르기 알림 저장 |

기존 `/rooms/{id}/map`, `/rooms/{id}/location`은 호환용으로 유지합니다.
두 경로의 id 역시 실제로는 약속 ID입니다. 새 프론트에서는 `/appointments/{id}`를 사용합니다.

```json
{
  "state": "EN_ROUTE",
  "transport": "WALK",
  "etaMinutes": 5,
  "statusMessage": "가는 길에 음료 사 갈게"
}
```

- 상태: `NOT_DEPARTED`, `EN_ROUTE`, `ARRIVED`. 이동 수단: `WALK`, `BICYCLE`, `CAR`, `TRANSIT`, `OTHER`.
- 도착 신고: `{"state":"ARRIVED"}`. 서버가 최초 도착 시각을 기록합니다. 자기 신고 방식이며 GPS 검증은 아닙니다.
- `transport`와 `etaMinutes`는 이동 중 상태에서만 유효합니다. ETA는 클라이언트 보고값이고
  5분간 갱신되지 않으면 null로 반환합니다. 도착 외 상태로 다시 변경하면 도착 시각을 초기화합니다.
- 상태 메시지 최대 200자. 상태 변경/위치 갱신/콕 찌르기는 확정 약속의 위치 공유 시간창 안에서만 가능합니다.
- `/attendance`는 약속 참여자만 조회하며 `serverTime`, `confirmedTime`, `secondsUntilAppointment`,
  `totalCount`, `arrivedCount`, `notDepartedCount`, `participants`를 반환합니다.
- 참여자: ID, 이름, 아바타, 상태, 메시지, 이동 수단, ETA, 도착 시각, 공유 여부, 좌표/갱신 시각, `nextPokeAt`.
  도착자는 도착 시각순, 그 외는 ID순입니다.
- 좌표는 공유 ON + 60초 이내 갱신 + 공유 시간창 내부인 경우만 반환합니다. 그 외 좌표는 null입니다.
  참여 취소/강퇴 시 해당 약속의 저장 위치와 도착 상태도 삭제합니다.
- 콕 찌르기 쿨다운은 약속/보낸 사람/받는 사람별 5분입니다. 중복 요청은 429 `POKE_COOLDOWN`.
  `nextPokeAt`을 사용해 버튼의 남은 시간을 그립니다. 자신이나 비참여자는 찌를 수 없습니다.

## 알림

`GET /notifications`는 자신의 최근 콕 찌르기 100개를 반환합니다.
`PUT /notifications/{id}/read`는 본인 알림을 읽음 처리합니다.
응답 필드: `id`, `appointmentId`, `senderId`, `recipientId`, `createdAt`, `readAt`.
서버 DB 알림함은 동작하지만 FCM/APNs 기기 푸시 발송은 별도 제공자 설정/연동이 필요합니다.
현재 클라이언트는 알림함을 폴링해서 표시할 수 있습니다.

## 실행과 검증

```powershell
cd backend
$env:KAKAO_REST_API_KEY = '개발자 콘솔에서 발급한 값'
$env:MEDIA_BASE_URL = 'http://localhost:8080'
# 선택: $env:WEATHER_ENABLED = 'true'
.\gradlew.bat bootRun
.\gradlew.bat test
```

외부 호출 테스트는 로컬 HTTP 테스트 서버를 사용하므로 실제 키가 필요 없습니다.
`FigmaApiFlowTests`는 실제 Spring MVC/JPA/H2 경로를 통해 방 초대, 익명 단일선택,
마감/추첨, 후보 수정/삭제, 홈/이미지, 도착, 알림 접근 제어, 동시 콕 찌르기를 검증합니다.

로컬 프로필은 기존처럼 메모리 H2이며 재시작하면 이미지/새 데이터도 사라집니다.
영속 운영은 PostgreSQL 프로필과 DB 볼륨을 사용해야 합니다. 기존 `postgres` 프로필의
`ddl-auto: update`는 새 테이블/컬럼을 추가합니다. 운영 배포의 스키마 승인/백업은 별도입니다.
새 테이블: `appointment_poll_settings`, `appointment_attendance`, `poke_notifications`,
`saved_places`, `media_assets`. 기존 테이블에는 커버/아바타/카드, 방 초대 코드, 장소 상세 컬럼이 추가됩니다.
