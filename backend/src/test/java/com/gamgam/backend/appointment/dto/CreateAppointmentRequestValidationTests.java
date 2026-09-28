package com.gamgam.backend.appointment.dto;

import static com.gamgam.backend.appointment.AppointmentFixtures.*;
import static org.assertj.core.api.Assertions.assertThat;

import com.gamgam.backend.appointment.dto.CreateAppointmentRequest.LocationSharingRequest;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest.PenaltyRequest;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest.PlaceRequest;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest.RewardRequest;
import com.gamgam.backend.appointment.vo.AppointmentTemplate;
import com.gamgam.backend.appointment.vo.LateThreshold;
import com.gamgam.backend.appointment.vo.LocationSharingPolicy;
import com.gamgam.backend.appointment.vo.PenaltyTarget;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

class CreateAppointmentRequestValidationTests {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    private Set<String> violatedProperties(CreateAppointmentRequest request) {
        return validator.validate(request).stream()
                .map(ConstraintViolation::getPropertyPath)
                .map(Object::toString)
                .collect(Collectors.toSet());
    }

    // ---------- 정상 케이스 ----------

    @Test
    void 템플릿별_정상_요청은_검증을_통과한다() {
        assertThat(violatedProperties(all())).isEmpty();
        assertThat(violatedProperties(timeOnly())).isEmpty();
        assertThat(violatedProperties(placeOnly())).isEmpty();
        assertThat(violatedProperties(both())).isEmpty();
    }

    // ---------- 이름 / 템플릿 ----------

    @Test
    void 이름이_비어있으면_실패한다() {
        var req = new CreateAppointmentRequest(" ", AppointmentTemplate.ALL,
                null, future(3), null, place("연남동"), null, null, null);

        assertThat(violatedProperties(req)).contains("name");
    }

    @Test
    void 이름이_50자를_넘으면_실패한다() {
        var req = new CreateAppointmentRequest("가".repeat(51), AppointmentTemplate.ALL,
                null, future(3), null, place("연남동"), null, null, null);

        assertThat(violatedProperties(req)).contains("name");
    }

    @Test
    void 템플릿이_null이면_template만_실패하고_일관성_검사는_중복_에러를_내지_않는다() {
        var req = new CreateAppointmentRequest("모임", null, null, null, null, null, null, null, null);

        assertThat(violatedProperties(req)).containsExactly("template");
    }

    // ---------- 시간 ----------

    @ParameterizedTest
    @EnumSource(value = AppointmentTemplate.class, names = {"TIME_ONLY", "BOTH"})
    void 시간을_조율하는_템플릿에_confirmedTime이_있으면_실패한다(AppointmentTemplate template) {
        var req = new CreateAppointmentRequest("모임", template,
                List.of(future(3), future(4)), future(5),
                List.of(place("a"), place("b")), place("c"), null, null, null);

        assertThat(violatedProperties(req)).contains("confirmedTimeConsistent");
    }

    @ParameterizedTest
    @EnumSource(value = AppointmentTemplate.class, names = {"ALL", "PLACE_ONLY"})
    void 시간이_정해진_템플릿에_confirmedTime이_없으면_실패한다(AppointmentTemplate template) {
        var req = new CreateAppointmentRequest("모임", template,
                null, null, List.of(place("a"), place("b")), place("c"), null, null, null);

        assertThat(violatedProperties(req)).contains("confirmedTimeConsistent");
    }

    @Test
    void 시간을_조율하는데_후보가_1개면_실패한다() {
        var req = new CreateAppointmentRequest("모임", AppointmentTemplate.TIME_ONLY,
                List.of(future(3)), null, null, place("연남동"), null, null, null);

        assertThat(violatedProperties(req)).contains("candidatesTimeConsistent");
    }

    @Test
    void 시간을_조율하는데_후보가_없으면_실패한다() {
        var req = new CreateAppointmentRequest("모임", AppointmentTemplate.TIME_ONLY,
                null, null, null, place("연남동"), null, null, null);

        assertThat(violatedProperties(req)).contains("candidatesTimeConsistent");
    }

    @Test
    void 시간이_정해졌는데_후보가_있으면_실패한다() {
        var req = new CreateAppointmentRequest("모임", AppointmentTemplate.ALL,
                List.of(future(3), future(4)), future(3), null, place("연남동"), null, null, null);

        assertThat(violatedProperties(req)).contains("candidatesTimeConsistent");
    }

    @Test
    void 과거_시간은_실패한다() {
        var req = new CreateAppointmentRequest("모임", AppointmentTemplate.ALL,
                null, future(-1), null, place("연남동"), null, null, null);

        assertThat(violatedProperties(req)).contains("confirmedTime");
    }

    @Test
    void 후보_시간_중_과거가_있으면_실패한다() {
        var req = new CreateAppointmentRequest("모임", AppointmentTemplate.TIME_ONLY,
                List.of(future(3), future(-1)), null, null, place("연남동"), null, null, null);

        assertThat(violatedProperties(req)).anyMatch(p -> p.startsWith("candidatesTime"));
    }

    // ---------- 장소 ----------

    @ParameterizedTest
    @EnumSource(value = AppointmentTemplate.class, names = {"PLACE_ONLY", "BOTH"})
    void 장소를_조율하는_템플릿에_confirmedPlace가_있으면_실패한다(AppointmentTemplate template) {
        var req = new CreateAppointmentRequest("모임", template,
                List.of(future(3), future(4)), null,
                List.of(place("a"), place("b")), place("c"), null, null, null);
        // PLACE_ONLY는 confirmedTime이 필요하므로 별도로 맞춘다
        if (template == AppointmentTemplate.PLACE_ONLY) {
            req = new CreateAppointmentRequest("모임", template,
                    null, future(3), List.of(place("a"), place("b")), place("c"), null, null, null);
        }

        assertThat(violatedProperties(req)).contains("confirmedPlaceConsistent");
    }

    @ParameterizedTest
    @EnumSource(value = AppointmentTemplate.class, names = {"ALL", "TIME_ONLY"})
    void 장소가_정해진_템플릿에_confirmedPlace가_없으면_실패한다(AppointmentTemplate template) {
        var req = template == AppointmentTemplate.ALL
                ? new CreateAppointmentRequest("모임", template, null, future(3), null, null, null, null, null)
                : new CreateAppointmentRequest("모임", template, List.of(future(3), future(4)), null, null, null, null, null, null);

        assertThat(violatedProperties(req)).contains("confirmedPlaceConsistent");
    }

    @Test
    void 장소를_조율하는데_후보가_1개면_실패한다() {
        var req = new CreateAppointmentRequest("모임", AppointmentTemplate.PLACE_ONLY,
                null, future(3), List.of(place("연남동")), null, null, null, null);

        assertThat(violatedProperties(req)).contains("candidatesPlaceConsistent");
    }

    @Test
    void 장소가_정해졌는데_후보가_있으면_실패한다() {
        var req = new CreateAppointmentRequest("모임", AppointmentTemplate.ALL,
                null, future(3), List.of(place("a"), place("b")), place("c"), null, null, null);

        assertThat(violatedProperties(req)).contains("candidatesPlaceConsistent");
    }

    @Test
    void 장소_좌표는_위도_경도를_함께_줘야_한다() {
        var onlyLat = new PlaceRequest("연남동", 37.5, null);
        var onlyLng = new PlaceRequest("연남동", null, 126.9);
        var none = new PlaceRequest("연남동", null, null);
        var both = new PlaceRequest("연남동", 37.5, 126.9);

        assertThat(validator.validate(onlyLat)).extracting(v -> v.getPropertyPath().toString())
                .contains("coordinatesPaired");
        assertThat(validator.validate(onlyLng)).extracting(v -> v.getPropertyPath().toString())
                .contains("coordinatesPaired");
        assertThat(validator.validate(none)).isEmpty();
        assertThat(validator.validate(both)).isEmpty();
    }

    @Test
    void 장소_좌표_범위를_벗어나면_실패한다() {
        assertThat(validator.validate(new PlaceRequest("a", 91.0, 126.9))).isNotEmpty();
        assertThat(validator.validate(new PlaceRequest("a", -91.0, 126.9))).isNotEmpty();
        assertThat(validator.validate(new PlaceRequest("a", 37.5, 181.0))).isNotEmpty();
        assertThat(validator.validate(new PlaceRequest("a", 37.5, -181.0))).isNotEmpty();
    }

    @Test
    void 장소_이름은_필수이고_100자_이하다() {
        assertThat(validator.validate(new PlaceRequest("", 37.5, 126.9))).isNotEmpty();
        assertThat(validator.validate(new PlaceRequest("가".repeat(101), 37.5, 126.9))).isNotEmpty();
        assertThat(validator.validate(new PlaceRequest("가".repeat(100), 37.5, 126.9))).isEmpty();
    }

    // ---------- 벌칙 / 보상 ----------

    @Test
    void 벌칙_필수값이_비면_실패한다() {
        assertThat(validator.validate(new PenaltyRequest("", LateThreshold.TEN, PenaltyTarget.ALL_LATE))).isNotEmpty();
        assertThat(validator.validate(new PenaltyRequest("커피", null, PenaltyTarget.ALL_LATE))).isNotEmpty();
        assertThat(validator.validate(new PenaltyRequest("커피", LateThreshold.TEN, null))).isNotEmpty();
        assertThat(validator.validate(new PenaltyRequest("커피", LateThreshold.TEN, PenaltyTarget.ALL_LATE))).isEmpty();
    }

    @Test
    void 중첩_벌칙이_잘못되면_요청_전체가_실패한다() {
        var req = new CreateAppointmentRequest("모임", AppointmentTemplate.ALL,
                null, future(3), null, place("연남동"),
                new PenaltyRequest("", LateThreshold.TEN, PenaltyTarget.ALL_LATE), null, null);

        assertThat(violatedProperties(req)).contains("penalty.description");
    }

    @Test
    void 보상_설명은_필수다() {
        assertThat(validator.validate(new RewardRequest(" "))).isNotEmpty();
        assertThat(validator.validate(new RewardRequest("커피 쿠폰"))).isEmpty();
    }

    // ---------- 위치 공유 ----------

    @Test
    void 위치공유_분_범위는_0에서_240이다() {
        assertThat(validator.validate(new LocationSharingRequest(-1, 30))).isNotEmpty();
        assertThat(validator.validate(new LocationSharingRequest(241, 30))).isNotEmpty();
        assertThat(validator.validate(new LocationSharingRequest(30, -1))).isNotEmpty();
        assertThat(validator.validate(new LocationSharingRequest(30, 241))).isNotEmpty();
        assertThat(validator.validate(new LocationSharingRequest(0, 240))).isEmpty();
        assertThat(validator.validate(new LocationSharingRequest(null, null))).isEmpty();
    }

    @Test
    void 위치공유_값이_없으면_기본값을_쓴다() {
        var policy = new LocationSharingRequest(null, null).toDomain();

        assertThat(policy).isEqualTo(LocationSharingPolicy.defaults());
        assertThat(policy.startMinutesBefore()).isEqualTo(30);
        assertThat(policy.maxMinutesAfter()).isEqualTo(30);
    }

    @Test
    void 위치공유_일부만_주면_나머지는_기본값이다() {
        var policy = new LocationSharingRequest(120, null).toDomain();

        assertThat(policy.startMinutesBefore()).isEqualTo(120);
        assertThat(policy.maxMinutesAfter()).isEqualTo(LocationSharingPolicy.DEFAULT_MAX_MINUTES_AFTER);
    }
}
