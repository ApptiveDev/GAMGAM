# 신규 화면 API 상세 명세

기준: 백엔드 구현 69cc4d4, main 통합. 구현 완료와 운영 배포는 별개입니다.

## 홈 약속 조회

### 동작 설명

`GET /api/v1/home`

내 방의 약속 카드와 다음 확정 약속을 조회합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **인증 사용자**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| filter | query | string | 선택 | "ALL" ALL, UPCOMING, COMPLETED |
| sort | query | string | 선택 | "NEWEST" NEWEST, TIME, NAME |
| query | query | string | 선택 | ""  |
| page | query | integer(int32) | 선택 | 0  |
| size | query | integer(int32) | 선택 | 20  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.serverTime | string(date-time) | — | 서버 현재 시각(UTC) |
| data.nextAppointment | object | — | 다음 미래 확정 약속; 없으면 null |
| data.nextAppointment.id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data.nextAppointment.roomId | string | — | 방 ID; 지도 응답에서는 호환상 약속 ID |
| data.nextAppointment.name | string | — | 이름 |
| data.nextAppointment.template | string | — | 허용: ALL, TIME_ONLY, PLACE_ONLY, BOTH |
| data.nextAppointment.candidatesTime | object[] | — | 시간 후보 목록 |
| data.nextAppointment.candidatesTime[].candidateId | string | — | 서버 발급 후보 UUID |
| data.nextAppointment.candidatesTime[].time | string(date-time) | — | 후보 시각(KST 응답) |
| data.nextAppointment.confirmedTime | string(date-time) | — | 확정 약속 시각(KST); 미확정 null |
| data.nextAppointment.candidatesPlace | object[] | — | 장소 후보 목록 |
| data.nextAppointment.candidatesPlace[].candidateId | string | — | 서버 발급 후보 UUID |
| data.nextAppointment.candidatesPlace[].place | object | — | 장소 정보 |
| data.nextAppointment.candidatesPlace[].place.name | string | — | 이름 |
| data.nextAppointment.candidatesPlace[].place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.nextAppointment.candidatesPlace[].place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.nextAppointment.candidatesPlace[].place.address | string | — | 주소; 없으면 null |
| data.nextAppointment.candidatesPlace[].place.category | string | — | 장소 분류; 없으면 null |
| data.nextAppointment.candidatesPlace[].place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.nextAppointment.candidatesPlace[].place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.nextAppointment.candidatesPlace[].place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.nextAppointment.confirmedPlace | object | — | 확정 장소; 미확정 null |
| data.nextAppointment.confirmedPlace.name | string | — | 이름 |
| data.nextAppointment.confirmedPlace.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.nextAppointment.confirmedPlace.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.nextAppointment.confirmedPlace.address | string | — | 주소; 없으면 null |
| data.nextAppointment.confirmedPlace.category | string | — | 장소 분류; 없으면 null |
| data.nextAppointment.confirmedPlace.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.nextAppointment.confirmedPlace.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.nextAppointment.confirmedPlace.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.nextAppointment.penalty | object | — | 벌칙 설정; 없으면 null |
| data.nextAppointment.penalty.description | string | — | 설명 |
| data.nextAppointment.penalty.lateThresholdMin | string | — | 허용: FIVE, TEN, FIFTEEN |
| data.nextAppointment.penalty.target | string | — | 허용: ALL_LATE |
| data.nextAppointment.reward | object | — | 기존 약속 보상; 투표별 선물과 별개 |
| data.nextAppointment.reward.description | string | — | 설명 |
| data.nextAppointment.locationSharing | object | — | 약속 위치 공유 시간 정책 |
| data.nextAppointment.locationSharing.startMinutesBefore | integer(int32) | — | 약속 이전 공유 가능 분 |
| data.nextAppointment.locationSharing.maxMinutesAfter | integer(int32) | — | 약속 이후 공유 가능 분 |
| data.nextAppointment.status | string | — | 허용: COORDINATING, CONFIRMED, COMPLETED |
| data.nextAppointment.shareUrl | string | — | 초대 공유 링크 |
| data.nextAppointment.createdAt | string(date-time) | — | 생성 시각(UTC) |
| data.nextAppointment.hostId | string | — | 약속 호스트 사용자 ID |
| data.nextAppointment.inviteCode | string | — | 초대 코드 |
| data.nextAppointment.members | object[] | — | 약속 멤버 목록 |
| data.nextAppointment.members[].userId | string | — | 사용자 ID |
| data.nextAppointment.members[].name | string | — | 이름 |
| data.nextAppointment.members[].role | string | — | 허용: HOST, MEMBER |
| data.nextAppointment.members[].joinedAt | string(date-time) | — | 가입 시각(UTC) |
| data.nextAppointment.members[].avatarUrl | string | — | 프로필 이미지 URL; 미설정 null |
| data.nextAppointment.timeVotes | object | — | 후보별 시간 투표자 ID 맵; 익명은 빈 객체 |
| data.nextAppointment.placeVotes | object | — | 후보별 장소 투표자 ID 맵; 익명은 빈 객체 |
| data.nextAppointment.coverImageUrl | string | — | 대표 이미지 URL; 미설정 null |
| data.nextAppointment.cardText | string | — | 카드 문구; 미설정 null |
| data.nextAppointment.cardStyle | string | — | 프론트 카드 스타일 식별자; 미설정 null |
| data.secondsUntilNext | integer(int64) | — | 다음 확정 약속까지 초; 없으면 null |
| data.totalCount | integer(int64) | — | 목록은 필터 적용 결과 수, 도착 현황은 참여자 수 |
| data.upcomingCount | integer(int64) | — | 검색·필터 전 미완료 약속 수 |
| data.completedCount | integer(int64) | — | 검색·필터 전 완료 약속 수 |
| data.page | integer(int32) | — | 요청한 페이지 번호 |
| data.size | integer(int32) | — | 목록의 페이지 크기 또는 업로드 저장 바이트 수 |
| data.items | object[] | — | 결과 목록 |
| data.items[].id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data.items[].roomId | string | — | 방 ID; 지도 응답에서는 호환상 약속 ID |
| data.items[].name | string | — | 이름 |
| data.items[].template | string | — | 허용: ALL, TIME_ONLY, PLACE_ONLY, BOTH |
| data.items[].candidatesTime | object[] | — | 시간 후보 목록 |
| data.items[].candidatesTime[].candidateId | string | — | 서버 발급 후보 UUID |
| data.items[].candidatesTime[].time | string(date-time) | — | 후보 시각(KST 응답) |
| data.items[].confirmedTime | string(date-time) | — | 확정 약속 시각(KST); 미확정 null |
| data.items[].candidatesPlace | object[] | — | 장소 후보 목록 |
| data.items[].candidatesPlace[].candidateId | string | — | 서버 발급 후보 UUID |
| data.items[].candidatesPlace[].place | object | — | 장소 정보 |
| data.items[].candidatesPlace[].place.name | string | — | 이름 |
| data.items[].candidatesPlace[].place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.items[].candidatesPlace[].place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.items[].candidatesPlace[].place.address | string | — | 주소; 없으면 null |
| data.items[].candidatesPlace[].place.category | string | — | 장소 분류; 없으면 null |
| data.items[].candidatesPlace[].place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.items[].candidatesPlace[].place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.items[].candidatesPlace[].place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.items[].confirmedPlace | object | — | 확정 장소; 미확정 null |
| data.items[].confirmedPlace.name | string | — | 이름 |
| data.items[].confirmedPlace.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.items[].confirmedPlace.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.items[].confirmedPlace.address | string | — | 주소; 없으면 null |
| data.items[].confirmedPlace.category | string | — | 장소 분류; 없으면 null |
| data.items[].confirmedPlace.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.items[].confirmedPlace.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.items[].confirmedPlace.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.items[].penalty | object | — | 벌칙 설정; 없으면 null |
| data.items[].penalty.description | string | — | 설명 |
| data.items[].penalty.lateThresholdMin | string | — | 허용: FIVE, TEN, FIFTEEN |
| data.items[].penalty.target | string | — | 허용: ALL_LATE |
| data.items[].reward | object | — | 기존 약속 보상; 투표별 선물과 별개 |
| data.items[].reward.description | string | — | 설명 |
| data.items[].locationSharing | object | — | 약속 위치 공유 시간 정책 |
| data.items[].locationSharing.startMinutesBefore | integer(int32) | — | 약속 이전 공유 가능 분 |
| data.items[].locationSharing.maxMinutesAfter | integer(int32) | — | 약속 이후 공유 가능 분 |
| data.items[].status | string | — | 허용: COORDINATING, CONFIRMED, COMPLETED |
| data.items[].shareUrl | string | — | 초대 공유 링크 |
| data.items[].createdAt | string(date-time) | — | 생성 시각(UTC) |
| data.items[].hostId | string | — | 약속 호스트 사용자 ID |
| data.items[].inviteCode | string | — | 초대 코드 |
| data.items[].members | object[] | — | 약속 멤버 목록 |
| data.items[].members[].userId | string | — | 사용자 ID |
| data.items[].members[].name | string | — | 이름 |
| data.items[].members[].role | string | — | 허용: HOST, MEMBER |
| data.items[].members[].joinedAt | string(date-time) | — | 가입 시각(UTC) |
| data.items[].members[].avatarUrl | string | — | 프로필 이미지 URL; 미설정 null |
| data.items[].timeVotes | object | — | 후보별 시간 투표자 ID 맵; 익명은 빈 객체 |
| data.items[].placeVotes | object | — | 후보별 장소 투표자 ID 맵; 익명은 빈 객체 |
| data.items[].coverImageUrl | string | — | 대표 이미지 URL; 미설정 null |
| data.items[].cardText | string | — | 카드 문구; 미설정 null |
| data.items[].cardStyle | string | — | 프론트 카드 스타일 식별자; 미설정 null |

### 동작 규칙·주의사항

page ≥ 0, size 1~100, query 최대 100자. UPCOMING은 COORDINATING을 포함한 미완료 약속입니다. totalCount는 검색·필터 적용 결과이며 upcomingCount/completedCount와 nextAppointment는 필터 전 전체 기준입니다. TIME 정렬은 미확정 시각을 뒤로 보냅니다. nextAppointment가 없으면 secondsUntilNext도 null입니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 모임 대시보드 조회

### 동작 설명

`GET /api/v1/rooms/{roomId}/dashboard`

모임의 약속 카드와 상태별 개수를 조회합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **해당 방 멤버**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| roomId | path | string | 필수 | ""  |
| filter | query | string | 선택 | "ALL" ALL, UPCOMING, COMPLETED |
| sort | query | string | 선택 | "NEWEST" NEWEST, TIME, NAME |
| query | query | string | 선택 | ""  |
| page | query | integer(int32) | 선택 | 0  |
| size | query | integer(int32) | 선택 | 20  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.serverTime | string(date-time) | — | 서버 현재 시각(UTC) |
| data.nextAppointment | object | — | 다음 미래 확정 약속; 없으면 null |
| data.nextAppointment.id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data.nextAppointment.roomId | string | — | 방 ID; 지도 응답에서는 호환상 약속 ID |
| data.nextAppointment.name | string | — | 이름 |
| data.nextAppointment.template | string | — | 허용: ALL, TIME_ONLY, PLACE_ONLY, BOTH |
| data.nextAppointment.candidatesTime | object[] | — | 시간 후보 목록 |
| data.nextAppointment.candidatesTime[].candidateId | string | — | 서버 발급 후보 UUID |
| data.nextAppointment.candidatesTime[].time | string(date-time) | — | 후보 시각(KST 응답) |
| data.nextAppointment.confirmedTime | string(date-time) | — | 확정 약속 시각(KST); 미확정 null |
| data.nextAppointment.candidatesPlace | object[] | — | 장소 후보 목록 |
| data.nextAppointment.candidatesPlace[].candidateId | string | — | 서버 발급 후보 UUID |
| data.nextAppointment.candidatesPlace[].place | object | — | 장소 정보 |
| data.nextAppointment.candidatesPlace[].place.name | string | — | 이름 |
| data.nextAppointment.candidatesPlace[].place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.nextAppointment.candidatesPlace[].place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.nextAppointment.candidatesPlace[].place.address | string | — | 주소; 없으면 null |
| data.nextAppointment.candidatesPlace[].place.category | string | — | 장소 분류; 없으면 null |
| data.nextAppointment.candidatesPlace[].place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.nextAppointment.candidatesPlace[].place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.nextAppointment.candidatesPlace[].place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.nextAppointment.confirmedPlace | object | — | 확정 장소; 미확정 null |
| data.nextAppointment.confirmedPlace.name | string | — | 이름 |
| data.nextAppointment.confirmedPlace.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.nextAppointment.confirmedPlace.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.nextAppointment.confirmedPlace.address | string | — | 주소; 없으면 null |
| data.nextAppointment.confirmedPlace.category | string | — | 장소 분류; 없으면 null |
| data.nextAppointment.confirmedPlace.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.nextAppointment.confirmedPlace.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.nextAppointment.confirmedPlace.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.nextAppointment.penalty | object | — | 벌칙 설정; 없으면 null |
| data.nextAppointment.penalty.description | string | — | 설명 |
| data.nextAppointment.penalty.lateThresholdMin | string | — | 허용: FIVE, TEN, FIFTEEN |
| data.nextAppointment.penalty.target | string | — | 허용: ALL_LATE |
| data.nextAppointment.reward | object | — | 기존 약속 보상; 투표별 선물과 별개 |
| data.nextAppointment.reward.description | string | — | 설명 |
| data.nextAppointment.locationSharing | object | — | 약속 위치 공유 시간 정책 |
| data.nextAppointment.locationSharing.startMinutesBefore | integer(int32) | — | 약속 이전 공유 가능 분 |
| data.nextAppointment.locationSharing.maxMinutesAfter | integer(int32) | — | 약속 이후 공유 가능 분 |
| data.nextAppointment.status | string | — | 허용: COORDINATING, CONFIRMED, COMPLETED |
| data.nextAppointment.shareUrl | string | — | 초대 공유 링크 |
| data.nextAppointment.createdAt | string(date-time) | — | 생성 시각(UTC) |
| data.nextAppointment.hostId | string | — | 약속 호스트 사용자 ID |
| data.nextAppointment.inviteCode | string | — | 초대 코드 |
| data.nextAppointment.members | object[] | — | 약속 멤버 목록 |
| data.nextAppointment.members[].userId | string | — | 사용자 ID |
| data.nextAppointment.members[].name | string | — | 이름 |
| data.nextAppointment.members[].role | string | — | 허용: HOST, MEMBER |
| data.nextAppointment.members[].joinedAt | string(date-time) | — | 가입 시각(UTC) |
| data.nextAppointment.members[].avatarUrl | string | — | 프로필 이미지 URL; 미설정 null |
| data.nextAppointment.timeVotes | object | — | 후보별 시간 투표자 ID 맵; 익명은 빈 객체 |
| data.nextAppointment.placeVotes | object | — | 후보별 장소 투표자 ID 맵; 익명은 빈 객체 |
| data.nextAppointment.coverImageUrl | string | — | 대표 이미지 URL; 미설정 null |
| data.nextAppointment.cardText | string | — | 카드 문구; 미설정 null |
| data.nextAppointment.cardStyle | string | — | 프론트 카드 스타일 식별자; 미설정 null |
| data.secondsUntilNext | integer(int64) | — | 다음 확정 약속까지 초; 없으면 null |
| data.totalCount | integer(int64) | — | 목록은 필터 적용 결과 수, 도착 현황은 참여자 수 |
| data.upcomingCount | integer(int64) | — | 검색·필터 전 미완료 약속 수 |
| data.completedCount | integer(int64) | — | 검색·필터 전 완료 약속 수 |
| data.page | integer(int32) | — | 요청한 페이지 번호 |
| data.size | integer(int32) | — | 목록의 페이지 크기 또는 업로드 저장 바이트 수 |
| data.items | object[] | — | 결과 목록 |
| data.items[].id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data.items[].roomId | string | — | 방 ID; 지도 응답에서는 호환상 약속 ID |
| data.items[].name | string | — | 이름 |
| data.items[].template | string | — | 허용: ALL, TIME_ONLY, PLACE_ONLY, BOTH |
| data.items[].candidatesTime | object[] | — | 시간 후보 목록 |
| data.items[].candidatesTime[].candidateId | string | — | 서버 발급 후보 UUID |
| data.items[].candidatesTime[].time | string(date-time) | — | 후보 시각(KST 응답) |
| data.items[].confirmedTime | string(date-time) | — | 확정 약속 시각(KST); 미확정 null |
| data.items[].candidatesPlace | object[] | — | 장소 후보 목록 |
| data.items[].candidatesPlace[].candidateId | string | — | 서버 발급 후보 UUID |
| data.items[].candidatesPlace[].place | object | — | 장소 정보 |
| data.items[].candidatesPlace[].place.name | string | — | 이름 |
| data.items[].candidatesPlace[].place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.items[].candidatesPlace[].place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.items[].candidatesPlace[].place.address | string | — | 주소; 없으면 null |
| data.items[].candidatesPlace[].place.category | string | — | 장소 분류; 없으면 null |
| data.items[].candidatesPlace[].place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.items[].candidatesPlace[].place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.items[].candidatesPlace[].place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.items[].confirmedPlace | object | — | 확정 장소; 미확정 null |
| data.items[].confirmedPlace.name | string | — | 이름 |
| data.items[].confirmedPlace.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.items[].confirmedPlace.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.items[].confirmedPlace.address | string | — | 주소; 없으면 null |
| data.items[].confirmedPlace.category | string | — | 장소 분류; 없으면 null |
| data.items[].confirmedPlace.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.items[].confirmedPlace.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.items[].confirmedPlace.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.items[].penalty | object | — | 벌칙 설정; 없으면 null |
| data.items[].penalty.description | string | — | 설명 |
| data.items[].penalty.lateThresholdMin | string | — | 허용: FIVE, TEN, FIFTEEN |
| data.items[].penalty.target | string | — | 허용: ALL_LATE |
| data.items[].reward | object | — | 기존 약속 보상; 투표별 선물과 별개 |
| data.items[].reward.description | string | — | 설명 |
| data.items[].locationSharing | object | — | 약속 위치 공유 시간 정책 |
| data.items[].locationSharing.startMinutesBefore | integer(int32) | — | 약속 이전 공유 가능 분 |
| data.items[].locationSharing.maxMinutesAfter | integer(int32) | — | 약속 이후 공유 가능 분 |
| data.items[].status | string | — | 허용: COORDINATING, CONFIRMED, COMPLETED |
| data.items[].shareUrl | string | — | 초대 공유 링크 |
| data.items[].createdAt | string(date-time) | — | 생성 시각(UTC) |
| data.items[].hostId | string | — | 약속 호스트 사용자 ID |
| data.items[].inviteCode | string | — | 초대 코드 |
| data.items[].members | object[] | — | 약속 멤버 목록 |
| data.items[].members[].userId | string | — | 사용자 ID |
| data.items[].members[].name | string | — | 이름 |
| data.items[].members[].role | string | — | 허용: HOST, MEMBER |
| data.items[].members[].joinedAt | string(date-time) | — | 가입 시각(UTC) |
| data.items[].members[].avatarUrl | string | — | 프로필 이미지 URL; 미설정 null |
| data.items[].timeVotes | object | — | 후보별 시간 투표자 ID 맵; 익명은 빈 객체 |
| data.items[].placeVotes | object | — | 후보별 장소 투표자 ID 맵; 익명은 빈 객체 |
| data.items[].coverImageUrl | string | — | 대표 이미지 URL; 미설정 null |
| data.items[].cardText | string | — | 카드 문구; 미설정 null |
| data.items[].cardStyle | string | — | 프론트 카드 스타일 식별자; 미설정 null |

### 동작 규칙·주의사항

홈과 동일한 검색·필터·정렬·페이지 규칙을 사용합니다. page ≥ 0, size 1~100, query 최대 100자. nextAppointment는 미래 확정 약속 중 가장 가까운 항목이며 없으면 null입니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 403 | ROOM_ACCESS_DENIED | 해당 방 접근 권한 또는 소유자 권한 없음 |
| 404 | ROOM_NOT_FOUND | 방 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 모임 정보 수정

### 동작 설명

`PATCH /api/v1/rooms/{id}`

모임 이름과 대표 이미지를 수정합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **방 소유자**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |

Content-Type: `application/json`.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| name | string | 필수 | 최대 50자 |
| coverImageUrl | string | 선택 | 최대 2048자; 패턴: https?://[^\s]+ |

요청 형식 예시(실제 ID·시각·URL로 교체):

```json
{
  "name": "성수 모임",
  "coverImageUrl": "https://api.example.com/example.png"
}
```

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data.name | string | — | 이름 |
| data.ownerId | string | — | 방 소유자 사용자 ID |
| data.memberCount | integer(int64) | — | 방 멤버 수 |
| data.createdAt | string(date-time) | — | 생성 시각(UTC) |
| data.coverImageUrl | string | — | 대표 이미지 URL; 미설정 null |

### 동작 규칙·주의사항

name은 필수, 공백 불가·최대 50자. coverImageUrl 생략/null은 기존 값을 유지합니다. URL 최대 2048자, http(s). 서버 이미지 URL은 접근 권한을 검사합니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 403 | ROOM_ACCESS_DENIED | 해당 방 접근 권한 또는 소유자 권한 없음 |
| 404 | ROOM_NOT_FOUND | 방 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 모임 멤버 조회

### 동작 설명

`GET /api/v1/rooms/{id}/members`

모임 전체 멤버와 소유자 여부·아바타를 조회합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **해당 방 멤버**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object[] | — | 응답 데이터; 반환값이 없으면 null |
| data[].id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data[].name | string | — | 이름 |
| data[].owner | boolean | — | 방 소유자 여부 |
| data[].avatarUrl | string | — | 프로필 이미지 URL; 미설정 null |

### 동작 규칙·주의사항

약속 투표 참여자 목록과 다릅니다. id는 사용자 ID입니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 403 | ROOM_ACCESS_DENIED | 해당 방 접근 권한 또는 소유자 권한 없음 |
| 404 | ROOM_NOT_FOUND | 방 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 모임 초대 조회

### 동작 설명

`GET /api/v1/rooms/{id}/invite`

방 초대 코드와 링크를 조회하고, 코드가 없으면 처음 발급합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **해당 방 멤버**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.roomId | string | — | 방 ID; 지도 응답에서는 호환상 약속 ID |
| data.inviteCode | string | — | 초대 코드 |
| data.shareUrl | string | — | 초대 공유 링크 |

### 동작 규칙·주의사항

shareUrl은 설정된 공유 주소 + /rooms/invite/{inviteCode}입니다. 최초 조회에는 코드 생성 부수 효과가 있습니다. 기존 약속 초대 코드와 다릅니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 403 | ROOM_ACCESS_DENIED | 해당 방 접근 권한 또는 소유자 권한 없음 |
| 404 | ROOM_NOT_FOUND | 방 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 모임 초대 코드 재발급

### 동작 설명

`POST /api/v1/rooms/{id}/invite/rotate`

기존 방 초대 코드를 폐기하고 새 코드를 발급합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **방 소유자**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.roomId | string | — | 방 ID; 지도 응답에서는 호환상 약속 ID |
| data.inviteCode | string | — | 초대 코드 |
| data.shareUrl | string | — | 초대 공유 링크 |

### 동작 규칙·주의사항

재요청할 때마다 새 코드가 생성됩니다. 이전 링크로 가입하면 INVALID_INVITE_CODE입니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 403 | ROOM_ACCESS_DENIED | 해당 방 접근 권한 또는 소유자 권한 없음 |
| 404 | ROOM_NOT_FOUND | 방 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 초대 코드로 모임 가입

### 동작 설명

`POST /api/v1/rooms/join`

방 초대 코드로 방 멤버를 등록합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **인증 사용자**.

### Request

Content-Type: `application/json`.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| inviteCode | string | 필수 | 최대 36자 |

요청 형식 예시(실제 ID·시각·URL로 교체):

```json
{
  "inviteCode": "11111111-1111-4111-8111-111111111111"
}
```

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data.name | string | — | 이름 |
| data.ownerId | string | — | 방 소유자 사용자 ID |
| data.memberCount | integer(int64) | — | 방 멤버 수 |
| data.createdAt | string(date-time) | — | 생성 시각(UTC) |
| data.coverImageUrl | string | — | 대표 이미지 URL; 미설정 null |

### 동작 규칙·주의사항

inviteCode는 필수·최대 36자이며 앞뒤 공백을 제거합니다. 이미 가입했으면 성공 응답을 반환하며 중복 등록하지 않습니다. 약속 투표 참여는 별도입니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | INVALID_INVITE_CODE / USER_NOT_FOUND | 잘못된 코드 또는 사용자 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 이미지 업로드

### 동작 설명

`POST /api/v1/media`

PNG/JPEG 이미지를 업로드합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **인증 사용자**.

### Request

Content-Type: `multipart/form-data`.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| file | string(binary) | 필수 | PNG/JPEG 파일 |

### Response

성공 **HTTP 201**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data.url | string | — | 저장 이미지 URL(Bearer 인증 필요) |
| data.contentType | string | — | 저장 이미지 MIME 타입 |
| data.size | integer(int64) | — | 목록의 페이지 크기 또는 업로드 저장 바이트 수 |

### 동작 규칙·주의사항

multipart/form-data의 file 파트가 필수입니다. 최대 5MB, 한 변 8192px, 총 1600만 픽셀. 디코딩·재인코딩 후 저장하므로 응답 size는 저장된 바이트 수입니다. MEDIA_BASE_URL을 클라이언트 접근 가능한 주소로 설정해야 합니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | NOT_FOUND | 리소스 없음 또는 접근 권한 없음 |
| 413 | PAYLOAD_TOO_LARGE | multipart 업로드 크기 초과 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 이미지 다운로드

### 동작 설명

`GET /api/v1/media/{id}`

저장된 이미지 바이너리를 반환합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **업로더 또는 연결된 방·약속에 접근 가능한 사용자**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

이미지 바이너리를 반환합니다. 성공 JSON 래퍼는 없습니다.

### 동작 규칙·주의사항

Bearer 인증이 필요합니다. Content-Type은 image/png 또는 image/jpeg, Cache-Control은 no-store입니다. 비공개·없는 이미지 모두 404 NOT_FOUND. JSON 응답 래퍼를 사용하지 않습니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | NOT_FOUND | 리소스 없음 또는 접근 권한 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 약속 카드 꾸미기

### 동작 설명

`PUT /api/v1/appointments/{id}/appearance`

약속 커버·카드 문구·스타일을 교체합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **해당 방 멤버인 약속 호스트**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |

Content-Type: `application/json`.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| coverImageUrl | string | 선택 | 최대 2048자; 패턴: https?://[^\s]+ |
| cardText | string | 선택 | 최대 1000자 |
| cardStyle | string | 선택 | 최대 30자 |

요청 형식 예시(실제 ID·시각·URL로 교체):

```json
{
  "coverImageUrl": "https://api.example.com/example.png",
  "cardText": "",
  "cardStyle": ""
}
```

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data.roomId | string | — | 방 ID; 지도 응답에서는 호환상 약속 ID |
| data.name | string | — | 이름 |
| data.template | string | — | 허용: ALL, TIME_ONLY, PLACE_ONLY, BOTH |
| data.candidatesTime | object[] | — | 시간 후보 목록 |
| data.candidatesTime[].candidateId | string | — | 서버 발급 후보 UUID |
| data.candidatesTime[].time | string(date-time) | — | 후보 시각(KST 응답) |
| data.confirmedTime | string(date-time) | — | 확정 약속 시각(KST); 미확정 null |
| data.candidatesPlace | object[] | — | 장소 후보 목록 |
| data.candidatesPlace[].candidateId | string | — | 서버 발급 후보 UUID |
| data.candidatesPlace[].place | object | — | 장소 정보 |
| data.candidatesPlace[].place.name | string | — | 이름 |
| data.candidatesPlace[].place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.candidatesPlace[].place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.candidatesPlace[].place.address | string | — | 주소; 없으면 null |
| data.candidatesPlace[].place.category | string | — | 장소 분류; 없으면 null |
| data.candidatesPlace[].place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.candidatesPlace[].place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.candidatesPlace[].place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.confirmedPlace | object | — | 확정 장소; 미확정 null |
| data.confirmedPlace.name | string | — | 이름 |
| data.confirmedPlace.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.confirmedPlace.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.confirmedPlace.address | string | — | 주소; 없으면 null |
| data.confirmedPlace.category | string | — | 장소 분류; 없으면 null |
| data.confirmedPlace.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.confirmedPlace.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.confirmedPlace.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.penalty | object | — | 벌칙 설정; 없으면 null |
| data.penalty.description | string | — | 설명 |
| data.penalty.lateThresholdMin | string | — | 허용: FIVE, TEN, FIFTEEN |
| data.penalty.target | string | — | 허용: ALL_LATE |
| data.reward | object | — | 기존 약속 보상; 투표별 선물과 별개 |
| data.reward.description | string | — | 설명 |
| data.locationSharing | object | — | 약속 위치 공유 시간 정책 |
| data.locationSharing.startMinutesBefore | integer(int32) | — | 약속 이전 공유 가능 분 |
| data.locationSharing.maxMinutesAfter | integer(int32) | — | 약속 이후 공유 가능 분 |
| data.status | string | — | 허용: COORDINATING, CONFIRMED, COMPLETED |
| data.shareUrl | string | — | 초대 공유 링크 |
| data.createdAt | string(date-time) | — | 생성 시각(UTC) |
| data.hostId | string | — | 약속 호스트 사용자 ID |
| data.inviteCode | string | — | 초대 코드 |
| data.members | object[] | — | 약속 멤버 목록 |
| data.members[].userId | string | — | 사용자 ID |
| data.members[].name | string | — | 이름 |
| data.members[].role | string | — | 허용: HOST, MEMBER |
| data.members[].joinedAt | string(date-time) | — | 가입 시각(UTC) |
| data.members[].avatarUrl | string | — | 프로필 이미지 URL; 미설정 null |
| data.timeVotes | object | — | 후보별 시간 투표자 ID 맵; 익명은 빈 객체 |
| data.placeVotes | object | — | 후보별 장소 투표자 ID 맵; 익명은 빈 객체 |
| data.coverImageUrl | string | — | 대표 이미지 URL; 미설정 null |
| data.cardText | string | — | 카드 문구; 미설정 null |
| data.cardStyle | string | — | 프론트 카드 스타일 식별자; 미설정 null |

### 동작 규칙·주의사항

전체 교체입니다. 생략/null은 해당 값을 지웁니다. coverImageUrl 최대 2048자 http(s), cardText 최대 1000자, cardStyle 최대 30자의 프론트 스타일 식별자. 서버 이미지 연결 권한을 검사합니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | APPOINTMENT_NOT_FOUND | 약속 없음 |
| 403 | ROOM_ACCESS_DENIED / APPOINTMENT_ACCESS_DENIED / APPOINTMENT_HOST_ONLY | 해당 API에 필요한 방·약속·호스트 권한 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 시간·장소 투표 설정

### 동작 설명

`PUT /api/v1/appointments/{id}/polls/{type}`

해당 종류의 투표 옵션과 마감 시간을 저장합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **해당 방 멤버인 약속 호스트**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |
| type | path | string | 필수 | "" TIME, PLACE |

Content-Type: `application/json`.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| multipleSelection | boolean | 필수 | 복수선택 허용 여부 |
| anonymous | boolean | 필수 | 익명 투표 여부 |
| allowAddingOptions | boolean | 필수 | 일반 참여자의 후보 추가 허용 여부 |
| durationMinutes | integer(int32) | 필수 | 투표 진행 분 |
| giftDescription | string | 선택 | 최대 100자 |
| giftMethod | string | 선택 | 허용: RANDOM, FIRST_COME |
| winnerCount | integer(int32) | 선택 | 최소 1; 최대 100 |

요청 형식 예시(실제 ID·시각·URL로 교체):

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

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.appointmentId | string | — | 약속 ID |
| data.roomId | string | — | 방 ID; 지도 응답에서는 호환상 약속 ID |
| data.status | string | — | 허용: COORDINATING, CONFIRMED, COMPLETED |
| data.participating | boolean | — | 내 약속 참여 여부 |
| data.participantIds | string[] | — | 약속 참여 사용자 ID 목록 |
| data.participatingRegardless | boolean | — | 내 상관없음 선택 |
| data.regardlessParticipantIds | string[] | — | 상관없음 선택 사용자 ID 목록 |
| data.timeOptions | object[] | — | 시간 후보와 득표 현황 |
| data.timeOptions[].candidateId | string | — | 서버 발급 후보 UUID |
| data.timeOptions[].time | string(date-time) | — | 후보 시각(KST 응답) |
| data.timeOptions[].voteCount | integer(int32) | — | 후보 득표 수 |
| data.timeOptions[].voterIds | string[] | — | 투표자 ID 목록; 익명 투표는 빈 배열 |
| data.timeOptions[].votedByMe | boolean | — | 내가 선택한 후보인지 |
| data.placeOptions | object[] | — | 장소 후보와 득표 현황 |
| data.placeOptions[].candidateId | string | — | 서버 발급 후보 UUID |
| data.placeOptions[].place | object | — | 장소 정보 |
| data.placeOptions[].place.name | string | — | 이름 |
| data.placeOptions[].place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.placeOptions[].place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.placeOptions[].place.address | string | — | 주소; 없으면 null |
| data.placeOptions[].place.category | string | — | 장소 분류; 없으면 null |
| data.placeOptions[].place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.placeOptions[].place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.placeOptions[].place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.placeOptions[].voteCount | integer(int32) | — | 후보 득표 수 |
| data.placeOptions[].voterIds | string[] | — | 투표자 ID 목록; 익명 투표는 빈 배열 |
| data.placeOptions[].votedByMe | boolean | — | 내가 선택한 후보인지 |
| data.timePoll | object | — | 시간 투표 설정 |
| data.timePoll.multipleSelection | boolean | — | 복수선택 허용 여부 |
| data.timePoll.anonymous | boolean | — | 익명 투표 여부 |
| data.timePoll.allowAddingOptions | boolean | — | 일반 참여자의 후보 추가 허용 여부 |
| data.timePoll.state | string | — | 투표는 EMPTY/OPEN/CLOSED/CONFIRMED, 이동은 NOT_DEPARTED/EN_ROUTE/ARRIVED |
| data.timePoll.startedAt | string(date-time) | — | 투표 시작 시각(UTC); 미설정 null |
| data.timePoll.endsAt | string(date-time) | — | 투표 마감 시각(UTC); 기한 없으면 null |
| data.timePoll.giftDescription | string | — | 선물 설명; 선물 없으면 null |
| data.timePoll.giftMethod | string | — | 허용: RANDOM, FIRST_COME |
| data.timePoll.winnerCount | integer(int32) | — | 당첨 인원; 미설정 null |
| data.timePoll.winnerIds | string[] | — | 당첨 사용자 ID 목록; 미선정 빈 배열 |
| data.placePoll | object | — | 장소 투표 설정 |
| data.placePoll.multipleSelection | boolean | — | 복수선택 허용 여부 |
| data.placePoll.anonymous | boolean | — | 익명 투표 여부 |
| data.placePoll.allowAddingOptions | boolean | — | 일반 참여자의 후보 추가 허용 여부 |
| data.placePoll.state | string | — | 투표는 EMPTY/OPEN/CLOSED/CONFIRMED, 이동은 NOT_DEPARTED/EN_ROUTE/ARRIVED |
| data.placePoll.startedAt | string(date-time) | — | 투표 시작 시각(UTC); 미설정 null |
| data.placePoll.endsAt | string(date-time) | — | 투표 마감 시각(UTC); 기한 없으면 null |
| data.placePoll.giftDescription | string | — | 선물 설명; 선물 없으면 null |
| data.placePoll.giftMethod | string | — | 허용: RANDOM, FIRST_COME |
| data.placePoll.winnerCount | integer(int32) | — | 당첨 인원; 미설정 null |
| data.placePoll.winnerIds | string[] | — | 당첨 사용자 ID 목록; 미선정 빈 배열 |

### 동작 규칙·주의사항

type은 TIME 또는 PLACE. durationMinutes는 30,60,240,480,1440,4320,10080,20160 중 하나입니다. 세 boolean과 durationMinutes는 필수. 선물 세 필드는 모두 생략하거나 함께 전달하며 description은 공백 불가·최대 100자, winnerCount는 1~100입니다. 해당 종류에 표가 있으면 409 POLL_HAS_VOTES. 저장 시각부터 마감 시간을 계산합니다. 설정 없는 기존 투표는 복수선택·후보추가 허용/비익명/기한 없음. 새 화면 기본값은 false,false,true,30을 명시적으로 전송합니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | APPOINTMENT_NOT_FOUND | 약속 없음 |
| 403 | ROOM_ACCESS_DENIED / APPOINTMENT_ACCESS_DENIED / APPOINTMENT_HOST_ONLY | 해당 API에 필요한 방·약속·호스트 권한 없음 |
| 409 | POLL_CLOSED / NOT_COORDINATING | 마감 또는 조율 중이 아닌 약속 |
| 400 | VOTE_NOT_ALLOWED / INVALID_OPTION | 조율 대상이 아니거나 확정됨 또는 없는 후보 |
| 409 | POLL_HAS_VOTES | 해당 종류의 투표가 이미 존재 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 시간·장소 투표 종료

### 동작 설명

`POST /api/v1/appointments/{id}/polls/{type}/close`

해당 종류의 투표를 조기 종료합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **해당 방 멤버인 약속 호스트**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |
| type | path | string | 필수 | "" TIME, PLACE |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.appointmentId | string | — | 약속 ID |
| data.roomId | string | — | 방 ID; 지도 응답에서는 호환상 약속 ID |
| data.status | string | — | 허용: COORDINATING, CONFIRMED, COMPLETED |
| data.participating | boolean | — | 내 약속 참여 여부 |
| data.participantIds | string[] | — | 약속 참여 사용자 ID 목록 |
| data.participatingRegardless | boolean | — | 내 상관없음 선택 |
| data.regardlessParticipantIds | string[] | — | 상관없음 선택 사용자 ID 목록 |
| data.timeOptions | object[] | — | 시간 후보와 득표 현황 |
| data.timeOptions[].candidateId | string | — | 서버 발급 후보 UUID |
| data.timeOptions[].time | string(date-time) | — | 후보 시각(KST 응답) |
| data.timeOptions[].voteCount | integer(int32) | — | 후보 득표 수 |
| data.timeOptions[].voterIds | string[] | — | 투표자 ID 목록; 익명 투표는 빈 배열 |
| data.timeOptions[].votedByMe | boolean | — | 내가 선택한 후보인지 |
| data.placeOptions | object[] | — | 장소 후보와 득표 현황 |
| data.placeOptions[].candidateId | string | — | 서버 발급 후보 UUID |
| data.placeOptions[].place | object | — | 장소 정보 |
| data.placeOptions[].place.name | string | — | 이름 |
| data.placeOptions[].place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.placeOptions[].place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.placeOptions[].place.address | string | — | 주소; 없으면 null |
| data.placeOptions[].place.category | string | — | 장소 분류; 없으면 null |
| data.placeOptions[].place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.placeOptions[].place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.placeOptions[].place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.placeOptions[].voteCount | integer(int32) | — | 후보 득표 수 |
| data.placeOptions[].voterIds | string[] | — | 투표자 ID 목록; 익명 투표는 빈 배열 |
| data.placeOptions[].votedByMe | boolean | — | 내가 선택한 후보인지 |
| data.timePoll | object | — | 시간 투표 설정 |
| data.timePoll.multipleSelection | boolean | — | 복수선택 허용 여부 |
| data.timePoll.anonymous | boolean | — | 익명 투표 여부 |
| data.timePoll.allowAddingOptions | boolean | — | 일반 참여자의 후보 추가 허용 여부 |
| data.timePoll.state | string | — | 투표는 EMPTY/OPEN/CLOSED/CONFIRMED, 이동은 NOT_DEPARTED/EN_ROUTE/ARRIVED |
| data.timePoll.startedAt | string(date-time) | — | 투표 시작 시각(UTC); 미설정 null |
| data.timePoll.endsAt | string(date-time) | — | 투표 마감 시각(UTC); 기한 없으면 null |
| data.timePoll.giftDescription | string | — | 선물 설명; 선물 없으면 null |
| data.timePoll.giftMethod | string | — | 허용: RANDOM, FIRST_COME |
| data.timePoll.winnerCount | integer(int32) | — | 당첨 인원; 미설정 null |
| data.timePoll.winnerIds | string[] | — | 당첨 사용자 ID 목록; 미선정 빈 배열 |
| data.placePoll | object | — | 장소 투표 설정 |
| data.placePoll.multipleSelection | boolean | — | 복수선택 허용 여부 |
| data.placePoll.anonymous | boolean | — | 익명 투표 여부 |
| data.placePoll.allowAddingOptions | boolean | — | 일반 참여자의 후보 추가 허용 여부 |
| data.placePoll.state | string | — | 투표는 EMPTY/OPEN/CLOSED/CONFIRMED, 이동은 NOT_DEPARTED/EN_ROUTE/ARRIVED |
| data.placePoll.startedAt | string(date-time) | — | 투표 시작 시각(UTC); 미설정 null |
| data.placePoll.endsAt | string(date-time) | — | 투표 마감 시각(UTC); 기한 없으면 null |
| data.placePoll.giftDescription | string | — | 선물 설명; 선물 없으면 null |
| data.placePoll.giftMethod | string | — | 허용: RANDOM, FIRST_COME |
| data.placePoll.winnerCount | integer(int32) | — | 당첨 인원; 미설정 null |
| data.placePoll.winnerIds | string[] | — | 당첨 사용자 ID 목록; 미선정 빈 배열 |

### 동작 규칙·주의사항

TIME과 PLACE는 독립적입니다. 종료는 확정이 아니며 호스트가 confirm API로 후보를 선택해야 합니다. 이미 종료한 종류도 조율 중·미확정이면 재호출할 수 있습니다. 전체 약속이 확정/완료면 409 NOT_COORDINATING입니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | APPOINTMENT_NOT_FOUND | 약속 없음 |
| 403 | ROOM_ACCESS_DENIED / APPOINTMENT_ACCESS_DENIED / APPOINTMENT_HOST_ONLY | 해당 API에 필요한 방·약속·호스트 권한 없음 |
| 409 | NOT_COORDINATING | 약속이 조율 중이 아님 |
| 400 | VOTE_NOT_ALLOWED | 조율 대상이 아니거나 이미 확정됨 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 투표 선물 당첨자 선정

### 동작 설명

`POST /api/v1/appointments/{id}/polls/{type}/gift/draw`

종료 또는 개별 확정된 투표의 선물 당첨자를 선정합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **해당 방 멤버인 약속 호스트**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |
| type | path | string | 필수 | "" TIME, PLACE |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.appointmentId | string | — | 약속 ID |
| data.roomId | string | — | 방 ID; 지도 응답에서는 호환상 약속 ID |
| data.status | string | — | 허용: COORDINATING, CONFIRMED, COMPLETED |
| data.participating | boolean | — | 내 약속 참여 여부 |
| data.participantIds | string[] | — | 약속 참여 사용자 ID 목록 |
| data.participatingRegardless | boolean | — | 내 상관없음 선택 |
| data.regardlessParticipantIds | string[] | — | 상관없음 선택 사용자 ID 목록 |
| data.timeOptions | object[] | — | 시간 후보와 득표 현황 |
| data.timeOptions[].candidateId | string | — | 서버 발급 후보 UUID |
| data.timeOptions[].time | string(date-time) | — | 후보 시각(KST 응답) |
| data.timeOptions[].voteCount | integer(int32) | — | 후보 득표 수 |
| data.timeOptions[].voterIds | string[] | — | 투표자 ID 목록; 익명 투표는 빈 배열 |
| data.timeOptions[].votedByMe | boolean | — | 내가 선택한 후보인지 |
| data.placeOptions | object[] | — | 장소 후보와 득표 현황 |
| data.placeOptions[].candidateId | string | — | 서버 발급 후보 UUID |
| data.placeOptions[].place | object | — | 장소 정보 |
| data.placeOptions[].place.name | string | — | 이름 |
| data.placeOptions[].place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.placeOptions[].place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.placeOptions[].place.address | string | — | 주소; 없으면 null |
| data.placeOptions[].place.category | string | — | 장소 분류; 없으면 null |
| data.placeOptions[].place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.placeOptions[].place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.placeOptions[].place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.placeOptions[].voteCount | integer(int32) | — | 후보 득표 수 |
| data.placeOptions[].voterIds | string[] | — | 투표자 ID 목록; 익명 투표는 빈 배열 |
| data.placeOptions[].votedByMe | boolean | — | 내가 선택한 후보인지 |
| data.timePoll | object | — | 시간 투표 설정 |
| data.timePoll.multipleSelection | boolean | — | 복수선택 허용 여부 |
| data.timePoll.anonymous | boolean | — | 익명 투표 여부 |
| data.timePoll.allowAddingOptions | boolean | — | 일반 참여자의 후보 추가 허용 여부 |
| data.timePoll.state | string | — | 투표는 EMPTY/OPEN/CLOSED/CONFIRMED, 이동은 NOT_DEPARTED/EN_ROUTE/ARRIVED |
| data.timePoll.startedAt | string(date-time) | — | 투표 시작 시각(UTC); 미설정 null |
| data.timePoll.endsAt | string(date-time) | — | 투표 마감 시각(UTC); 기한 없으면 null |
| data.timePoll.giftDescription | string | — | 선물 설명; 선물 없으면 null |
| data.timePoll.giftMethod | string | — | 허용: RANDOM, FIRST_COME |
| data.timePoll.winnerCount | integer(int32) | — | 당첨 인원; 미설정 null |
| data.timePoll.winnerIds | string[] | — | 당첨 사용자 ID 목록; 미선정 빈 배열 |
| data.placePoll | object | — | 장소 투표 설정 |
| data.placePoll.multipleSelection | boolean | — | 복수선택 허용 여부 |
| data.placePoll.anonymous | boolean | — | 익명 투표 여부 |
| data.placePoll.allowAddingOptions | boolean | — | 일반 참여자의 후보 추가 허용 여부 |
| data.placePoll.state | string | — | 투표는 EMPTY/OPEN/CLOSED/CONFIRMED, 이동은 NOT_DEPARTED/EN_ROUTE/ARRIVED |
| data.placePoll.startedAt | string(date-time) | — | 투표 시작 시각(UTC); 미설정 null |
| data.placePoll.endsAt | string(date-time) | — | 투표 마감 시각(UTC); 기한 없으면 null |
| data.placePoll.giftDescription | string | — | 선물 설명; 선물 없으면 null |
| data.placePoll.giftMethod | string | — | 허용: RANDOM, FIRST_COME |
| data.placePoll.winnerCount | integer(int32) | — | 당첨 인원; 미설정 null |
| data.placePoll.winnerIds | string[] | — | 당첨 사용자 ID 목록; 미선정 빈 배열 |

### 동작 규칙·주의사항

선물 미설정 또는 열린 미확정 투표는 400 BAD_REQUEST. RANDOM은 현재 투표자별 동일 확률, FIRST_COME는 현재 남아 있는 최초 표 등록 순입니다. 취소·선택 변경은 우선순위를 잃고 동일 선택 재전송은 유지합니다. 당첨 인원은 현재 투표자 수를 넘지 않으며 재요청은 저장된 결과를 반환합니다. 결제·발송은 미포함.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | APPOINTMENT_NOT_FOUND | 약속 없음 |
| 403 | ROOM_ACCESS_DENIED / APPOINTMENT_ACCESS_DENIED / APPOINTMENT_HOST_ONLY | 해당 API에 필요한 방·약속·호스트 권한 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 시간 후보 수정

### 동작 설명

`PUT /api/v1/appointments/{id}/time-candidates/{candidateId}`

미확정·미마감 후보를 수정합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **해당 방 멤버인 약속 호스트**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |
| candidateId | path | string | 필수 | ""  |

Content-Type: `application/json`.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| time | string(date-time) | 필수 | 후보 시각(KST 응답) |

요청 형식 예시(실제 ID·시각·URL로 교체):

```json
{
  "time": "2030-01-01T18:00:00+09:00"
}
```

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.appointmentId | string | — | 약속 ID |
| data.roomId | string | — | 방 ID; 지도 응답에서는 호환상 약속 ID |
| data.status | string | — | 허용: COORDINATING, CONFIRMED, COMPLETED |
| data.participating | boolean | — | 내 약속 참여 여부 |
| data.participantIds | string[] | — | 약속 참여 사용자 ID 목록 |
| data.participatingRegardless | boolean | — | 내 상관없음 선택 |
| data.regardlessParticipantIds | string[] | — | 상관없음 선택 사용자 ID 목록 |
| data.timeOptions | object[] | — | 시간 후보와 득표 현황 |
| data.timeOptions[].candidateId | string | — | 서버 발급 후보 UUID |
| data.timeOptions[].time | string(date-time) | — | 후보 시각(KST 응답) |
| data.timeOptions[].voteCount | integer(int32) | — | 후보 득표 수 |
| data.timeOptions[].voterIds | string[] | — | 투표자 ID 목록; 익명 투표는 빈 배열 |
| data.timeOptions[].votedByMe | boolean | — | 내가 선택한 후보인지 |
| data.placeOptions | object[] | — | 장소 후보와 득표 현황 |
| data.placeOptions[].candidateId | string | — | 서버 발급 후보 UUID |
| data.placeOptions[].place | object | — | 장소 정보 |
| data.placeOptions[].place.name | string | — | 이름 |
| data.placeOptions[].place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.placeOptions[].place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.placeOptions[].place.address | string | — | 주소; 없으면 null |
| data.placeOptions[].place.category | string | — | 장소 분류; 없으면 null |
| data.placeOptions[].place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.placeOptions[].place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.placeOptions[].place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.placeOptions[].voteCount | integer(int32) | — | 후보 득표 수 |
| data.placeOptions[].voterIds | string[] | — | 투표자 ID 목록; 익명 투표는 빈 배열 |
| data.placeOptions[].votedByMe | boolean | — | 내가 선택한 후보인지 |
| data.timePoll | object | — | 시간 투표 설정 |
| data.timePoll.multipleSelection | boolean | — | 복수선택 허용 여부 |
| data.timePoll.anonymous | boolean | — | 익명 투표 여부 |
| data.timePoll.allowAddingOptions | boolean | — | 일반 참여자의 후보 추가 허용 여부 |
| data.timePoll.state | string | — | 투표는 EMPTY/OPEN/CLOSED/CONFIRMED, 이동은 NOT_DEPARTED/EN_ROUTE/ARRIVED |
| data.timePoll.startedAt | string(date-time) | — | 투표 시작 시각(UTC); 미설정 null |
| data.timePoll.endsAt | string(date-time) | — | 투표 마감 시각(UTC); 기한 없으면 null |
| data.timePoll.giftDescription | string | — | 선물 설명; 선물 없으면 null |
| data.timePoll.giftMethod | string | — | 허용: RANDOM, FIRST_COME |
| data.timePoll.winnerCount | integer(int32) | — | 당첨 인원; 미설정 null |
| data.timePoll.winnerIds | string[] | — | 당첨 사용자 ID 목록; 미선정 빈 배열 |
| data.placePoll | object | — | 장소 투표 설정 |
| data.placePoll.multipleSelection | boolean | — | 복수선택 허용 여부 |
| data.placePoll.anonymous | boolean | — | 익명 투표 여부 |
| data.placePoll.allowAddingOptions | boolean | — | 일반 참여자의 후보 추가 허용 여부 |
| data.placePoll.state | string | — | 투표는 EMPTY/OPEN/CLOSED/CONFIRMED, 이동은 NOT_DEPARTED/EN_ROUTE/ARRIVED |
| data.placePoll.startedAt | string(date-time) | — | 투표 시작 시각(UTC); 미설정 null |
| data.placePoll.endsAt | string(date-time) | — | 투표 마감 시각(UTC); 기한 없으면 null |
| data.placePoll.giftDescription | string | — | 선물 설명; 선물 없으면 null |
| data.placePoll.giftMethod | string | — | 허용: RANDOM, FIRST_COME |
| data.placePoll.winnerCount | integer(int32) | — | 당첨 인원; 미설정 null |
| data.placePoll.winnerIds | string[] | — | 당첨 사용자 ID 목록; 미선정 빈 배열 |

### 동작 규칙·주의사항

candidateId는 서버 발급 후보 UUID. 실제 변경 시 해당 후보의 표만 제거하고 다른 후보의 표는 유지합니다. 동일 값이면 유지합니다. 다른 표·상관없음이 없는 일반 참여자는 참여 해제됩니다. time은 미래 ISO 8601 오프셋 시각입니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | APPOINTMENT_NOT_FOUND | 약속 없음 |
| 403 | ROOM_ACCESS_DENIED / APPOINTMENT_ACCESS_DENIED / APPOINTMENT_HOST_ONLY | 해당 API에 필요한 방·약속·호스트 권한 없음 |
| 409 | POLL_CLOSED / NOT_COORDINATING | 마감 또는 조율 중이 아닌 약속 |
| 400 | VOTE_NOT_ALLOWED / INVALID_OPTION | 조율 대상이 아니거나 확정됨 또는 없는 후보 |
| 409 | DUPLICATE_CANDIDATE | 중복 후보 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 시간 후보 삭제

### 동작 설명

`DELETE /api/v1/appointments/{id}/time-candidates/{candidateId}`

미확정·미마감 후보를 삭제합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **해당 방 멤버인 약속 호스트**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |
| candidateId | path | string | 필수 | ""  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.appointmentId | string | — | 약속 ID |
| data.roomId | string | — | 방 ID; 지도 응답에서는 호환상 약속 ID |
| data.status | string | — | 허용: COORDINATING, CONFIRMED, COMPLETED |
| data.participating | boolean | — | 내 약속 참여 여부 |
| data.participantIds | string[] | — | 약속 참여 사용자 ID 목록 |
| data.participatingRegardless | boolean | — | 내 상관없음 선택 |
| data.regardlessParticipantIds | string[] | — | 상관없음 선택 사용자 ID 목록 |
| data.timeOptions | object[] | — | 시간 후보와 득표 현황 |
| data.timeOptions[].candidateId | string | — | 서버 발급 후보 UUID |
| data.timeOptions[].time | string(date-time) | — | 후보 시각(KST 응답) |
| data.timeOptions[].voteCount | integer(int32) | — | 후보 득표 수 |
| data.timeOptions[].voterIds | string[] | — | 투표자 ID 목록; 익명 투표는 빈 배열 |
| data.timeOptions[].votedByMe | boolean | — | 내가 선택한 후보인지 |
| data.placeOptions | object[] | — | 장소 후보와 득표 현황 |
| data.placeOptions[].candidateId | string | — | 서버 발급 후보 UUID |
| data.placeOptions[].place | object | — | 장소 정보 |
| data.placeOptions[].place.name | string | — | 이름 |
| data.placeOptions[].place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.placeOptions[].place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.placeOptions[].place.address | string | — | 주소; 없으면 null |
| data.placeOptions[].place.category | string | — | 장소 분류; 없으면 null |
| data.placeOptions[].place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.placeOptions[].place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.placeOptions[].place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.placeOptions[].voteCount | integer(int32) | — | 후보 득표 수 |
| data.placeOptions[].voterIds | string[] | — | 투표자 ID 목록; 익명 투표는 빈 배열 |
| data.placeOptions[].votedByMe | boolean | — | 내가 선택한 후보인지 |
| data.timePoll | object | — | 시간 투표 설정 |
| data.timePoll.multipleSelection | boolean | — | 복수선택 허용 여부 |
| data.timePoll.anonymous | boolean | — | 익명 투표 여부 |
| data.timePoll.allowAddingOptions | boolean | — | 일반 참여자의 후보 추가 허용 여부 |
| data.timePoll.state | string | — | 투표는 EMPTY/OPEN/CLOSED/CONFIRMED, 이동은 NOT_DEPARTED/EN_ROUTE/ARRIVED |
| data.timePoll.startedAt | string(date-time) | — | 투표 시작 시각(UTC); 미설정 null |
| data.timePoll.endsAt | string(date-time) | — | 투표 마감 시각(UTC); 기한 없으면 null |
| data.timePoll.giftDescription | string | — | 선물 설명; 선물 없으면 null |
| data.timePoll.giftMethod | string | — | 허용: RANDOM, FIRST_COME |
| data.timePoll.winnerCount | integer(int32) | — | 당첨 인원; 미설정 null |
| data.timePoll.winnerIds | string[] | — | 당첨 사용자 ID 목록; 미선정 빈 배열 |
| data.placePoll | object | — | 장소 투표 설정 |
| data.placePoll.multipleSelection | boolean | — | 복수선택 허용 여부 |
| data.placePoll.anonymous | boolean | — | 익명 투표 여부 |
| data.placePoll.allowAddingOptions | boolean | — | 일반 참여자의 후보 추가 허용 여부 |
| data.placePoll.state | string | — | 투표는 EMPTY/OPEN/CLOSED/CONFIRMED, 이동은 NOT_DEPARTED/EN_ROUTE/ARRIVED |
| data.placePoll.startedAt | string(date-time) | — | 투표 시작 시각(UTC); 미설정 null |
| data.placePoll.endsAt | string(date-time) | — | 투표 마감 시각(UTC); 기한 없으면 null |
| data.placePoll.giftDescription | string | — | 선물 설명; 선물 없으면 null |
| data.placePoll.giftMethod | string | — | 허용: RANDOM, FIRST_COME |
| data.placePoll.winnerCount | integer(int32) | — | 당첨 인원; 미설정 null |
| data.placePoll.winnerIds | string[] | — | 당첨 사용자 ID 목록; 미선정 빈 배열 |

### 동작 규칙·주의사항

해당 후보의 표도 삭제합니다. 마지막 표와 상관없음 선택을 모두 잃은 일반 참여자는 참여 해제됩니다. 호스트는 멤버로 유지합니다. 이미 삭제한 ID 재요청은 INVALID_OPTION입니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | APPOINTMENT_NOT_FOUND | 약속 없음 |
| 403 | ROOM_ACCESS_DENIED / APPOINTMENT_ACCESS_DENIED / APPOINTMENT_HOST_ONLY | 해당 API에 필요한 방·약속·호스트 권한 없음 |
| 409 | POLL_CLOSED / NOT_COORDINATING | 마감 또는 조율 중이 아닌 약속 |
| 400 | VOTE_NOT_ALLOWED / INVALID_OPTION | 조율 대상이 아니거나 확정됨 또는 없는 후보 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 장소 후보 수정

### 동작 설명

`PUT /api/v1/appointments/{id}/place-candidates/{candidateId}`

미확정·미마감 후보를 수정합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **해당 방 멤버인 약속 호스트**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |
| candidateId | path | string | 필수 | ""  |

Content-Type: `application/json`.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| name | string | 필수 | 최대 100자 |
| latitude | number(double) | 선택 | 최소 -90; 최대 90 |
| longitude | number(double) | 선택 | 최소 -180; 최대 180 |
| address | string | 선택 | 최대 500자 |
| category | string | 선택 | 최대 100자 |
| imageUrl | string | 선택 | 최대 2048자; 패턴: https?://[^\s]+ |
| providerId | string | 선택 | 최대 100자 |
| mapUrl | string | 선택 | 최대 2048자; 패턴: https?://[^\s]+ |

요청 형식 예시(실제 ID·시각·URL로 교체):

```json
{
  "name": "성수 모임",
  "latitude": 37.5444,
  "longitude": 127.0374,
  "address": "",
  "category": "",
  "imageUrl": "https://api.example.com/example.png",
  "providerId": "11111111-1111-4111-8111-111111111111",
  "mapUrl": "https://api.example.com/example.png"
}
```

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.appointmentId | string | — | 약속 ID |
| data.roomId | string | — | 방 ID; 지도 응답에서는 호환상 약속 ID |
| data.status | string | — | 허용: COORDINATING, CONFIRMED, COMPLETED |
| data.participating | boolean | — | 내 약속 참여 여부 |
| data.participantIds | string[] | — | 약속 참여 사용자 ID 목록 |
| data.participatingRegardless | boolean | — | 내 상관없음 선택 |
| data.regardlessParticipantIds | string[] | — | 상관없음 선택 사용자 ID 목록 |
| data.timeOptions | object[] | — | 시간 후보와 득표 현황 |
| data.timeOptions[].candidateId | string | — | 서버 발급 후보 UUID |
| data.timeOptions[].time | string(date-time) | — | 후보 시각(KST 응답) |
| data.timeOptions[].voteCount | integer(int32) | — | 후보 득표 수 |
| data.timeOptions[].voterIds | string[] | — | 투표자 ID 목록; 익명 투표는 빈 배열 |
| data.timeOptions[].votedByMe | boolean | — | 내가 선택한 후보인지 |
| data.placeOptions | object[] | — | 장소 후보와 득표 현황 |
| data.placeOptions[].candidateId | string | — | 서버 발급 후보 UUID |
| data.placeOptions[].place | object | — | 장소 정보 |
| data.placeOptions[].place.name | string | — | 이름 |
| data.placeOptions[].place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.placeOptions[].place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.placeOptions[].place.address | string | — | 주소; 없으면 null |
| data.placeOptions[].place.category | string | — | 장소 분류; 없으면 null |
| data.placeOptions[].place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.placeOptions[].place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.placeOptions[].place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.placeOptions[].voteCount | integer(int32) | — | 후보 득표 수 |
| data.placeOptions[].voterIds | string[] | — | 투표자 ID 목록; 익명 투표는 빈 배열 |
| data.placeOptions[].votedByMe | boolean | — | 내가 선택한 후보인지 |
| data.timePoll | object | — | 시간 투표 설정 |
| data.timePoll.multipleSelection | boolean | — | 복수선택 허용 여부 |
| data.timePoll.anonymous | boolean | — | 익명 투표 여부 |
| data.timePoll.allowAddingOptions | boolean | — | 일반 참여자의 후보 추가 허용 여부 |
| data.timePoll.state | string | — | 투표는 EMPTY/OPEN/CLOSED/CONFIRMED, 이동은 NOT_DEPARTED/EN_ROUTE/ARRIVED |
| data.timePoll.startedAt | string(date-time) | — | 투표 시작 시각(UTC); 미설정 null |
| data.timePoll.endsAt | string(date-time) | — | 투표 마감 시각(UTC); 기한 없으면 null |
| data.timePoll.giftDescription | string | — | 선물 설명; 선물 없으면 null |
| data.timePoll.giftMethod | string | — | 허용: RANDOM, FIRST_COME |
| data.timePoll.winnerCount | integer(int32) | — | 당첨 인원; 미설정 null |
| data.timePoll.winnerIds | string[] | — | 당첨 사용자 ID 목록; 미선정 빈 배열 |
| data.placePoll | object | — | 장소 투표 설정 |
| data.placePoll.multipleSelection | boolean | — | 복수선택 허용 여부 |
| data.placePoll.anonymous | boolean | — | 익명 투표 여부 |
| data.placePoll.allowAddingOptions | boolean | — | 일반 참여자의 후보 추가 허용 여부 |
| data.placePoll.state | string | — | 투표는 EMPTY/OPEN/CLOSED/CONFIRMED, 이동은 NOT_DEPARTED/EN_ROUTE/ARRIVED |
| data.placePoll.startedAt | string(date-time) | — | 투표 시작 시각(UTC); 미설정 null |
| data.placePoll.endsAt | string(date-time) | — | 투표 마감 시각(UTC); 기한 없으면 null |
| data.placePoll.giftDescription | string | — | 선물 설명; 선물 없으면 null |
| data.placePoll.giftMethod | string | — | 허용: RANDOM, FIRST_COME |
| data.placePoll.winnerCount | integer(int32) | — | 당첨 인원; 미설정 null |
| data.placePoll.winnerIds | string[] | — | 당첨 사용자 ID 목록; 미선정 빈 배열 |

### 동작 규칙·주의사항

candidateId는 서버 발급 후보 UUID. 실제 변경 시 해당 후보의 표만 제거하고 다른 후보의 표는 유지합니다. 동일 값이면 유지합니다. 다른 표·상관없음이 없는 일반 참여자는 참여 해제됩니다. 장소 좌표는 둘 다 생략하거나 함께 전송합니다. name 필수·공백 불가. 이름(대소문자 무시)과 좌표가 같으면 중복입니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | APPOINTMENT_NOT_FOUND | 약속 없음 |
| 403 | ROOM_ACCESS_DENIED / APPOINTMENT_ACCESS_DENIED / APPOINTMENT_HOST_ONLY | 해당 API에 필요한 방·약속·호스트 권한 없음 |
| 409 | POLL_CLOSED / NOT_COORDINATING | 마감 또는 조율 중이 아닌 약속 |
| 400 | VOTE_NOT_ALLOWED / INVALID_OPTION | 조율 대상이 아니거나 확정됨 또는 없는 후보 |
| 409 | DUPLICATE_CANDIDATE | 중복 후보 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 장소 후보 삭제

### 동작 설명

`DELETE /api/v1/appointments/{id}/place-candidates/{candidateId}`

미확정·미마감 후보를 삭제합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **해당 방 멤버인 약속 호스트**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |
| candidateId | path | string | 필수 | ""  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.appointmentId | string | — | 약속 ID |
| data.roomId | string | — | 방 ID; 지도 응답에서는 호환상 약속 ID |
| data.status | string | — | 허용: COORDINATING, CONFIRMED, COMPLETED |
| data.participating | boolean | — | 내 약속 참여 여부 |
| data.participantIds | string[] | — | 약속 참여 사용자 ID 목록 |
| data.participatingRegardless | boolean | — | 내 상관없음 선택 |
| data.regardlessParticipantIds | string[] | — | 상관없음 선택 사용자 ID 목록 |
| data.timeOptions | object[] | — | 시간 후보와 득표 현황 |
| data.timeOptions[].candidateId | string | — | 서버 발급 후보 UUID |
| data.timeOptions[].time | string(date-time) | — | 후보 시각(KST 응답) |
| data.timeOptions[].voteCount | integer(int32) | — | 후보 득표 수 |
| data.timeOptions[].voterIds | string[] | — | 투표자 ID 목록; 익명 투표는 빈 배열 |
| data.timeOptions[].votedByMe | boolean | — | 내가 선택한 후보인지 |
| data.placeOptions | object[] | — | 장소 후보와 득표 현황 |
| data.placeOptions[].candidateId | string | — | 서버 발급 후보 UUID |
| data.placeOptions[].place | object | — | 장소 정보 |
| data.placeOptions[].place.name | string | — | 이름 |
| data.placeOptions[].place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.placeOptions[].place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.placeOptions[].place.address | string | — | 주소; 없으면 null |
| data.placeOptions[].place.category | string | — | 장소 분류; 없으면 null |
| data.placeOptions[].place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.placeOptions[].place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.placeOptions[].place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.placeOptions[].voteCount | integer(int32) | — | 후보 득표 수 |
| data.placeOptions[].voterIds | string[] | — | 투표자 ID 목록; 익명 투표는 빈 배열 |
| data.placeOptions[].votedByMe | boolean | — | 내가 선택한 후보인지 |
| data.timePoll | object | — | 시간 투표 설정 |
| data.timePoll.multipleSelection | boolean | — | 복수선택 허용 여부 |
| data.timePoll.anonymous | boolean | — | 익명 투표 여부 |
| data.timePoll.allowAddingOptions | boolean | — | 일반 참여자의 후보 추가 허용 여부 |
| data.timePoll.state | string | — | 투표는 EMPTY/OPEN/CLOSED/CONFIRMED, 이동은 NOT_DEPARTED/EN_ROUTE/ARRIVED |
| data.timePoll.startedAt | string(date-time) | — | 투표 시작 시각(UTC); 미설정 null |
| data.timePoll.endsAt | string(date-time) | — | 투표 마감 시각(UTC); 기한 없으면 null |
| data.timePoll.giftDescription | string | — | 선물 설명; 선물 없으면 null |
| data.timePoll.giftMethod | string | — | 허용: RANDOM, FIRST_COME |
| data.timePoll.winnerCount | integer(int32) | — | 당첨 인원; 미설정 null |
| data.timePoll.winnerIds | string[] | — | 당첨 사용자 ID 목록; 미선정 빈 배열 |
| data.placePoll | object | — | 장소 투표 설정 |
| data.placePoll.multipleSelection | boolean | — | 복수선택 허용 여부 |
| data.placePoll.anonymous | boolean | — | 익명 투표 여부 |
| data.placePoll.allowAddingOptions | boolean | — | 일반 참여자의 후보 추가 허용 여부 |
| data.placePoll.state | string | — | 투표는 EMPTY/OPEN/CLOSED/CONFIRMED, 이동은 NOT_DEPARTED/EN_ROUTE/ARRIVED |
| data.placePoll.startedAt | string(date-time) | — | 투표 시작 시각(UTC); 미설정 null |
| data.placePoll.endsAt | string(date-time) | — | 투표 마감 시각(UTC); 기한 없으면 null |
| data.placePoll.giftDescription | string | — | 선물 설명; 선물 없으면 null |
| data.placePoll.giftMethod | string | — | 허용: RANDOM, FIRST_COME |
| data.placePoll.winnerCount | integer(int32) | — | 당첨 인원; 미설정 null |
| data.placePoll.winnerIds | string[] | — | 당첨 사용자 ID 목록; 미선정 빈 배열 |

### 동작 규칙·주의사항

해당 후보의 표도 삭제합니다. 마지막 표와 상관없음 선택을 모두 잃은 일반 참여자는 참여 해제됩니다. 호스트는 멤버로 유지합니다. 이미 삭제한 ID 재요청은 INVALID_OPTION입니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | APPOINTMENT_NOT_FOUND | 약속 없음 |
| 403 | ROOM_ACCESS_DENIED / APPOINTMENT_ACCESS_DENIED / APPOINTMENT_HOST_ONLY | 해당 API에 필요한 방·약속·호스트 권한 없음 |
| 409 | POLL_CLOSED / NOT_COORDINATING | 마감 또는 조율 중이 아닌 약속 |
| 400 | VOTE_NOT_ALLOWED / INVALID_OPTION | 조율 대상이 아니거나 확정됨 또는 없는 후보 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 장소·주소 검색

### 동작 설명

`GET /api/v1/places/search`

카카오 Local API로 장소 또는 주소를 검색합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **인증 사용자**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| query | query | string | 필수 | ""  |
| address | query | boolean | 선택 | false  |
| latitude | query | number(double) | 선택 | ""  |
| longitude | query | number(double) | 선택 | ""  |
| page | query | integer(int32) | 선택 | 1  |
| size | query | integer(int32) | 선택 | 15  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.items | object[] | — | 결과 목록 |
| data.items[].name | string | — | 이름 |
| data.items[].latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.items[].longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.items[].address | string | — | 주소; 없으면 null |
| data.items[].category | string | — | 장소 분류; 없으면 null |
| data.items[].imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.items[].providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.items[].mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.page | integer(int32) | — | 요청한 페이지 번호 |
| data.hasNext | boolean | — | 다음 검색 페이지 존재 여부 |
| data.attribution | string | — | 데이터 출처 |

### 동작 규칙·주의사항

query 필수·공백 불가·최대 100자. address=true는 주소 검색. page 1~45, size 1~15. 좌표는 둘 다 생략하거나 함께 전달합니다. KAKAO_REST_API_KEY 미설정·외부 장애는 503 PROVIDER_UNAVAILABLE. 사진은 제공하지 않아 imageUrl은 null일 수 있습니다. attribution을 표시합니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 503 | PROVIDER_UNAVAILABLE | 외부 연동 미설정·비활성·장애 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 개인 장소 저장

### 동작 설명

`POST /api/v1/places/saved`

내 장소와 추천 맥락을 저장합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **인증 사용자**.

### Request

Content-Type: `application/json`.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| place | object | 필수 | 장소 정보 |
| place.name | string | 필수 | 최대 100자 |
| place.latitude | number(double) | 선택 | 최소 -90; 최대 90 |
| place.longitude | number(double) | 선택 | 최소 -180; 최대 180 |
| place.address | string | 선택 | 최대 500자 |
| place.category | string | 선택 | 최대 100자 |
| place.imageUrl | string | 선택 | 최대 2048자; 패턴: https?://[^\s]+ |
| place.providerId | string | 선택 | 최대 100자 |
| place.mapUrl | string | 선택 | 최대 2048자; 패턴: https?://[^\s]+ |
| context | string | 필수 | 허용: ALL, SENIOR, COLLEAGUES, FRIENDS, RECENT |

요청 형식 예시(실제 ID·시각·URL로 교체):

```json
{
  "place": {
    "name": "성수 모임",
    "latitude": 37.5444,
    "longitude": 127.0374,
    "address": "",
    "category": "",
    "imageUrl": "https://api.example.com/example.png",
    "providerId": "11111111-1111-4111-8111-111111111111",
    "mapUrl": "https://api.example.com/example.png"
  },
  "context": "ALL"
}
```

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data.place | object | — | 장소 정보 |
| data.place.name | string | — | 이름 |
| data.place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.place.address | string | — | 주소; 없으면 null |
| data.place.category | string | — | 장소 분류; 없으면 null |
| data.place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data.place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data.place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data.context | string | — | 허용: ALL, SENIOR, COLLEAGUES, FRIENDS, RECENT |
| data.createdAt | string(date-time) | — | 생성 시각(UTC) |

### 동작 규칙·주의사항

place와 context 필수. name 필수·공백 불가. 좌표는 함께 전달하거나 둘 다 생략. context는 ALL/SENIOR/COLLEAGUES/FRIENDS/RECENT. 다른 사용자에게 저장 목록은 공유되지 않습니다. 매번 새 저장 항목을 생성합니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 개인 저장 장소 조회

### 동작 설명

`GET /api/v1/places/saved`

내 저장 장소를 최신 저장순으로 조회합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **인증 사용자**.

### Request

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object[] | — | 응답 데이터; 반환값이 없으면 null |
| data[].id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data[].place | object | — | 장소 정보 |
| data[].place.name | string | — | 이름 |
| data[].place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data[].place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data[].place.address | string | — | 주소; 없으면 null |
| data[].place.category | string | — | 장소 분류; 없으면 null |
| data[].place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data[].place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data[].place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data[].context | string | — | 허용: ALL, SENIOR, COLLEAGUES, FRIENDS, RECENT |
| data[].createdAt | string(date-time) | — | 생성 시각(UTC) |

### 동작 규칙·주의사항

페이지네이션 없이 배열을 반환합니다. 결과 없으면 빈 배열.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 개인 저장 장소 삭제

### 동작 설명

`DELETE /api/v1/places/saved/{id}`

저장 항목을 삭제합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **저장한 사용자 본인**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | null | — | 반환 데이터 없음 |

```json
{"success":true,"data":null}
```

### 동작 규칙·주의사항

타인 소유 또는 없는 저장 ID는 404 NOT_FOUND. 재요청도 같은 오류입니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | NOT_FOUND | 리소스 없음 또는 접근 권한 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 개인 장소 추천

### 동작 설명

`GET /api/v1/places/recommendations`

개인 저장 장소를 맥락과 검색어로 추천합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **인증 사용자**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| context | query | string | 선택 | "ALL" ALL, SENIOR, COLLEAGUES, FRIENDS, RECENT |
| query | query | string | 선택 | ""  |
| latitude | query | number(double) | 선택 | ""  |
| longitude | query | number(double) | 선택 | ""  |
| limit | query | integer(int32) | 선택 | 20  |
| refresh | query | boolean | 선택 | false  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object[] | — | 응답 데이터; 반환값이 없으면 null |
| data[].place | object | — | 장소 정보 |
| data[].place.name | string | — | 이름 |
| data[].place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data[].place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data[].place.address | string | — | 주소; 없으면 null |
| data[].place.category | string | — | 장소 분류; 없으면 null |
| data[].place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data[].place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data[].place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data[].distanceMeters | integer(int64) | — | 직선거리(m); 좌표 없으면 null |
| data[].estimatedWalkMinutes | integer(int32) | — | 직선거리 기반 예상 도보 분; 좌표 없으면 null |
| data[].source | string | — | 추천 출처 식별자(SAVED_OR_ROOM_HISTORY) |

### 동작 규칙·주의사항

context 기본 ALL, query 최대 100자, limit 1~100(기본20), refresh 기본false. 좌표는 둘 다 필요합니다. refresh=true는 후보 순서를 섞습니다. 좌표가 있고 RECENT가 아니면 거리순, 그 외 저장 최신순. 데이터 없으면 빈 배열. 도보 시간은 직선거리/80m·분을 올림한 참고값입니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 약속별 장소 추천

### 동작 설명

`GET /api/v1/appointments/{id}/recommendations`

개인 저장 장소와 같은 방의 장소 기록을 추천합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **해당 방 멤버**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |
| context | query | string | 선택 | "ALL" ALL, SENIOR, COLLEAGUES, FRIENDS, RECENT |
| query | query | string | 선택 | ""  |
| latitude | query | number(double) | 선택 | ""  |
| longitude | query | number(double) | 선택 | ""  |
| limit | query | integer(int32) | 선택 | 20  |
| refresh | query | boolean | 선택 | false  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object[] | — | 응답 데이터; 반환값이 없으면 null |
| data[].place | object | — | 장소 정보 |
| data[].place.name | string | — | 이름 |
| data[].place.latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data[].place.longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data[].place.address | string | — | 주소; 없으면 null |
| data[].place.category | string | — | 장소 분류; 없으면 null |
| data[].place.imageUrl | string | — | 장소 이미지 URL; 없으면 null |
| data[].place.providerId | string | — | 외부 제공자 장소 ID; 없으면 null |
| data[].place.mapUrl | string | — | 외부 지도 URL; 없으면 null |
| data[].distanceMeters | integer(int64) | — | 직선거리(m); 좌표 없으면 null |
| data[].estimatedWalkMinutes | integer(int32) | — | 직선거리 기반 예상 도보 분; 좌표 없으면 null |
| data[].source | string | — | 추천 출처 식별자(SAVED_OR_ROOM_HISTORY) |

### 동작 규칙·주의사항

추천 쿼리는 개인 추천과 동일합니다. ALL/RECENT만 같은 방의 확정 장소·후보 기록을 추가합니다. 저장 장소 최신순 뒤에 약속 생성 최신순 기록을 추가해 중복 제거하며, 전체 통합 시각순 정렬은 아닙니다. 다른 맥락은 해당 맥락의 개인 저장 장소만 사용합니다. 거리·도보 시간은 좌표 없으면 null.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | APPOINTMENT_NOT_FOUND | 약속 없음 |
| 403 | ROOM_ACCESS_DENIED / APPOINTMENT_ACCESS_DENIED / APPOINTMENT_HOST_ONLY | 해당 API에 필요한 방·약속·호스트 권한 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 약속 장소 날씨 조회

### 동작 설명

`GET /api/v1/appointments/{id}/weather`

확정 장소의 현재 기온과 날씨 코드를 조회합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **해당 방 멤버**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.temperatureCelsius | number(double) | — | 현재 기온(섭씨) |
| data.weatherCode | integer(int32) | — | WMO 날씨 코드 |
| data.observedAt | string | — | 현재 날씨 관측 시각(KST) |
| data.attribution | string | — | 데이터 출처 |

### 동작 규칙·주의사항

좌표가 있는 확정 장소가 필요하며 없으면 400 BAD_REQUEST. WEATHER_ENABLED=true 설정 필요. 비활성·외부 장애는 503 PROVIDER_UNAVAILABLE. weatherCode는 WMO 코드, observedAt은 KST 오프셋 시각입니다. 미래 약속 시각의 예보가 아닙니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | APPOINTMENT_NOT_FOUND | 약속 없음 |
| 403 | ROOM_ACCESS_DENIED / APPOINTMENT_ACCESS_DENIED / APPOINTMENT_HOST_ONLY | 해당 API에 필요한 방·약속·호스트 권한 없음 |
| 503 | PROVIDER_UNAVAILABLE | 외부 연동 미설정·비활성·장애 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 약속 지도 조회

### 동작 설명

`GET /api/v1/appointments/{id}/map`

현재 공유 중인 참여자의 최신 위치를 조회합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **약속 멤버**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |
| latitude | query | number | 필수 | -90~90 |
| longitude | query | number | 필수 | -180~180 |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.roomId | string | — | 방 ID; 지도 응답에서는 호환상 약속 ID |
| data.roomName | string | — | 지도 응답에서는 약속 이름 |
| data.currentUserId | string | — | 요청자 ID |
| data.participants | object[] | — | 지도 위치 목록 또는 도착 현황 참여자 목록 |
| data.participants[].id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data.participants[].name | string | — | 이름 |
| data.participants[].latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.participants[].longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.participants[].distanceMeters | integer(int64) | — | 직선거리(m); 좌표 없으면 null |
| data.participants[].self | boolean | — | 요청자 본인 여부 |
| data.participants[].mock | boolean | — | 실제 저장 위치는 false |
| data.participants[].updatedAt | string(date-time) | — | 마지막 갱신 시각(UTC) |

### 동작 규칙·주의사항

CONFIRMED이며 위치 공유 시간창 안에서만 가능합니다(기본 약속 전후30분). 쿼리 latitude/longitude 필수. 공유 활성·최근60초 이내 갱신·현재 약속 멤버인 위치만 반환합니다. 쿼리 위치는 거리 계산용이며 저장하지 않습니다. 응답 roomId/roomName은 호환을 위해 약속 ID/이름을 담습니다. 기존 /rooms/{약속ID}/map과 동일합니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 403 | ROOM_ACCESS_DENIED | 약속 멤버가 아니거나 확정·공유시간 조건 불충족 |
| 404 | ROOM_NOT_FOUND | 약속 ID에 해당하는 약속 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 약속 내 위치 갱신

### 동작 설명

`PUT /api/v1/appointments/{id}/location`

내 위치와 공유 상태를 갱신합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **약속 멤버**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |

Content-Type: `application/json`.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| latitude | number(double) | 필수 | 최소 -90; 최대 90 |
| longitude | number(double) | 필수 | 최소 -180; 최대 180 |
| sharingEnabled | boolean | 선택 | 위치 공유 여부; 도착 응답은 시간창·최신성까지 반영 |
| shareLevel | string | 선택 | 최대 10자 |
| speedKmh | number(double) | 선택 | 최소 0; 최대 500 |
| transport | string | 선택 | 최대 10자 |

요청 형식 예시(실제 ID·시각·URL로 교체):

```json
{
  "latitude": 37.5444,
  "longitude": 127.0374,
  "sharingEnabled": true,
  "shareLevel": "BASIC",
  "speedKmh": 0,
  "transport": "WALK"
}
```

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | null | — | 반환 데이터 없음 |

```json
{"success":true,"data":null}
```

### 동작 규칙·주의사항

CONFIRMED 및 공유 시간창 내에서만 가능합니다. latitude/longitude 필수. sharingEnabled는 명시적으로 전달하며 생략 시 false입니다. shareLevel은 ALL/BASIC/CLOSE/OFF(대소문자 무시), 생략 시 BASIC. OFF는 공유를 끕니다. speedKmh(0~500)와 transport(최대10자)는 저장하지만 지도 응답에는 노출하지 않습니다. 현재 ALL/BASIC/CLOSE 간 공개 좌표 정밀도 차이는 없습니다. 기존 /rooms/{약속ID}/location과 동일합니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 403 | ROOM_ACCESS_DENIED | 약속 멤버가 아니거나 확정·공유시간 조건 불충족 |
| 404 | ROOM_NOT_FOUND | 약속 ID에 해당하는 약속 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 약속 위치 공유 해제

### 동작 설명

`DELETE /api/v1/appointments/{id}/location`

본인의 위치 공유를 즉시 끕니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **약속 멤버**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | null | — | 반환 데이터 없음 |

```json
{"success":true,"data":null}
```

### 동작 규칙·주의사항

공유 시간창 밖에서도 가능합니다. 저장 위치가 없어도 성공합니다. 도착·이동 상태는 변경하지 않습니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | APPOINTMENT_NOT_FOUND | 약속 없음 |
| 403 | ROOM_ACCESS_DENIED / APPOINTMENT_ACCESS_DENIED / APPOINTMENT_HOST_ONLY | 해당 API에 필요한 방·약속·호스트 권한 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 약속 도착 현황 조회

### 동작 설명

`GET /api/v1/appointments/{id}/attendance`

참여자의 이동·도착·상태 메시지와 인원 요약을 조회합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **약속 멤버**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.appointmentId | string | — | 약속 ID |
| data.serverTime | string(date-time) | — | 서버 현재 시각(UTC) |
| data.confirmedTime | string(date-time) | — | 확정 약속 시각(KST); 미확정 null |
| data.secondsUntilAppointment | integer(int64) | — | 약속까지 초; 미확정 null, 지났으면 음수 |
| data.totalCount | integer(int32) | — | 목록은 필터 적용 결과 수, 도착 현황은 참여자 수 |
| data.arrivedCount | integer(int64) | — | 도착 인원 |
| data.notDepartedCount | integer(int64) | — | 출발 전 인원 |
| data.participants | object[] | — | 지도 위치 목록 또는 도착 현황 참여자 목록 |
| data.participants[].id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data.participants[].name | string | — | 이름 |
| data.participants[].avatarUrl | string | — | 프로필 이미지 URL; 미설정 null |
| data.participants[].state | string | — | 허용: NOT_DEPARTED, EN_ROUTE, ARRIVED |
| data.participants[].statusMessage | string | — | 상태 메시지; 없으면 null |
| data.participants[].transport | string | — | 허용: WALK, BICYCLE, CAR, TRANSIT, OTHER |
| data.participants[].etaMinutes | integer(int32) | — | 예상 도착 분; 미보고 또는 5분 미갱신 null |
| data.participants[].arrivedAt | string(date-time) | — | 도착 시각(UTC); 미도착 null |
| data.participants[].sharingEnabled | boolean | — | 위치 공유 여부; 도착 응답은 시간창·최신성까지 반영 |
| data.participants[].latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.participants[].longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.participants[].locationUpdatedAt | string(date-time) | — | 공개 위치 갱신 시각; 없으면 null |
| data.participants[].nextPokeAt | string(date-time) | — | 해당 대상 콕 찌르기 쿨다운 종료 시각; 없으면 null |

### 동작 규칙·주의사항

상태 없으면 NOT_DEPARTED. 도착자 도착시각순 뒤에 사용자 ID순. ETA는 5분 미갱신 시 null. 좌표는 공유ON·60초 이내·공유시간창 내부일 때만 공개합니다. secondsUntilAppointment는 약속 시각 이후 음수일 수 있고 미확정이면 null. nextPokeAt은 요청자-대상별 콕 찌르기 쿨다운 종료 시각이며 없으면 null.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | APPOINTMENT_NOT_FOUND | 약속 없음 |
| 403 | ROOM_ACCESS_DENIED / APPOINTMENT_ACCESS_DENIED / APPOINTMENT_HOST_ONLY | 해당 API에 필요한 방·약속·호스트 권한 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 내 이동·도착 상태 갱신

### 동작 설명

`PUT /api/v1/appointments/{id}/attendance/me`

본인의 출발·이동·도착 상태와 상태 메시지를 저장합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **약속 멤버**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |

Content-Type: `application/json`.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| state | string | 필수 | 허용: NOT_DEPARTED, EN_ROUTE, ARRIVED |
| transport | string | 선택 | 허용: WALK, BICYCLE, CAR, TRANSIT, OTHER |
| etaMinutes | integer(int32) | 선택 | 최소 0; 최대 1440 |
| statusMessage | string | 선택 | 최대 200자 |

요청 형식 예시(실제 ID·시각·URL로 교체):

```json
{
  "state": "EN_ROUTE",
  "transport": "WALK",
  "etaMinutes": 0,
  "statusMessage": ""
}
```

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.appointmentId | string | — | 약속 ID |
| data.serverTime | string(date-time) | — | 서버 현재 시각(UTC) |
| data.confirmedTime | string(date-time) | — | 확정 약속 시각(KST); 미확정 null |
| data.secondsUntilAppointment | integer(int64) | — | 약속까지 초; 미확정 null, 지났으면 음수 |
| data.totalCount | integer(int32) | — | 목록은 필터 적용 결과 수, 도착 현황은 참여자 수 |
| data.arrivedCount | integer(int64) | — | 도착 인원 |
| data.notDepartedCount | integer(int64) | — | 출발 전 인원 |
| data.participants | object[] | — | 지도 위치 목록 또는 도착 현황 참여자 목록 |
| data.participants[].id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data.participants[].name | string | — | 이름 |
| data.participants[].avatarUrl | string | — | 프로필 이미지 URL; 미설정 null |
| data.participants[].state | string | — | 허용: NOT_DEPARTED, EN_ROUTE, ARRIVED |
| data.participants[].statusMessage | string | — | 상태 메시지; 없으면 null |
| data.participants[].transport | string | — | 허용: WALK, BICYCLE, CAR, TRANSIT, OTHER |
| data.participants[].etaMinutes | integer(int32) | — | 예상 도착 분; 미보고 또는 5분 미갱신 null |
| data.participants[].arrivedAt | string(date-time) | — | 도착 시각(UTC); 미도착 null |
| data.participants[].sharingEnabled | boolean | — | 위치 공유 여부; 도착 응답은 시간창·최신성까지 반영 |
| data.participants[].latitude | number(double) | — | 위도; 미제공 또는 비공개면 null |
| data.participants[].longitude | number(double) | — | 경도; 미제공 또는 비공개면 null |
| data.participants[].locationUpdatedAt | string(date-time) | — | 공개 위치 갱신 시각; 없으면 null |
| data.participants[].nextPokeAt | string(date-time) | — | 해당 대상 콕 찌르기 쿨다운 종료 시각; 없으면 null |

### 동작 규칙·주의사항

CONFIRMED 및 공유 시간창 내에서만 허용합니다. state 필수. EN_ROUTE일 때만 transport와 etaMinutes(0~1440)를 보낼 수 있습니다. statusMessage 최대200자. ARRIVED 최초 신고시 서버가 도착 시각을 기록하며 다른 상태로 바꾸면 초기화합니다. 자동 GPS 판정이 아닌 본인 신고입니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | APPOINTMENT_NOT_FOUND | 약속 없음 |
| 403 | ROOM_ACCESS_DENIED / APPOINTMENT_ACCESS_DENIED / APPOINTMENT_HOST_ONLY | 해당 API에 필요한 방·약속·호스트 권한 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 참여자 콕 찌르기

### 동작 설명

`POST /api/v1/appointments/{id}/members/{memberId}/poke`

대상 약속 멤버에게 콕 찌르기 알림을 저장합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **약속 멤버**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |
| memberId | path | string | 필수 | ""  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data.appointmentId | string | — | 약속 ID |
| data.senderId | string | — | 알림 발신 사용자 ID |
| data.recipientId | string | — | 알림 수신 사용자 ID |
| data.createdAt | string(date-time) | — | 생성 시각(UTC) |
| data.readAt | string(date-time) | — | 최초 읽음 시각(UTC); 미확인 null |

### 동작 규칙·주의사항

공유 시간창 내에서만 가능. 자신은 찌를 수 없습니다. 약속/발신자/수신자별5분 쿨다운으로 중복 시429 POKE_COOLDOWN. 실제 기기 푸시는 미연동이며 알림함 조회로 확인합니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | APPOINTMENT_NOT_FOUND | 약속 없음 |
| 403 | ROOM_ACCESS_DENIED / APPOINTMENT_ACCESS_DENIED / APPOINTMENT_HOST_ONLY | 해당 API에 필요한 방·약속·호스트 권한 없음 |
| 404 | MEMBER_NOT_FOUND | 대상이 약속 멤버가 아님 |
| 429 | POKE_COOLDOWN | 같은 대상에 5분 이내 재요청 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 내 알림 조회

### 동작 설명

`GET /api/v1/notifications`

수신한 콕 찌르기 알림을 최신순으로 최대100개 조회합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **인증 사용자**.

### Request

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object[] | — | 응답 데이터; 반환값이 없으면 null |
| data[].id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data[].appointmentId | string | — | 약속 ID |
| data[].senderId | string | — | 알림 발신 사용자 ID |
| data[].recipientId | string | — | 알림 수신 사용자 ID |
| data[].createdAt | string(date-time) | — | 생성 시각(UTC) |
| data[].readAt | string(date-time) | — | 최초 읽음 시각(UTC); 미확인 null |

### 동작 규칙·주의사항

다른 사용자의 알림은 포함하지 않습니다. readAt이 null이면 읽지 않은 알림. 페이지네이션 없음.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.

---

## 알림 읽음 처리

### 동작 설명

`PUT /api/v1/notifications/{id}/read`

수신 알림을 읽음 처리합니다.

인증: `Authorization: Bearer <accessToken>`. 권한: **알림 수신자 본인**.

### Request

| 필드 | 위치 | 타입 | 필수 | 기본값·허용값 |
| --- | --- | --- | --- | --- |
| id | path | string | 필수 | ""  |

요청 본문 없음.

### Response

성공 **HTTP 200**.

| 필드 | 타입 | 필수 여부 | 설명·제한 |
| --- | --- | --- | --- |
| success | boolean | — | 성공 여부(true) |
| data | object | — | 응답 데이터; 반환값이 없으면 null |
| data.id | string | — | 리소스 ID(경로에 따라 방·사용자·알림·이미지 등) |
| data.appointmentId | string | — | 약속 ID |
| data.senderId | string | — | 알림 발신 사용자 ID |
| data.recipientId | string | — | 알림 수신 사용자 ID |
| data.createdAt | string(date-time) | — | 생성 시각(UTC) |
| data.readAt | string(date-time) | — | 최초 읽음 시각(UTC); 미확인 null |

### 동작 규칙·주의사항

없는 ID 또는 타인 알림은404 NOT_FOUND. 재호출은 기존 최초 읽음 시각을 유지합니다.

### 오류 응답

| HTTP | code | 발생 조건 |
| --- | --- | --- |
| 401 | AUTHENTICATION_REQUIRED / INVALID_TOKEN | 인증 누락 또는 만료·무효 토큰 |
| 400 | BAD_REQUEST / VALIDATION_ERROR | 요청 형식·필수값·범위·상태 조건 위반 |
| 404 | NOT_FOUND | 리소스 없음 또는 접근 권한 없음 |

오류는 `{"success":false,"code":"...","message":"...","fieldErrors":{}}` 형식입니다. 필드 검증 실패 시 fieldErrors에 상세 내용이 포함됩니다. 조건이 겹치면 먼저 검사된 오류를 반환합니다.

### 기준

백엔드 구현 `69cc4d4`와 main 통합 기준. 구현 완료와 운영 배포 여부는 별개입니다.
