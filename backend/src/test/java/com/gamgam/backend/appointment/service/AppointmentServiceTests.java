package com.gamgam.backend.appointment.service;

import static com.gamgam.backend.appointment.AppointmentFixtures.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import com.gamgam.backend.appointment.dto.CreateAppointmentRequest;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest.LocationSharingRequest;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest.RewardRequest;
import com.gamgam.backend.appointment.entity.Appointment;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.vo.AppointmentTemplate;
import com.gamgam.backend.appointment.vo.LocationSharingPolicy;
import com.gamgam.backend.global.config.ShareProperties;
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class AppointmentServiceTests {

    private static final String BASE_URL = "http://localhost:3000";

    @Mock
    private AppointmentRepository repository;

    private AppointmentService service;

    @BeforeEach
    void setUp() {
        service = new AppointmentService(repository, new ShareLinkGenerator(new ShareProperties(BASE_URL)));
        lenient().when(repository.save(any(Appointment.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    private Appointment savedEntity() {
        var captor = ArgumentCaptor.forClass(Appointment.class);
        verify(repository).save(captor.capture());
        return captor.getValue();
    }

    @Test
    void ALL_템플릿은_바로_CONFIRMED로_시작한다() {
        var response = service.create(all());

        assertThat(response.status()).isEqualTo(AppointmentStatus.CONFIRMED);
        assertThat(response.template()).isEqualTo(AppointmentTemplate.ALL);
        assertThat(response.confirmedTime()).isNotNull();
        assertThat(response.confirmedPlace().name()).isEqualTo("연남동 소금집 델리");
    }

    @Test
    void 조율이_필요한_템플릿은_COORDINATING으로_시작한다() {
        assertThat(service.create(timeOnly()).status()).isEqualTo(AppointmentStatus.COORDINATING);
    }

    @Test
    void 장소나_시간_후보가_응답에_그대로_담긴다() {
        var response = service.create(both());

        assertThat(response.candidatesTime()).hasSize(2);
        assertThat(response.candidatesPlace()).extracting("name").containsExactly("성수 카페거리", "서울숲");
        assertThat(response.confirmedTime()).isNull();
        assertThat(response.confirmedPlace()).isNull();
    }

    @Test
    void 저장할_때는_UTC_응답할_때는_KST다() {
        var request = timeOnly();

        var response = service.create(request);

        var entity = savedEntity();
        assertThat(entity.getCandidatesTime()).allMatch(t -> t.getOffset().equals(ZoneOffset.UTC));
        assertThat(response.candidatesTime()).allMatch(t -> t.getOffset().getTotalSeconds() == 9 * 3600);
        // 시각 자체는 변하지 않는다
        assertThat(response.candidatesTime().get(0).toInstant())
                .isEqualTo(request.candidatesTime().get(0).toInstant());
    }

    @Test
    void 다른_오프셋으로_보내도_같은_시각으로_저장된다() {
        var utcTime = OffsetDateTime.now(ZoneOffset.UTC).plusDays(3).withNano(0);
        var request = new CreateAppointmentRequest("모임", AppointmentTemplate.ALL,
                null, utcTime, null, place("연남동"), null, null, null);

        var response = service.create(request);

        assertThat(response.confirmedTime().toInstant()).isEqualTo(utcTime.toInstant());
        assertThat(savedEntity().getConfirmedTime().getOffset()).isEqualTo(ZoneOffset.UTC);
    }

    @Test
    void 위치공유_미지정이면_기본값이_적용된다() {
        var response = service.create(all());

        assertThat(response.locationSharing()).isEqualTo(LocationSharingPolicy.defaults());
    }

    @Test
    void 위치공유를_지정하면_그_값을_쓴다() {
        var request = new CreateAppointmentRequest("모임", AppointmentTemplate.ALL,
                null, future(3), null, place("연남동"), null, null, new LocationSharingRequest(120, 15));

        var response = service.create(request);

        assertThat(response.locationSharing()).isEqualTo(new LocationSharingPolicy(120, 15));
    }

    @Test
    void 벌칙과_보상을_지정하면_응답에_담긴다() {
        var withRules = new CreateAppointmentRequest("모임", AppointmentTemplate.ALL,
                null, future(3), null, place("연남동"), penalty(), new RewardRequest("커피 쿠폰"), null);

        var response = service.create(withRules);
        assertThat(response.penalty().description()).isEqualTo("커피 사기");
        assertThat(response.penalty().lateThresholdMin().minutes()).isEqualTo(10);
        assertThat(response.reward().description()).isEqualTo("커피 쿠폰");
    }

    @Test
    void 벌칙_보상을_안_주면_null이다() {
        var response = service.create(all());

        assertThat(response.penalty()).isNull();
        assertThat(response.reward()).isNull();
    }

    @Test
    void 생성하면_UUID_id와_공유링크가_만들어진다() {
        var response = service.create(all());

        assertThat(response.id()).hasSize(36);
        assertThat(response.shareUrl()).isEqualTo(BASE_URL + "/appointments/" + response.id());
    }

    @Test
    void 조회하면_저장된_약속을_응답으로_변환한다() {
        var entity = Appointment.builder()
                .id("abc")
                .name("동기 모임")
                .template(AppointmentTemplate.ALL)
                .confirmedTime(OffsetDateTime.parse("2030-01-01T10:00:00Z"))
                .confirmedPlace(place("연남동").toDomain())
                .locationSharing(LocationSharingPolicy.defaults())
                .status(AppointmentStatus.CONFIRMED)
                .build();
        when(repository.findById("abc")).thenReturn(Optional.of(entity));

        var response = service.get("abc");

        assertThat(response.id()).isEqualTo("abc");
        assertThat(response.confirmedTime().getHour()).isEqualTo(19); // 10:00Z -> 19:00 KST
        assertThat(response.shareUrl()).isEqualTo(BASE_URL + "/appointments/abc");
    }

    @Test
    void 없는_약속을_조회하면_APPOINTMENT_NOT_FOUND다() {
        when(repository.findById("missing")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.get("missing"))
                .isInstanceOfSatisfying(BusinessException.class,
                        e -> assertThat(e.errorCode()).isEqualTo(ErrorCode.APPOINTMENT_NOT_FOUND));
    }
}
