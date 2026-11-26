# API 명세 반영 기록

- 기준 구현: `69cc4d4`; 원격 main `63d51c9`와 통합.
- 검증: Java 21, `gradlew test bootJar --no-daemon`, 157 tests, 0 failures/errors/skips.
- Notion 기존 29개 중 변경 대상 27개 갱신, 신규 32개 추가. 로그아웃·health는 기존 계약 유지.
- Notion의 완료는 구현 및 명세 완료이며 운영 배포 완료를 뜻하지 않음.
- 실제 기기 푸시, 선물 결제·발송, GPS 자동 도착, 자동 최다득표 확정은 미구현.

## 신규 명세

| 기능 | Method | Path | Notion |
| --- | --- | --- | --- |
| 홈 약속 조회 | GET | `/api/v1/home` | [명세](https://app.notion.com/p/424e3d4189a58122b9bac7ac61ec23b8) |
| 모임 대시보드 조회 | GET | `/api/v1/rooms/{roomId}/dashboard` | [명세](https://app.notion.com/p/424e3d4189a5815e9eaafb5c06a96619) |
| 모임 정보 수정 | PATCH | `/api/v1/rooms/{id}` | [명세](https://app.notion.com/p/424e3d4189a58190a237f100b890651c) |
| 모임 멤버 조회 | GET | `/api/v1/rooms/{id}/members` | [명세](https://app.notion.com/p/424e3d4189a5816fbbcfd12a4617b479) |
| 모임 초대 조회 | GET | `/api/v1/rooms/{id}/invite` | [명세](https://app.notion.com/p/424e3d4189a58144b2d6ded82fc9083b) |
| 모임 초대 코드 재발급 | POST | `/api/v1/rooms/{id}/invite/rotate` | [명세](https://app.notion.com/p/424e3d4189a5818aa103d81d13dac55d) |
| 초대 코드로 모임 가입 | POST | `/api/v1/rooms/join` | [명세](https://app.notion.com/p/424e3d4189a581dda2ebe4b51a53132c) |
| 이미지 업로드 | POST | `/api/v1/media` | [명세](https://app.notion.com/p/424e3d4189a581e29a68eaa640310f95) |
| 이미지 다운로드 | GET | `/api/v1/media/{id}` | [명세](https://app.notion.com/p/424e3d4189a581a8acd3d1af5024362c) |
| 약속 카드 꾸미기 | PUT | `/api/v1/appointments/{id}/appearance` | [명세](https://app.notion.com/p/424e3d4189a581a88e2beb341b461d00) |
| 시간·장소 투표 설정 | PUT | `/api/v1/appointments/{id}/polls/{type}` | [명세](https://app.notion.com/p/424e3d4189a5810e8619c29cbdb0d5c4) |
| 시간·장소 투표 종료 | POST | `/api/v1/appointments/{id}/polls/{type}/close` | [명세](https://app.notion.com/p/424e3d4189a581dd8049fef324db3475) |
| 투표 선물 당첨자 선정 | POST | `/api/v1/appointments/{id}/polls/{type}/gift/draw` | [명세](https://app.notion.com/p/424e3d4189a5818889dad2c29023a1ac) |
| 시간 후보 수정 | PUT | `/api/v1/appointments/{id}/time-candidates/{candidateId}` | [명세](https://app.notion.com/p/424e3d4189a5813baa43fee30c4c8ee5) |
| 시간 후보 삭제 | DELETE | `/api/v1/appointments/{id}/time-candidates/{candidateId}` | [명세](https://app.notion.com/p/424e3d4189a58191b4aad848fc83be1a) |
| 장소 후보 수정 | PUT | `/api/v1/appointments/{id}/place-candidates/{candidateId}` | [명세](https://app.notion.com/p/424e3d4189a58101bdb8f66b9881555f) |
| 장소 후보 삭제 | DELETE | `/api/v1/appointments/{id}/place-candidates/{candidateId}` | [명세](https://app.notion.com/p/424e3d4189a5818b8395e736de33b07e) |
| 장소·주소 검색 | GET | `/api/v1/places/search` | [명세](https://app.notion.com/p/424e3d4189a58172a8c6c24bdc71066f) |
| 개인 장소 저장 | POST | `/api/v1/places/saved` | [명세](https://app.notion.com/p/424e3d4189a581369417e7fb07cf4d97) |
| 개인 저장 장소 조회 | GET | `/api/v1/places/saved` | [명세](https://app.notion.com/p/424e3d4189a5812c8b36d40bee0a5adf) |
| 개인 저장 장소 삭제 | DELETE | `/api/v1/places/saved/{id}` | [명세](https://app.notion.com/p/424e3d4189a58193b1a0e0f9a6ae92d8) |
| 개인 장소 추천 | GET | `/api/v1/places/recommendations` | [명세](https://app.notion.com/p/424e3d4189a5811193bbf4daeeb12c48) |
| 약속별 장소 추천 | GET | `/api/v1/appointments/{id}/recommendations` | [명세](https://app.notion.com/p/424e3d4189a58141a1cff2b524a0615c) |
| 약속 장소 날씨 조회 | GET | `/api/v1/appointments/{id}/weather` | [명세](https://app.notion.com/p/424e3d4189a581fc945cc1ebc4b510fc) |
| 약속 지도 조회 | GET | `/api/v1/appointments/{id}/map` | [명세](https://app.notion.com/p/424e3d4189a58158a9d0c142ba641b91) |
| 약속 내 위치 갱신 | PUT | `/api/v1/appointments/{id}/location` | [명세](https://app.notion.com/p/424e3d4189a5819f87ebf67a49165b83) |
| 약속 위치 공유 해제 | DELETE | `/api/v1/appointments/{id}/location` | [명세](https://app.notion.com/p/424e3d4189a5814b9d52f1947284d891) |
| 약속 도착 현황 조회 | GET | `/api/v1/appointments/{id}/attendance` | [명세](https://app.notion.com/p/424e3d4189a5812ba494f10dc1c043cb) |
| 내 이동·도착 상태 갱신 | PUT | `/api/v1/appointments/{id}/attendance/me` | [명세](https://app.notion.com/p/424e3d4189a5810c9e78d0989f360d47) |
| 참여자 콕 찌르기 | POST | `/api/v1/appointments/{id}/members/{memberId}/poke` | [명세](https://app.notion.com/p/424e3d4189a5816f97c6fa80ac8582ea) |
| 내 알림 조회 | GET | `/api/v1/notifications` | [명세](https://app.notion.com/p/424e3d4189a581219d0ccfb932cea324) |
| 알림 읽음 처리 | PUT | `/api/v1/notifications/{id}/read` | [명세](https://app.notion.com/p/424e3d4189a58101a588c609fc61e04b) |

## 기존 명세 변경

- [회원가입](https://app.notion.com/p/409e3d4189a580968b2dc7f36123fdfa)
- [로그인](https://app.notion.com/p/409e3d4189a580d3b192c1be3590c719)
- [내 정보 조회](https://app.notion.com/p/409e3d4189a58070b1bffeab2b5f6ffd)
- [내 정보 수정](https://app.notion.com/p/409e3d4189a580f48ad9c48701a59d34)
- [그룹 생성](https://app.notion.com/p/40de3d4189a5801eaea2eda829f27af9)
- [내 그룹 목록 조회](https://app.notion.com/p/40de3d4189a580a0b868deccff175f9a)
- [그룹 단건 조회](https://app.notion.com/p/40de3d4189a580b99198d43c09d4c4eb)
- [약속 생성](https://app.notion.com/p/3ece3d4189a58030910ee4e0909b8879)
- [내 약속 목록 조회](https://app.notion.com/p/40de3d4189a580f8841dc02ccb374458)
- [방별 약속 목록 조회](https://app.notion.com/p/3ece3d4189a580cfb411cad121d0c64e)
- [약속 단건 조회](https://app.notion.com/p/406e3d4189a5805dba7ee02764fbe9b7)
- [약속 이름 변경](https://app.notion.com/p/40fe3d4189a5813ab64fc096b3e8498d)
- [벌칙 설정](https://app.notion.com/p/40de3d4189a580f4bdcad984ed4a21b0)
- [투표 시간 후보 추가](https://app.notion.com/p/407e3d4189a58079943fdcbfa20dd402)
- [투표 장소 후보 추가](https://app.notion.com/p/407e3d4189a580bbb6a7fa821c58d610)
- [약속 투표 현황 조회](https://app.notion.com/p/407e3d4189a580478f85c7f99c3239b1)
- [시간 투표 및 취소](https://app.notion.com/p/407e3d4189a580e7a934fdff096f3a11)
- [장소 투표 및 취소](https://app.notion.com/p/407e3d4189a5805b8f9fc2a08d4611d6)
- [상관없음 투표](https://app.notion.com/p/407e3d4189a580a59dd2da125db05d57)
- [시간 개별 확정](https://app.notion.com/p/40fe3d4189a5814b9099c0f3d054a92b)
- [장소 개별 확정](https://app.notion.com/p/40fe3d4189a581099bc2e4da7a377729)
- [내 위치·공유 상태 갱신](https://app.notion.com/p/3ece3d4189a580f485d4ec7e76eb0be3)
- [약속 지도 생성](https://app.notion.com/p/3ece3d4189a580adb49ae78ff972e1a4)
- [약속 완료](https://app.notion.com/p/40de3d4189a58062804dc24c4b42f3bb)
- [약속 탈퇴](https://app.notion.com/p/40de3d4189a58050a69ce5137ea83887)
- [약속 참여자 내보내기](https://app.notion.com/p/40de3d4189a580f093f8e1b3550daf1c)
- [초대 코드로 약속 참여](https://app.notion.com/p/40de3d4189a580efa6c1db9ca0954726)

