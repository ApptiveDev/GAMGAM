package com.gamgam.backend.appointment.service;

import com.gamgam.backend.appointment.dto.AppointmentMemberResponse;
import com.gamgam.backend.appointment.dto.AppointmentResponse;
import com.gamgam.backend.appointment.dto.ConfirmAppointmentRequest;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest;
import com.gamgam.backend.appointment.entity.Appointment;
import com.gamgam.backend.appointment.entity.AppointmentMember;
import com.gamgam.backend.appointment.entity.AppointmentPlaceVote;
import com.gamgam.backend.appointment.entity.AppointmentTimeVote;
import com.gamgam.backend.appointment.repository.AppointmentMemberRepository;
import com.gamgam.backend.appointment.repository.AppointmentPlaceVoteRepository;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.repository.AppointmentTimeVoteRepository;
import com.gamgam.backend.appointment.repository.PenaltyAgreementRepository;
import com.gamgam.backend.appointment.entity.PenaltyAgreement;
import com.gamgam.backend.appointment.vo.AppointmentMemberRole;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.vo.LocationSharingPolicy;
import com.gamgam.backend.appointment.vo.PenaltyRule;
import com.gamgam.backend.appointment.vo.Place;
import com.gamgam.backend.appointment.vo.RewardRule;
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import com.gamgam.backend.global.util.KstTimeConverter;
import com.gamgam.backend.room.RoomAccess;
import com.gamgam.backend.user.entity.User;
import com.gamgam.backend.user.repository.UserRepository;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AppointmentService {

    private final AppointmentRepository repository;
    private final AppointmentMemberRepository memberRepository;
    private final AppointmentTimeVoteRepository timeVoteRepository;
    private final AppointmentPlaceVoteRepository placeVoteRepository;
    private final PenaltyAgreementRepository penaltyAgreementRepository;
    private final UserRepository userRepository;
    private final ShareLinkGenerator shareLinkGenerator;
    private final RoomAccess rooms;

    @Transactional
    public AppointmentResponse create(String roomId, String userId, CreateAppointmentRequest request) {
        if (roomId == null || roomId.isBlank()) throw new BusinessException(ErrorCode.BAD_REQUEST);
        rooms.requireMember(roomId, userId);
        User host = findUser(userId);
        Place confirmedPlace = request.confirmedPlace() == null ? null : request.confirmedPlace().toDomain();
        PenaltyRule penalty = request.penalty() == null ? null : request.penalty().toDomain();
        RewardRule reward = request.reward() == null ? null : request.reward().toDomain();
        LocationSharingPolicy sharing = request.locationSharing() == null
                ? LocationSharingPolicy.defaults() : request.locationSharing().toDomain();
        AppointmentStatus status = request.template().isFullyDecided()
                ? AppointmentStatus.CONFIRMED : AppointmentStatus.COORDINATING;

        Appointment appointment = repository.save(Appointment.builder()
                .id(UUID.randomUUID().toString())
                .name(request.name().trim())
                .roomId(roomId)
                .hostId(userId)
                .inviteCode(generateInviteCode())
                .template(request.template())
                .candidatesTime(KstTimeConverter.toUtc(request.candidatesTime()))
                .confirmedTime(KstTimeConverter.toUtc(request.confirmedTime()))
                .candidatesPlace(toDomainPlaces(request.candidatesPlace()))
                .confirmedPlace(confirmedPlace)
                .penalty(penalty)
                .reward(reward)
                .locationSharing(sharing)
                .status(status)
                .build());
        memberRepository.save(new AppointmentMember(
                UUID.randomUUID().toString(), appointment, host, AppointmentMemberRole.HOST));
        return toResponse(appointment);
    }

    public AppointmentResponse get(String userId, String id) {
        Appointment appointment = findAccessible(userId, id);
        rooms.requireMember(appointment.getRoomId(), userId);
        return toResponse(appointment);
    }

    public List<AppointmentResponse> list(String userId) {
        return repository.findAllForUser(userId).stream().map(this::toResponse).toList();
    }

    public List<AppointmentResponse> list(String roomId, String userId) {
        rooms.requireMember(roomId, userId);
        return repository.findAllForUserInRoom(roomId, userId).stream().map(this::toResponse).toList();
    }

    @Transactional
    public AppointmentResponse join(String userId, String inviteCode) {
        Appointment appointment = repository.findByInviteCode(inviteCode.trim().toUpperCase(Locale.ROOT))
                .orElseThrow(() -> new BusinessException(ErrorCode.INVALID_INVITE_CODE));
        if (memberRepository.existsByAppointmentIdAndUserId(appointment.getId(), userId)) {
            throw new BusinessException(ErrorCode.ALREADY_JOINED);
        }
        memberRepository.save(new AppointmentMember(UUID.randomUUID().toString(), appointment,
                findUser(userId), AppointmentMemberRole.MEMBER));
        return toResponse(appointment);
    }

    @Transactional
    public void leave(String userId, String appointmentId) {
        Appointment appointment = findAccessible(userId, appointmentId);
        if (appointment.getHostId().equals(userId)) {
            throw new BusinessException(ErrorCode.HOST_CANNOT_LEAVE);
        }
        removeMemberData(appointmentId, userId);
    }

    @Transactional
    public void removeMember(String hostId, String appointmentId, String memberId) {
        Appointment appointment = findAccessible(hostId, appointmentId);
        requireHost(appointment, hostId);
        if (appointment.getHostId().equals(memberId)) {
            throw new BusinessException(ErrorCode.HOST_CANNOT_LEAVE);
        }
        if (!memberRepository.existsByAppointmentIdAndUserId(appointmentId, memberId)) {
            throw new BusinessException(ErrorCode.MEMBER_NOT_FOUND);
        }
        removeMemberData(appointmentId, memberId);
    }

    @Transactional
    public AppointmentResponse toggleTimeVote(String userId, String appointmentId, int optionIndex) {
        Appointment appointment = findAccessible(userId, appointmentId);
        requireCoordinating(appointment);
        validateIndex(optionIndex, appointment.getCandidatesTime().size());
        timeVoteRepository.findByAppointmentIdAndUserIdAndOptionIndex(appointmentId, userId, optionIndex)
                .ifPresentOrElse(timeVoteRepository::delete,
                        () -> timeVoteRepository.save(new AppointmentTimeVote(appointmentId, userId, optionIndex)));
        return toResponse(appointment);
    }

    @Transactional
    public AppointmentResponse votePlace(String userId, String appointmentId, int optionIndex) {
        Appointment appointment = findAccessible(userId, appointmentId);
        requireCoordinating(appointment);
        validateIndex(optionIndex, appointment.getCandidatesPlace().size());
        placeVoteRepository.findByAppointmentIdAndUserId(appointmentId, userId)
                .ifPresent(placeVoteRepository::delete);
        placeVoteRepository.flush();
        placeVoteRepository.save(new AppointmentPlaceVote(appointmentId, userId, optionIndex));
        return toResponse(appointment);
    }

    @Transactional
    public AppointmentResponse clearPlaceVote(String userId, String appointmentId) {
        Appointment appointment = findAccessible(userId, appointmentId);
        requireCoordinating(appointment);
        placeVoteRepository.deleteAllByAppointmentIdAndUserId(appointmentId, userId);
        return toResponse(appointment);
    }

    @Transactional
    public AppointmentResponse confirm(String userId, String appointmentId, ConfirmAppointmentRequest request) {
        Appointment appointment = findAccessible(userId, appointmentId);
        requireHost(appointment, userId);
        requireCoordinating(appointment);
        Integer timeIndex = request.timeOptionIndex();
        Integer placeIndex = request.placeOptionIndex();
        if (appointment.getTemplate().coordinatesTime()) {
            validateNullableIndex(timeIndex, appointment.getCandidatesTime().size());
        }
        if (appointment.getTemplate().coordinatesPlace()) {
            validateNullableIndex(placeIndex, appointment.getCandidatesPlace().size());
        }
        appointment.confirm(timeIndex, placeIndex);
        return toResponse(appointment);
    }

    @Transactional
    public AppointmentResponse addTimeOption(String userId, String appointmentId, java.time.OffsetDateTime time) {
        Appointment appointment = findAccessible(userId, appointmentId);
        requireCoordinating(appointment);
        if (!appointment.getTemplate().coordinatesTime()) {
            throw new BusinessException(ErrorCode.BAD_REQUEST);
        }
        appointment.addCandidateTime(KstTimeConverter.toUtc(time));
        return toResponse(appointment);
    }

    @Transactional
    public AppointmentResponse setPenalty(String userId, String appointmentId,
                                          CreateAppointmentRequest.PenaltyRequest request) {
        Appointment appointment = findAccessible(userId, appointmentId);
        requireHost(appointment, userId);
        appointment.updatePenalty(request.toDomain());
        penaltyAgreementRepository.deleteAllByAppointmentIdAndUserId(appointmentId, userId);
        penaltyAgreementRepository.save(new PenaltyAgreement(appointmentId, userId));
        return toResponse(appointment);
    }

    @Transactional
    public AppointmentResponse togglePenaltyAgreement(String userId, String appointmentId) {
        Appointment appointment = findAccessible(userId, appointmentId);
        if (appointment.getPenalty() == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST);
        }
        penaltyAgreementRepository.findByAppointmentIdAndUserId(appointmentId, userId)
                .ifPresentOrElse(penaltyAgreementRepository::delete,
                        () -> penaltyAgreementRepository.save(new PenaltyAgreement(appointmentId, userId)));
        return toResponse(appointment);
    }

    @Transactional
    public AppointmentResponse complete(String userId, String appointmentId) {
        Appointment appointment = findAccessible(userId, appointmentId);
        requireHost(appointment, userId);
        if (appointment.getStatus() != AppointmentStatus.CONFIRMED) {
            throw new BusinessException(ErrorCode.BAD_REQUEST);
        }
        appointment.complete();
        return toResponse(appointment);
    }

    public boolean isMember(String appointmentId, String userId) {
        return memberRepository.existsByAppointmentIdAndUserId(appointmentId, userId);
    }

    private void removeMemberData(String appointmentId, String userId) {
        AppointmentMember member = memberRepository.findByAppointmentIdAndUserId(appointmentId, userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.MEMBER_NOT_FOUND));
        timeVoteRepository.deleteAllByAppointmentIdAndUserId(appointmentId, userId);
        placeVoteRepository.deleteAllByAppointmentIdAndUserId(appointmentId, userId);
        penaltyAgreementRepository.deleteAllByAppointmentIdAndUserId(appointmentId, userId);
        memberRepository.delete(member);
    }

    private Appointment findAccessible(String userId, String id) {
        Appointment appointment = repository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.APPOINTMENT_NOT_FOUND));
        if (!memberRepository.existsByAppointmentIdAndUserId(id, userId)) {
            throw new BusinessException(ErrorCode.APPOINTMENT_ACCESS_DENIED);
        }
        return appointment;
    }

    private User findUser(String userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
    }

    private static void requireHost(Appointment appointment, String userId) {
        if (!appointment.getHostId().equals(userId)) {
            throw new BusinessException(ErrorCode.APPOINTMENT_HOST_ONLY);
        }
    }

    private static void requireCoordinating(Appointment appointment) {
        if (appointment.getStatus() != AppointmentStatus.COORDINATING) {
            throw new BusinessException(ErrorCode.BAD_REQUEST);
        }
    }

    private static void validateNullableIndex(Integer index, int size) {
        if (index == null) {
            throw new BusinessException(ErrorCode.INVALID_VOTE_OPTION);
        }
        validateIndex(index, size);
    }

    private static void validateIndex(int index, int size) {
        if (index < 0 || index >= size) {
            throw new BusinessException(ErrorCode.INVALID_VOTE_OPTION);
        }
    }

    private String generateInviteCode() {
        String code;
        do {
            code = UUID.randomUUID().toString().replace("-", "").substring(0, 8).toUpperCase(Locale.ROOT);
        } while (repository.existsByInviteCode(code));
        return code;
    }

    private AppointmentResponse toResponse(Appointment appointment) {
        List<AppointmentMemberResponse> members = memberRepository
                .findAllByAppointmentIdOrderByJoinedAtAsc(appointment.getId()).stream()
                .map(AppointmentMemberResponse::from).toList();
        Map<Integer, List<String>> timeVotes = new LinkedHashMap<>();
        timeVoteRepository.findAllByAppointmentId(appointment.getId()).forEach(vote ->
                timeVotes.computeIfAbsent(vote.getOptionIndex(), ignored -> new ArrayList<>()).add(vote.getUserId()));
        Map<Integer, List<String>> placeVotes = new LinkedHashMap<>();
        placeVoteRepository.findAllByAppointmentId(appointment.getId()).forEach(vote ->
                placeVotes.computeIfAbsent(vote.getOptionIndex(), ignored -> new ArrayList<>()).add(vote.getUserId()));
        List<String> agreements = penaltyAgreementRepository.findAllByAppointmentId(appointment.getId()).stream()
                .map(PenaltyAgreement::getUserId).toList();
        return AppointmentResponse.of(appointment, shareLinkGenerator.create(appointment.getInviteCode()),
                members, timeVotes, placeVotes, agreements);
    }

    private static List<Place> toDomainPlaces(List<CreateAppointmentRequest.PlaceRequest> requests) {
        return requests == null ? null : requests.stream().map(CreateAppointmentRequest.PlaceRequest::toDomain).toList();
    }
}
