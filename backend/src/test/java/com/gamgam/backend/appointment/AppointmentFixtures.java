package com.gamgam.backend.appointment;

import com.gamgam.backend.appointment.dto.CreateAppointmentRequest;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest.PenaltyRequest;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest.PlaceRequest;
import com.gamgam.backend.appointment.vo.AppointmentTemplate;
import com.gamgam.backend.appointment.vo.LateThreshold;
import com.gamgam.backend.appointment.vo.PenaltyTarget;
import com.gamgam.backend.global.util.KstTimeConverter;

import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

// 테스트용 요청 객체 모음. 템플릿별로 "유효한" 요청을 만들어 준다.
public final class AppointmentFixtures {

    private AppointmentFixtures() {
    }

    public static OffsetDateTime future(int days) {
        return OffsetDateTime.now(KstTimeConverter.KST).plusDays(days).truncatedTo(ChronoUnit.SECONDS);
    }

    public static PlaceRequest place(String name) {
        return new PlaceRequest(name, 37.5563, 126.9236);
    }

    public static PenaltyRequest penalty() {
        return new PenaltyRequest("커피 사기", LateThreshold.TEN, PenaltyTarget.LATEST_ONLY);
    }

    // ALL: 시간·장소 모두 확정
    public static CreateAppointmentRequest all() {
        return new CreateAppointmentRequest("홍대 저녁 모임", AppointmentTemplate.ALL,
                null, future(3), null, place("연남동 소금집 델리"), null, null, null);
    }

    // TIME_ONLY: 시간만 조율
    public static CreateAppointmentRequest timeOnly() {
        return new CreateAppointmentRequest("동기 모임", AppointmentTemplate.TIME_ONLY,
                List.of(future(3), future(4)), null, null, place("연남동"), null, null, null);
    }

    // PLACE_ONLY: 장소만 조율
    public static CreateAppointmentRequest placeOnly() {
        return new CreateAppointmentRequest("주말 나들이", AppointmentTemplate.PLACE_ONLY,
                null, future(3), List.of(place("연남동"), place("망원동")), null, null, null, null);
    }

    // BOTH: 시간·장소 모두 조율
    public static CreateAppointmentRequest both() {
        return new CreateAppointmentRequest("성수 브런치", AppointmentTemplate.BOTH,
                List.of(future(3), future(4)), null,
                List.of(place("성수 카페거리"), place("서울숲")), null, null, null, null);
    }
}
