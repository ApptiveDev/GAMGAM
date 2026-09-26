package com.gamgam.backend.map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;

import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class RoomMapServiceTests {
    private final RoomMapService service = new RoomMapService(new MockRoomRepository());

    @Test
    void returnsCurrentCoordinatesAndEveryRoomMemberIncludingDistantMembers() {
        var result = service.getMap("a-hongdae", 35.1796, 129.0756);
        assertThat(result.currentUserId()).isEqualTo("u-yeeun");
        assertThat(result.participants()).extracting(RoomMapResponse.Participant::id)
                .containsExactly("u-yeeun", "u-doyun", "u-seoa", "u-minjun", "u-harin");
        var self = result.participants().getFirst();
        assertThat(self.self()).isTrue();
        assertThat(self.mock()).isFalse();
        assertThat(self.latitude()).isEqualTo(35.1796);
        assertThat(self.longitude()).isEqualTo(129.0756);
        assertThat(self.distanceMeters()).isZero();
        assertThat(result.participants().getLast().distanceMeters()).isEqualTo(5000);
        assertThat(result.participants().subList(1, 5)).allMatch(RoomMapResponse.Participant::mock);
    }

    @Test
    void onlyReturnsMembersOfTheSelectedRoom() {
        assertThat(service.getMap("a-hiking", 37.5, 127).participants())
                .extracting(RoomMapResponse.Participant::id).containsExactly("u-yeeun", "u-doyun", "u-seoa");
        assertThat(service.getMap("a-donggi", 37.5, 127).participants())
                .extracting(RoomMapResponse.Participant::id).doesNotContain("u-harin");
        assertThat(service.getMap("a-seongsu", 37.5, 127).participants())
                .extracting(RoomMapResponse.Participant::id).doesNotContain("u-minjun");
    }

    @Test
    void refusesMissingRoomsAndRoomsWithoutCurrentMockUser() {
        assertThatThrownBy(() -> service.getMap("missing", 0, 0)).isInstanceOfSatisfying(BusinessException.class,
                error -> assertThat(error.errorCode()).isEqualTo(ErrorCode.ROOM_NOT_FOUND));
        assertThatThrownBy(() -> service.getMap("a-board", 0, 0)).isInstanceOfSatisfying(BusinessException.class,
                error -> assertThat(error.errorCode()).isEqualTo(ErrorCode.ROOM_ACCESS_DENIED));
    }

    @ParameterizedTest
    @CsvSource({"37.5563,126.9236", "35.1796,129.0756", "90,180", "-90,-180", "0,179.999"})
    void generatesValidMockCoordinatesAtSpecifiedDistancesAnywhere(double latitude, double longitude) {
        var result = service.getMap("a-hongdae", latitude, longitude);
        for (var participant : result.participants()) {
            assertThat(participant.latitude()).isBetween(-90.0, 90.0);
            assertThat(participant.longitude()).isBetween(-180.0, 180.0);
            double deltaLat = Math.toRadians(participant.latitude() - latitude);
            double deltaLon = Math.toRadians(participant.longitude() - longitude);
            double a = Math.pow(Math.sin(deltaLat / 2), 2) + Math.cos(Math.toRadians(latitude))
                    * Math.cos(Math.toRadians(participant.latitude())) * Math.pow(Math.sin(deltaLon / 2), 2);
            double actualDistance = 2 * 6371000 * Math.asin(Math.sqrt(Math.min(1, a)));
            assertThat(actualDistance).isCloseTo(participant.distanceMeters(), within(0.01));
        }
    }
}
