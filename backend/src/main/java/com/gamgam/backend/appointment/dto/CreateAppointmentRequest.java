package com.gamgam.backend.appointment.dto;

import com.gamgam.backend.appointment.vo.AppointmentTemplate;
import com.gamgam.backend.appointment.vo.LateThreshold;
import com.gamgam.backend.appointment.vo.LocationSharingPolicy;
import com.gamgam.backend.appointment.vo.PenaltyRule;
import com.gamgam.backend.appointment.vo.PenaltyTarget;
import com.gamgam.backend.appointment.vo.Place;
import com.gamgam.backend.appointment.vo.RewardRule;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.OffsetDateTime;
import java.util.List;

public record CreateAppointmentRequest(
        @NotBlank @Size(max = 50) String name,
        @NotNull AppointmentTemplate template,
        List<@NotNull @Future OffsetDateTime> candidatesTime,
        @Future OffsetDateTime confirmedTime,
        List<@NotNull @Valid PlaceRequest> candidatesPlace,
        @Valid PlaceRequest confirmedPlace,
        @Valid PenaltyRequest penalty,
        @Valid RewardRequest reward,
        @Valid LocationSharingRequest locationSharing
) {
    /**
     * template과 confirmedTime의 관계를 검사한다.
     * - 시간을 조율해야 하는 template(TIME_ONLY, BOTH)이면 confirmedTime은 아직 없어야 정상
     *   (나중에 candidatesTime 중 하나로 확정될 값이라서, 지금 미리 넣으면 모순)
     * - 시간이 이미 정해진 template(ALL, PLACE_ONLY)이면 confirmedTime이 반드시 있어야 정상
     *
     * template이 null인 경우는 @NotNull이 이미 실패 처리하므로,
     * 여기서는 판단할 근거가 없다고 보고 true(통과)를 반환해 에러 메시지 중복을 막는다.
     */
    @AssertTrue(message = "confirmedTime is required unless the template coordinates time")
    public boolean isConfirmedTimeConsistent() {
        if (template == null) {
            return true;
        }
        if (template.coordinatesTime()) {
            return confirmedTime == null;
        }
        return confirmedTime != null;
    }

    /**
     * template과 candidatesTime(시간 후보 목록)의 관계를 검사한다.
     * - 시간을 조율해야 하는 template이면 후보가 2개 이상 있어야 투표/선택이 의미 있음
     * - 그렇지 않으면 후보 목록 자체가 비어 있어야 함 (이미 confirmedTime으로 정했으니까)
     *
     * 실제 "몇 개 이상이어야 하는지/비어야 하는지" 판단은 공통 로직이라
     * isCandidateListConsistent()로 뽑아뒀다. (candidatesPlace 검사와 로직이 완전히 동일)
     */
    @AssertTrue(message = "candidatesTime must have at least 2 options when coordinating time, and must be empty otherwise")
    public boolean isCandidatesTimeConsistent() {
        if (template == null) {
            return true;
        }
        return isCandidateListConsistent(candidatesTime, template.coordinatesTime());
    }

    /**
     * template과 confirmedPlace의 관계를 검사한다.
     * - 장소를 조율해야 하는 template(PLACE_ONLY, BOTH)이면 confirmedPlace는 없어야 정상
     * - 장소가 이미 정해진 template(ALL, TIME_ONLY)이면 confirmedPlace가 있어야 정상
     */
    @AssertTrue(message = "confirmedPlace is required unless the template coordinates place")
    public boolean isConfirmedPlaceConsistent() {
        if (template == null) {
            return true;
        }
        if (template.coordinatesPlace()) {
            return confirmedPlace == null;
        }
        return confirmedPlace != null;
    }

    /**
     * template과 candidatesPlace(장소 후보 목록)의 관계를 검사한다.
     * isCandidatesTimeConsistent()와 대칭 — 시간이 장소로 바뀐 버전.
     */
    @AssertTrue(message = "candidatesPlace must have at least 2 options when coordinating place, and must be empty otherwise")
    public boolean isCandidatesPlaceConsistent() {
        if (template == null) {
            return true;
        }
        return isCandidateListConsistent(candidatesPlace, template.coordinatesPlace());
    }

    /**
     * "조율이 필요한 항목이면 후보가 2개 이상, 아니면 후보가 아예 없어야 한다"는
     * 시간/장소 공통 규칙 하나만 담당하는 도우미 메서드.
     *
     * candidates: 검사할 후보 목록 (candidatesTime 또는 candidatesPlace가 들어온다)
     * coordinationRequired: 이 항목을 지금 조율해야 하는 template인지 여부
     *                        (template.coordinatesTime() 또는 template.coordinatesPlace() 결과)
     */
    private static boolean isCandidateListConsistent(List<?> candidates, boolean coordinationRequired) {
        if (coordinationRequired) {
            return candidates != null && candidates.size() >= 2;
        }
        return candidates == null || candidates.isEmpty();
    }

    /**
     * 장소 후보/확정 장소를 표현하는 중첩 DTO.
     * 좌표는 선택 입력이지만, 주면 위도·경도 둘 다 같이 줘야 한다 (하나만 주는 건 허용 안 함).
     */
    public record PlaceRequest(
            @NotBlank @Size(max = 100) String name,
            @DecimalMin("-90") @DecimalMax("90") Double latitude,
            @DecimalMin("-180") @DecimalMax("180") Double longitude) {
        @AssertTrue(message = "latitude and longitude must be provided together")
        public boolean isCoordinatesPaired() {
            return (latitude == null) == (longitude == null);
        }

        public Place toDomain() {
            return new Place(name, latitude, longitude);
        }
    }

    /** 지각 벌칙 규칙 요청 DTO. */
    public record PenaltyRequest(
            @NotBlank @Size(max = 100) String description,
            @NotNull LateThreshold lateThresholdMin,
            @NotNull PenaltyTarget target) {
        public PenaltyRule toDomain() {
            return new PenaltyRule(description, lateThresholdMin, target);
        }
    }

    /** 보상 규칙 요청 DTO. */
    public record RewardRequest(@NotBlank @Size(max = 100) String description) {
        public RewardRule toDomain() {
            return new RewardRule(description);
        }
    }

    /**
     * 위치 공유 시작/종료 시점 설정 요청 DTO.
     * 둘 다 선택 입력이며, 안 주면 LocationSharingPolicy의 기본값을 쓴다.
     */
    public record LocationSharingRequest(
            @Min(0) @Max(240) Integer startMinutesBefore,
            @Min(0) @Max(240) Integer maxMinutesAfter) {
        public LocationSharingPolicy toDomain() {
            int start = LocationSharingPolicy.DEFAULT_START_MINUTES_BEFORE;
            if (startMinutesBefore != null) {
                start = startMinutesBefore;
            }
            int max = LocationSharingPolicy.DEFAULT_MAX_MINUTES_AFTER;
            if (maxMinutesAfter != null) {
                max = maxMinutesAfter;
            }
            return new LocationSharingPolicy(start, max);
        }
    }
}
