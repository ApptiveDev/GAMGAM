package com.gamgam.backend.map;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.springframework.stereotype.Repository;

@Repository
public class MockRoomRepository {
    // Matches the frontend's mock identity until authentication is implemented.
    public static final String CURRENT_USER_ID = "u-yeeun";

    // Simulated distances/bearings from the supplied current location, not real user locations.
    private static final Member YEEUN = new Member(CURRENT_USER_ID, "예은", 0, 0);
    private static final Member DOYUN = new Member("u-doyun", "도윤", 900, 35);
    private static final Member SEOA = new Member("u-seoa", "서아", 1600, 120);
    private static final Member MINJUN = new Member("u-minjun", "민준", 2400, 240);
    private static final Member HARIN = new Member("u-harin", "하린", 5000, 310);

    private static final Map<String, Room> ROOMS = Map.of(
            "a-hongdae", new Room("a-hongdae", "홍대 저녁 모임", List.of(YEEUN, DOYUN, SEOA, MINJUN, HARIN)),
            "a-hiking", new Room("a-hiking", "토요일 등산", List.of(DOYUN, YEEUN, SEOA)),
            "a-donggi", new Room("a-donggi", "동기 모임", List.of(YEEUN, DOYUN, SEOA, MINJUN)),
            "a-seongsu", new Room("a-seongsu", "성수 브런치", List.of(SEOA, YEEUN, DOYUN, HARIN)),
            "a-board", new Room("a-board", "금요일 보드게임", List.of(SEOA, HARIN))
    );

    public Optional<Room> findById(String roomId) {
        return Optional.ofNullable(ROOMS.get(roomId));
    }

    public record Room(String id, String name, List<Member> members) {
    }

    public record Member(String id, String name, double distanceMeters, double bearingDegrees) {
    }
}
