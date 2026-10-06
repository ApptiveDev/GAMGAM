package com.gamgam.backend.appointment;

import com.gamgam.backend.appointment.entity.Appointment;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.vo.AppointmentTemplate;
import com.gamgam.backend.appointment.vo.LocationSharingPolicy;
import com.gamgam.backend.appointment.vo.Place;
import java.time.OffsetDateTime;
import java.util.List;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class MockAppointmentData {

    @Bean
    CommandLineRunner seedAppointments(AppointmentRepository repository) {
        return args -> {
            if (repository.count() > 0) {
                return;
            }

            var tomorrow = OffsetDateTime.now().plusDays(1).withHour(19).withMinute(0).withSecond(0).withNano(0);
            repository.saveAll(List.of(
                    Appointment.builder()
                            .id("a-hongdae")
                            .name("홍대 저녁 모임")
                            .template(AppointmentTemplate.BOTH)
                            .candidatesTime(List.of(tomorrow, tomorrow.plusHours(1)))
                            .candidatesPlace(List.of(new Place("홍대입구역", 37.5571, 126.9245), new Place("연남동", 37.5614, 126.9258)))
                            .locationSharing(LocationSharingPolicy.defaults())
                            .status(AppointmentStatus.COORDINATING)
                            .build(),
                    Appointment.builder()
                            .id("a-seongsu")
                            .name("성수 브런치")
                            .template(AppointmentTemplate.ALL)
                            .confirmedTime(tomorrow.plusDays(2).withHour(11))
                            .confirmedPlace(new Place("서울숲", 37.5444, 127.0374))
                            .locationSharing(LocationSharingPolicy.defaults())
                            .status(AppointmentStatus.CONFIRMED)
                            .build()));
        };
    }
}
