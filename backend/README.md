# GAMGAM Spring Boot Backend

Java 21, Spring Boot 4.1.1, Spring Web MVC, Bean Validation, Spring Data JPA를 사용합니다. 기본 로컬 DB는 H2이며 PostgreSQL용 프로필도 제공합니다.

화면별 API와 프론트 연동 예제는 [API.md](API.md)를 참고하세요. 홈/모임 필터, 방 초대, 투표 설정·마감·선물 추첨, 후보 수정·삭제, 장소 검색·추천, 도착 현황·콕 찌르기, 이미지 업로드와 카드 꾸미기를 지원합니다.

## 실행 및 테스트

`backend` 디렉터리에서 실행합니다.

```powershell
.\gradlew.bat bootRun
.\gradlew.bat test
```

기본 주소는 `http://localhost:8080`, 기본 프로필은 `local`입니다. 상태 확인은 `GET /api/v1/health`를 사용합니다.

## 인증과 공통 응답

약속·투표·방·지도 API는 `Authorization: Bearer <accessToken>`을 사용합니다. 서버가 토큰에서 사용자 ID를 확인하므로 `X-User-Id`로 사용자를 지정할 수 없습니다.

| Method | Path | 기능 |
| --- | --- | --- |
| POST | `/api/v1/auth/signup` | 회원가입, `email`, `password`, `name`, HTTP 201 |
| POST | `/api/v1/auth/login` | 로그인, `email`, `password` |
| GET | `/api/v1/auth/me` | 내 정보 조회 |
| PATCH | `/api/v1/auth/me` | 이름 변경, `name` |
| POST | `/api/v1/auth/logout` | 로그아웃 응답 반환 |

로그인 응답에는 `tokenType`, `accessToken`, `expiresIn`, `user`가 포함됩니다. 현재 로그아웃 API는 토큰 폐기 목록을 관리하지 않으며 클라이언트에서 토큰을 삭제해야 합니다.

- 성공 응답은 `{ "success": true, "data": ... }`입니다.
- 오류 응답은 `{ "success": false, "code": "...", "message": "...", "fieldErrors": ... }`입니다.
- 검증 실패는 400 `VALIDATION_ERROR`, 잘못된 JSON·enum 등은 400 `BAD_REQUEST`입니다.
- 존재하지 않는 약속은 404 `APPOINTMENT_NOT_FOUND`, 방 접근 거부는 403 `ROOM_ACCESS_DENIED`입니다.

## 방과 약속 조회

| Method | Path | 기능 |
| --- | --- | --- |
| POST | `/api/v1/rooms` | `{"name":"스터디"}`로 방 생성, HTTP 201 |
| GET | `/api/v1/rooms` | 내가 속한 방 목록 |
| GET | `/api/v1/rooms/{roomId}` | 방 상세 |
| GET | `/api/v1/appointments` | 내가 속한 방들의 약속 목록 |
| GET | `/api/v1/rooms/{roomId}/appointments` | 해당 방의 약속 목록 |
| GET | `/api/v1/appointments/{id}` | 약속 상세 |

방 이름은 앞뒤 공백 제거 후 1~50자이며 생성자는 방 멤버로 등록됩니다. 방 멤버는 아직 투표하지 않았어도 방의 약속 목록·상세·투표 현황을 볼 수 있습니다. 조회만으로 약속 참여자가 되지는 않습니다. 약속 목록은 생성 시각 내림차순입니다.

## 약속 생성과 이름 변경

`AppointmentController`가 약속 생성·조회·이름 변경·확정·멤버 관리·벌칙을 담당합니다.

`POST /api/v1/rooms/{roomId}/appointments`로 약속을 생성하며 HTTP 201을 반환합니다. 방 멤버가 생성할 수 있고 생성자는 약속 방장(`HOST`)으로 등록됩니다.

```json
{ "name": "주말 모임" }
```

`template`을 생략하면 시간·장소 후보가 비어 있는 `BOTH`, `COORDINATING` 상태로 생성됩니다. 이 경우 확정 시간·장소는 생략하고 후보 목록도 생략하거나 빈 배열로 보내야 합니다. 이후 후보 추가 API를 이용합니다.

| 필드 | 규칙 |
| --- | --- |
| `name` | 필수, 공백 불가, 최대 50자 |
| `template` | 선택, `ALL`, `TIME_ONLY`, `PLACE_ONLY`, `BOTH` |
| `candidatesTime` | 템플릿에 따른 미래 시간 목록 |
| `confirmedTime` | 템플릿에 따른 미래 시간 |
| `candidatesPlace` | 템플릿에 따른 장소 목록 |
| `confirmedPlace` | 템플릿에 따른 확정 장소 |
| `penalty` | 선택, 벌칙 규칙 |
| `reward` | 선택, `description` 필수·최대 100자 |
| `locationSharing` | 선택, 위치 공유 시간 설정 |

명시적으로 템플릿을 보내면 다음 규칙을 적용합니다. 조율하는 항목은 후보가 2개 이상 필요하고 확정값은 생략합니다. 이미 정한 항목은 확정값이 필수이며 후보는 생략하거나 빈 배열로 보냅니다.

| 템플릿 | 시간 | 장소 | 초기 상태 |
| --- | --- | --- | --- |
| `ALL` | `confirmedTime` | `confirmedPlace` | `CONFIRMED` |
| `TIME_ONLY` | `candidatesTime` | `confirmedPlace` | `COORDINATING` |
| `PLACE_ONLY` | `confirmedTime` | `candidatesPlace` | `COORDINATING` |
| `BOTH` | `candidatesTime` | `candidatesPlace` | `COORDINATING` |

장소는 `name`이 필수이며 최대 100자입니다. `latitude`(-90~90)와 `longitude`(-180~180)는 함께 보내거나 함께 생략합니다. 이름에서 좌표를 자동으로 찾는 기능은 없습니다.

`PATCH /api/v1/appointments/{id}`에 `{"name":"변경한 모임"}`을 보내 이름을 변경합니다. 해당 방 멤버인 약속 방장만 가능하며 앞뒤 공백 제거 후 1~50자입니다. 현재는 약속 상태에 따른 이름 변경 제한이 없습니다.

## 투표와 참여

`AppointmentVotingController`가 투표 조회·변경과 후보 추가를 담당합니다.

| Method | Path | 요청 |
| --- | --- | --- |
| GET | `/api/v1/appointments/{id}/votes` | 투표 현황 조회 |
| PUT | `/api/v1/appointments/{id}/votes/time` | `{"candidateIds":["후보 UUID 1","후보 UUID 2"]}` |
| PUT | `/api/v1/appointments/{id}/votes/place` | `{"candidateIds":["후보 UUID 1","후보 UUID 2"]}` |
| PUT | `/api/v1/appointments/{id}/votes/regardless` | `{"selected":true}` 또는 `false` |
| POST | `/api/v1/appointments/{id}/time-candidates` | `{"time":"2030-01-03T18:00:00+09:00"}` |
| POST | `/api/v1/appointments/{id}/place-candidates` | `{"name":"새 카페","latitude":37.5,"longitude":127.0}` |

- 방 멤버가 시간 또는 장소 후보에 투표하면 약속 참여자로 등록됩니다. 후보 추가만으로는 참여하거나 투표하지 않습니다.
- 투표 PUT은 해당 종류의 내 선택 전체를 교체합니다. 빈 배열 `[]`로 해당 종류의 투표를 모두 취소합니다. 다른 종류의 내 표와 다른 사람의 표는 유지됩니다.
- 시간·장소 후보는 생성 시 발급하여 DB에 저장한 UUID인 `candidateId`로 식별합니다. `candidateIds` 필드 생략, `null`, 빈 문자열·공백, 존재하지 않는 ID, 다른 약속 또는 다른 종류의 후보 ID는 거절하며 중복 ID는 한 표로 처리합니다.
- 시간·장소 표가 모두 없고 상관없이 참여도 꺼져 있으면 일반 참여자의 멤버·투표 기록을 제거합니다.
- 방장은 투표를 모두 취소해도 `HOST` 멤버로 유지됩니다. 다만 실제 표나 상관없이 참여 표시가 없으면 투표 응답의 참여자 목록에는 포함되지 않습니다.
- 상관없이 참여를 켜면 내 시간·장소 표를 모두 지웁니다. 특정 후보에 투표하면 상관없이 참여가 해제됩니다. 상관없이 참여자는 특정 후보의 득표수에 합산하지 않습니다.
- 후보는 기존 목록 뒤에 추가합니다. 호스트의 수정·삭제 API는 [API.md](API.md)를 참고하세요. 재정렬 API는 없습니다.
- 시간 후보는 미래 시각과 시간대가 필요합니다. 마이크로초 정밀도로 반올림하며 같은 순간의 후보는 409 `DUPLICATE_CANDIDATE`입니다.
- 장소 이름은 앞뒤 공백을 제거합니다. 이름의 대소문자·앞뒤 공백을 제외하고 이름과 좌표가 모두 같으면 중복입니다.
- `COORDINATING` 상태에서 해당 템플릿이 조율하는 항목만 투표·후보 추가가 가능합니다. 확정된 항목의 투표 변경·후보 추가는 막습니다.
- 조율 대상 중 하나라도 확정되면 상관없이 참여 전환도 막습니다. 생성 시 미리 지정한 확정 항목은 이 제한의 대상이 아닙니다.

생성 요청의 후보 입력 형식은 그대로입니다. 서버가 ID를 발급하므로 클라이언트는 생성·조회·후보 추가 응답에서 받은 ID를 사용합니다.

| 응답 필드 | 항목 형식 |
| --- | --- |
| 약속 응답 `candidatesTime` | `{"candidateId":"UUID","time":"2030-01-03T18:00:00+09:00"}` |
| 약속 응답 `candidatesPlace` | `{"candidateId":"UUID","place":{"name":"카페","latitude":37.5,"longitude":127.0}}` |
| 약속 응답 `timeVotes`, `placeVotes` | `{"후보 UUID":["사용자 ID"]}` |

투표 응답의 `timeOptions`·`placeOptions`에도 동일한 `candidateId`가 포함됩니다. `confirmedTime`·`confirmedPlace`는 기존 확정값 형식을 유지합니다. 이전 `optionIndex`·`optionIndexes` 요청은 지원하지 않습니다.

투표 응답 `data`에는 다음 필드가 포함됩니다.

| 필드 | 의미 |
| --- | --- |
| `appointmentId`, `roomId`, `status` | 약속·방·상태 |
| `participating`, `participantIds` | 내 참여 여부와 실제 참여자 ID 목록 |
| `participatingRegardless`, `regardlessParticipantIds` | 상관없이 참여 여부와 해당 사용자 목록 |
| `timeOptions` | `candidateId`, `time`, `voteCount`, `voterIds`, `votedByMe` |
| `placeOptions` | `candidateId`, `place`, `voteCount`, `voterIds`, `votedByMe` |

후보의 득표순 표시는 프론트에서 `voteCount` 내림차순으로 정렬합니다. 동률은 응답의 등록 순서를 유지하며, 투표·확정 요청에는 선택한 후보의 `candidateId`를 사용합니다. 화면에서 정렬해도 ID는 바뀌지 않습니다. 백엔드는 후보 등록 순서로 반환합니다.

이전 `POST /votes/time/{index}`, `PUT /votes/place/{index}`, `DELETE /votes/place`, `POST /options/time` 경로는 제거되었습니다. 취소도 현재 PUT API의 빈 배열로 처리합니다.

## 약속 확정과 완료

약속 생성자(`HOST`)가 시간과 장소의 후보를 각각 최종 선택해 확정합니다. 득표수와 관계없이 후보를 선택할 수 있습니다.

| Method | Path | 요청과 동작 |
| --- | --- | --- |
| POST | `/api/v1/appointments/{id}/confirm/time` | 시간 확정. `{"candidateId":"시간 후보 UUID"}` 필수 |
| POST | `/api/v1/appointments/{id}/confirm/place` | 장소 확정. `{"candidateId":"장소 후보 UUID"}` 필수 |
| POST | `/api/v1/appointments/{id}/complete` | 방장이 `CONFIRMED` 약속을 `COMPLETED`로 변경 |

- 요청 본문과 `candidateId`는 필수입니다. 본문 생략, `{}`, `null`, 빈 문자열·공백, 존재하지 않는 ID, 다른 약속 또는 다른 종류의 후보 ID는 HTTP 400으로 거절합니다. 후보가 없는 경우에도 확정할 수 없습니다.
- 개별 확정은 해당 방 멤버인 약속 방장만 호출할 수 있습니다. 이미 확정한 항목은 재확정할 수 없습니다.
- 일괄 확정 API(`/api/v1/appointments/{id}/confirm`)는 제거했습니다.
- 시간과 장소가 모두 정해지면 `CONFIRMED`가 됩니다. 일부만 정해졌다면 `COORDINATING`을 유지하며 남은 항목을 계속 투표할 수 있습니다.
- 시간·장소의 확정 순서는 자유입니다. `TIME_ONLY`·`PLACE_ONLY`는 생성 시 정해진 항목이 있으므로 남은 항목을 확정하면 `CONFIRMED`가 됩니다.
- 생성자가 지도 표시 시점까지 선택하지 않았을 때 최다득표 후보를 자동 선정하는 기능은 향후 개발 예정입니다. 현재 후보 ID 생략이나 특정 시각 도달에 따른 자동 확정은 없습니다.

## 약속 나가기와 강퇴

| Method | Path | 동작 |
| --- | --- | --- |
| DELETE | `/api/v1/appointments/{id}/members/me` | 본인의 약속 참여 취소 |
| DELETE | `/api/v1/appointments/{id}/members/{memberId}` | 약속 방장이 참여자 강퇴 |

`memberId`에는 대상 사용자의 ID를 넣습니다. 방장 본인의 나가기·강퇴는 거절합니다. 참여자를 제거할 때 멤버와 시간·장소 투표를 같은 트랜잭션에서 삭제합니다. 강퇴는 재참여 차단 기능이 아니므로 방 멤버는 투표 가능한 상태에서 다시 투표해 참여할 수 있습니다.

## 벌칙 설정과 수정

벌칙 객체를 생략하면 벌칙 없이 생성합니다. 벌칙을 설정할 때는 다음 값을 사용합니다.

| 필드 | 규칙 |
| --- | --- |
| `description` | 필수, 공백 불가, 최대 100자 |
| `lateThresholdMin` | 필수, `FIVE`, `TEN`, `FIFTEEN` 문자열로 각각 5·10·15분 지정 |
| `target` | `ALL_LATE`만 지원. 생략·`null`이면 `ALL_LATE` |

`ALL_LATE`는 설정한 지각 기준에 해당하는 사람 전원을 벌칙 대상으로 지정하는 규칙입니다. 기본값은 약속 생성과 벌칙 수정에 동일하게 적용합니다. `LATEST_ONLY` 등 지원하지 않는 값은 HTTP 400 `BAD_REQUEST`로 거절합니다. 대상 선택 UI와 가장 늦은 사람 등의 추가 옵션은 향후 확장 대상입니다.

| Method | Path | 동작 |
| --- | --- | --- |
| PUT | `/api/v1/appointments/{id}/penalty` | 생성자가 확정 전 벌칙 객체를 본문으로 보내 추가·수정 |

벌칙은 약속 생성 요청의 `penalty`로 설정하거나 생성 후 위 API로 추가·수정할 수 있습니다. 수정은 `COORDINATING` 상태에서 생성자만 가능합니다. 시간·장소 중 하나만 확정한 상태에서도 수정할 수 있으며, 둘 다 정해진 `CONFIRMED` 상태와 완료된 `COMPLETED` 상태에서는 HTTP 400 `BAD_REQUEST`로 거절합니다. 처음부터 `ALL` 템플릿으로 생성한 약속도 이미 확정 상태이므로 벌칙을 수정할 수 없습니다.

벌칙은 참여자가 내용을 인지하고 참여하는 정책이며 별도 동의를 받지 않습니다. 동의 API(`/api/v1/appointments/{id}/penalty/agreement`), `PenaltyAgreement` 엔티티·저장소, 응답의 `penaltyAgreedUserIds`는 제거했습니다.

## 약속 응답과 저장 구조

약속 생성·목록·상세 응답에는 다음 정보가 포함됩니다.

- 기본 정보와 설정 — `id`, `roomId`, `name`, `template`, `status`, `createdAt`, `hostId`
- 후보·확정 정보 — `candidatesTime`, `confirmedTime`, `candidatesPlace`, `confirmedPlace`
- 규칙 — `penalty`, `reward`, `locationSharing`
- 멤버·투표 — `members`, `timeVotes`, `placeVotes`
- 기존 공유 관련 필드 — `shareUrl`, `inviteCode`

`timeVotes`와 `placeVotes`는 후보 ID를 키로 하는 사용자 ID 목록입니다. 후보·확정 시간은 UTC로 저장하고 응답에서는 KST(`+09:00`)로 변환합니다. `createdAt`은 `Instant`입니다.

약속 멤버는 `AppointmentMember`로 통합했습니다. 역할은 `HOST`·`MEMBER`이고 상관없이 참여 여부는 `regardlessOfTimeAndPlace`로 관리합니다. 시간·장소 투표는 `AppointmentVote`와 `VoteType.TIME`·`PLACE`로 통합했습니다. 투표 변경·후보 추가·확정·참여자 제거 등의 변경 작업은 약속 행 잠금을 사용해 처리합니다.

사용하지 않는 엔티티의 이전 `confirm()`과 서비스의 `isMember()` 메서드는 제거했습니다. 확정 처리는 서비스의 공통 선택 로직과 엔티티의 `confirmTime()`·`confirmPlace()`를 사용합니다.

## 초대 관련 현재 상태

제품 방향은 **방으로 초대하고 약속은 방 안에서 투표로 참여**하는 것입니다. 기존 약속 초대 코드와 가입 API 정리는 별도 논의 대상으로 남아 있습니다.

현재 `POST /api/v1/appointments/join`은 `{"inviteCode":"..."}`를 받아 약속 멤버를 등록하는 기존 API입니다. `inviteCode` 생성·조회와 응답 필드, `{app.share.base-url}/invite/{code}` 형태의 `shareUrl`도 남아 있습니다. 새 방 초대·가입은 `/rooms/{roomId}/invite`, `/rooms/join`을 사용합니다. 링크 폐기와 권한 정책은 [API.md](API.md)를 참고하세요.

## 위치 공유와 지도

| Method | Path | 요청 |
| --- | --- | --- |
| GET | `/api/v1/rooms/{roomId}/map` | 쿼리 `latitude`, `longitude` |
| PUT | `/api/v1/rooms/{roomId}/location` | `latitude`, `longitude`, `sharingEnabled`, 선택적으로 `shareLevel`, `speedKmh`, `transport` |

새 지도 API는 `/appointments/{id}/map`, `/appointments/{id}/location`입니다. 호환용 기존 API의 `roomId` 역시 **약속 ID**로 조회합니다. 약속 멤버이며 약속이 `CONFIRMED` 상태이고 위치 공유 시간 범위 안에 있어야 합니다.

`locationSharing.startMinutesBefore`, `maxMinutesAfter`는 각각 0~240분이며 기본값은 각각 30분입니다. 객체나 필드를 생략하면 기본값을 적용합니다.

지도는 공유가 켜져 있고 최근 60초 안에 갱신된 위치를 반환합니다. 응답은 `roomId`, `roomName`, `currentUserId`, `participants`이며 참가자는 `id`, `name`, `latitude`, `longitude`, `distanceMeters`, `self`, `mock`, `updatedAt`을 포함합니다. 현재 실제 저장 위치를 사용하며 `mock`은 `false`입니다. 자신을 먼저, 나머지는 거리순으로 정렬합니다.

위도·경도 범위는 각각 -90~90, -180~180입니다. `shareLevel`은 `ALL`, `BASIC`, `CLOSE`, `OFF`이며 생략 시 `BASIC`, `OFF`는 공유 비활성화로 처리합니다.

## PowerShell 호출 예시

회원가입·로그인 후 실제로 생성한 방과 약속 ID를 사용합니다. 아래 예시는 같은 PowerShell 세션에서 순서대로 실행합니다.

```powershell
$base = 'http://localhost:8080/api/v1'
$signup = @{ email = 'demo@example.com'; password = 'demo-password-123'; name = 'Demo' } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "$base/auth/signup" -ContentType 'application/json' -Body $signup
$loginBody = @{ email = 'demo@example.com'; password = 'demo-password-123' } | ConvertTo-Json
$login = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType 'application/json' -Body $loginBody
$headers = @{ Authorization = "Bearer $($login.data.accessToken)" }
$room = Invoke-RestMethod -Method Post -Uri "$base/rooms" -Headers $headers -ContentType 'application/json' -Body '{"name":"Demo room"}'
$created = Invoke-RestMethod -Method Post -Uri "$base/rooms/$($room.data.id)/appointments" -Headers $headers -ContentType 'application/json' -Body '{"name":"Demo meeting"}'
$url = "$base/appointments/$($created.data.id)"
$future = (Get-Date).AddDays(1).ToString('o')
$timeBody = @{ time = $future } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "$url/time-candidates" -Headers $headers -ContentType 'application/json' -Body $timeBody
Invoke-RestMethod -Method Post -Uri "$url/place-candidates" -Headers $headers -ContentType 'application/json' -Body '{"name":"Cafe"}'
$voting = Invoke-RestMethod -Uri "$url/votes" -Headers $headers
$timeId = $voting.data.timeOptions[0].candidateId
$placeId = $voting.data.placeOptions[0].candidateId
$timeVote = @{ candidateIds = @($timeId) } | ConvertTo-Json
$placeVote = @{ candidateIds = @($placeId) } | ConvertTo-Json
Invoke-RestMethod -Method Put -Uri "$url/votes/time" -Headers $headers -ContentType 'application/json' -Body $timeVote
Invoke-RestMethod -Method Put -Uri "$url/votes/place" -Headers $headers -ContentType 'application/json' -Body $placeVote
Invoke-RestMethod -Uri "$url/votes" -Headers $headers | ConvertTo-Json -Depth 8
$timeConfirm = @{ candidateId = $timeId } | ConvertTo-Json
$placeConfirm = @{ candidateId = $placeId } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "$url/confirm/time" -Headers $headers -ContentType 'application/json' -Body $timeConfirm
Invoke-RestMethod -Method Post -Uri "$url/confirm/place" -Headers $headers -ContentType 'application/json' -Body $placeConfirm
Invoke-RestMethod -Uri $url -Headers $headers | ConvertTo-Json -Depth 8
```

## 환경별 DB와 설정

| 파일 | 역할 |
| --- | --- |
| `application.yml` | 공통 설정, 기본 프로필 `local`, JDBC 시간대 UTC |
| `application-local.yml` | H2 인메모리 DB, 로컬 CORS·JWT·공유 주소 |
| `application-postgres.yml` | PostgreSQL 연결, `ddl-auto: update` |
| `application-prod.yml` | 운영 JWT·CORS·공유 주소 환경변수 |

로컬 H2 URL은 다음과 같습니다.

```text
jdbc:h2:mem:gamgam;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH;DB_CLOSE_DELAY=-1
```

`DB_CLOSE_DELAY=-1`은 마지막 연결이 닫혀도 JVM이 실행 중인 동안 인메모리 DB를 유지합니다. 서버를 종료하면 데이터가 사라지며, 로컬 `ddl-auto: create-drop`도 종료 시 스키마를 삭제합니다. `MODE=PostgreSQL`은 H2 호환 모드입니다. 기본 실행은 H2를 사용합니다.

PostgreSQL을 사용할 때는 실행 중인 DB를 준비하고 `postgres` 프로필을 선택합니다. `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`를 설정할 수 있으며 기본값은 각각 `jdbc:postgresql://localhost:5432/gamgam`, `gamgam`, `gamgam`입니다.

```powershell
.\gradlew.bat bootRun --args="--spring.profiles.active=postgres"
```

`prod` 프로필은 `JWT_SECRET`, `CORS_ALLOWED_ORIGINS`, `SHARE_BASE_URL`을 요구합니다. `JWT_EXPIRATION_SECONDS`는 선택이며 기본 3600초입니다. 운영 프로필의 DB 설정은 현재 주석 상태이므로 배포 시 사용할 DB 연결과 스키마 관리 설정을 별도로 구성해야 합니다.

로컬 CORS는 `localhost`·`127.0.0.1`의 포트를 허용하고 로컬 공유 주소는 `http://localhost:3000`입니다.
