package com.gamgam.backend.appointment.service;

import com.gamgam.backend.appointment.dto.AppointmentResponse;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest;
import com.gamgam.backend.appointment.entity.Appointment;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.vo.LocationSharingPolicy;
import com.gamgam.backend.appointment.vo.PenaltyRule;
import com.gamgam.backend.appointment.vo.Place;
import com.gamgam.backend.appointment.vo.RewardRule;
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;

import java.util.List;
import java.util.UUID;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AppointmentService {

    private final AppointmentRepository repository;
    private final ShareLinkGenerator shareLinkGenerator;

    @Transactional
    public AppointmentResponse create(CreateAppointmentRequest request) {
        Place confirmedPlace = null;
        if (request.confirmedPlace() != null) {
            confirmedPlace = request.confirmedPlace().toDomain();
        }

        PenaltyRule penalty = null;
        if (request.penalty() != null) {
            penalty = request.penalty().toDomain();
        }

        RewardRule reward = null;
        if (request.reward() != null) {
            reward = request.reward().toDomain();
        }

        LocationSharingPolicy locationSharing = LocationSharingPolicy.defaults();
        if (request.locationSharing() != null) {
            locationSharing = request.locationSharing().toDomain();
        }

        // template이 이미 다 정해진 상태(ALL)면 바로 확정, 그 외에는 조율 대기 상태로 시작
        AppointmentStatus status = AppointmentStatus.COORDINATING;
        if (request.template().isFullyDecided()) {
            status = AppointmentStatus.CONFIRMED;
        }

        Appointment appointment = repository.save(Appointment.builder()
                .id(UUID.randomUUID().toString())
                .name(request.name())
                .template(request.template())
                .candidatesTime(request.candidatesTime())
                .confirmedTime(request.confirmedTime())
                .candidatesPlace(toDomainPlaces(request.candidatesPlace()))
                .confirmedPlace(confirmedPlace)
                .penalty(penalty)
                .reward(reward)
                .locationSharing(locationSharing)
                .status(status)
                .build());

        return toResponse(appointment);
    }

    public AppointmentResponse get(String id) {
        return repository.findById(id)
                .map(this::toResponse)
                .orElseThrow(() -> new BusinessException(ErrorCode.APPOINTMENT_NOT_FOUND));
    }

    // DTO의 PlaceRequest 목록을 도메인 vo인 Place 목록으로 변환
    private static List<Place> toDomainPlaces(List<CreateAppointmentRequest.PlaceRequest> requests) {
        if (requests == null) {
            return null;
        }
        return requests.stream()
                .map(CreateAppointmentRequest.PlaceRequest::toDomain)
                .toList();
    }

    private AppointmentResponse toResponse(Appointment appointment) {
        return AppointmentResponse.of(appointment, shareLinkGenerator.create(appointment.getId()));
    }
}
