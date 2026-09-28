package com.gamgam.backend.appointment;

import static com.gamgam.backend.appointment.AppointmentFixtures.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.service.AppointmentService;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

// 기본 프로필(local)의 H2 인메모리 DB로 실제 저장·조회를 확인한다.
@SpringBootTest
class AppointmentPersistenceTests {

    @Autowired
    private AppointmentService service;

    @Autowired
    private AppointmentRepository repository;

    @Test
    void 생성한_약속을_id로_다시_조회할_수_있다() {
        var created = service.create(both());

        var found = service.get(created.id());

        assertThat(found.name()).isEqualTo("성수 브런치");
        assertThat(found.status()).isEqualTo(AppointmentStatus.COORDINATING);
        assertThat(found.shareUrl()).isEqualTo(created.shareUrl());
        assertThat(repository.existsById(created.id())).isTrue();
    }

    @Test
    void 후보_리스트의_순서와_개수가_유지된다() {
        var request = both();
        var created = service.create(request);

        var found = service.get(created.id());

        assertThat(found.candidatesTime()).hasSize(2);
        assertThat(found.candidatesTime().get(0).toInstant())
                .isEqualTo(request.candidatesTime().get(0).toInstant());
        assertThat(found.candidatesTime().get(1).toInstant())
                .isEqualTo(request.candidatesTime().get(1).toInstant());
        assertThat(found.candidatesPlace()).extracting("name").containsExactly("성수 카페거리", "서울숲");
    }

    @Test
    void 조회_응답의_시간은_KST_오프셋이다() {
        var created = service.create(all());

        var found = service.get(created.id());

        assertThat(found.confirmedTime().getOffset().getTotalSeconds()).isEqualTo(9 * 3600);
    }

    @Test
    void 확정_장소_좌표와_생성시각이_저장된다() {
        var created = service.create(all());

        var found = service.get(created.id());

        assertThat(found.status()).isEqualTo(AppointmentStatus.CONFIRMED);
        assertThat(found.confirmedPlace().latitude()).isEqualTo(37.5563);
        assertThat(found.confirmedPlace().longitude()).isEqualTo(126.9236);
        assertThat(found.createdAt()).isNotNull(); // JPA Auditing
    }

    @Test
    void 없는_id를_조회하면_예외가_난다() {
        assertThatThrownBy(() -> service.get("no-such-id"))
                .isInstanceOfSatisfying(BusinessException.class,
                        e -> assertThat(e.errorCode()).isEqualTo(ErrorCode.APPOINTMENT_NOT_FOUND));
    }
}
