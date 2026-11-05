package com.gamgam.backend.appointment.service;

import com.gamgam.backend.appointment.dto.AppointmentMemberResponse;
import com.gamgam.backend.appointment.dto.AppointmentResponse;
import com.gamgam.backend.appointment.dto.ConfirmAppointmentRequest;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest;
import com.gamgam.backend.appointment.entity.Appointment;
import com.gamgam.backend.appointment.entity.AppointmentMember;
import com.gamgam.backend.appointment.vo.VoteType;

import com.gamgam.backend.appointment.repository.AppointmentMemberRepository;
import com.gamgam.backend.appointment.repository.AppointmentVoteRepository;
import com.gamgam.backend.appointment.repository.AppointmentRepository;

import com.gamgam.backend.appointment.repository.PenaltyAgreementRepository;
import com.gamgam.backend.appointment.entity.PenaltyAgreement;
import com.gamgam.backend.appointment.vo.AppointmentMemberRole;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.vo.AppointmentTemplate;
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
    private final AppointmentVoteRepository voteRepository;

    private final PenaltyAgreementRepository penaltyAgreementRepository;
    private final UserRepository userRepository;
    private final ShareLinkGenerator shareLinkGenerator;
    private final RoomAccess rooms;
    private final AppointmentParticipationService participation;

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
        AppointmentTemplate template = request.template() == null ? AppointmentTemplate.BOTH : request.template();
        AppointmentStatus status = template.isFullyDecided()
                ? AppointmentStatus.CONFIRMED : AppointmentStatus.COORDINATING;

        Appointment appointment = repository.save(Appointment.builder()
                .id(UUID.randomUUID().toString())
                .name(request.name().trim())
                .roomId(roomId)
                .hostId(userId)
                .inviteCode(generateInviteCode())
                .template(template)
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
        Appointment appointment = repository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.APPOINTMENT_NOT_FOUND));
        rooms.requireMember(appointment.getRoomId(), userId);
        return toResponse(appointment);
    }

    public List<AppointmentResponse> list(String userId) {
        return repository.findAllForUser(userId).stream().map(this::toResponse).toList();
    }

    public List<AppointmentResponse> list(String roomId, String userId) {
        rooms.requireMember(roomId, userId);
        return repository.findByRoomIdOrderByCreatedAtDesc(roomId).stream().map(this::toResponse).toList();
    }

    @Transactional
    public AppointmentResponse join(String userId, String inviteCode) {
        Appointment appointment = repository.findByInviteCode(inviteCode.trim().toUpperCase(Locale.ROOT))
                .orElseThrow(() -> new BusinessException(ErrorCode.INVALID_INVITE_CODE));
        appointment = repository.findByIdForUpdate(appointment.getId())
                .orElseThrow(() -> new BusinessException(ErrorCode.APPOINTMENT_NOT_FOUND));
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
    public AppointmentResponse confirm(String userId, String appointmentId, ConfirmAppointmentRequest request) {
        Appointment appointment = findAccessible(userId, appointmentId);
        requireHost(appointment, userId);
        requireCoordinating(appointment);
        if (appointment.getTemplate().coordinatesTime() && appointment.getConfirmedTime() == null) {
            confirmOption(appointment, VoteType.TIME, request.timeOptionIndex());
        }
        if (appointment.getTemplate().coordinatesPlace() && appointment.getConfirmedPlace() == null) {
            confirmOption(appointment, VoteType.PLACE, request.placeOptionIndex());
        }
        return toResponse(appointment);
    }

    @Transactional
    public AppointmentResponse confirmOption(String userId, String id, VoteType type, Integer index) {
        Appointment appointment = findAccessible(userId, id);
        rooms.requireMember(appointment.getRoomId(), userId);
        requireHost(appointment, userId);
        requireCoordinating(appointment);
        confirmOption(appointment, type, index);
        return toResponse(appointment);
    }

    private void confirmOption(Appointment appointment, VoteType type, Integer index) {
        boolean time = type == VoteType.TIME;
        if (time && (!appointment.getTemplate().coordinatesTime() || appointment.getConfirmedTime() != null)
                || !time && (!appointment.getTemplate().coordinatesPlace() || appointment.getConfirmedPlace() != null)) {
            throw new BusinessException(ErrorCode.VOTE_NOT_ALLOWED);
        }
        int size = appointment.getCandidatesTime().size();
        if (!time) size = appointment.getCandidatesPlace().size();
        if (size == 0) throw new BusinessException(ErrorCode.INVALID_OPTION);
        if (index == null) {
            int[] counts = new int[size];
            voteRepository.findByAppointmentIdOrderByIdAsc(appointment.getId()).stream()
                    .filter(vote -> vote.getType() == type)
                    .forEach(vote -> counts[vote.getOptionIndex()]++);
            index = 0;
            for (int candidate = 1; candidate < size; candidate++) {
                if (counts[candidate] > counts[index]) index = candidate;
            }
        }
        validateIndex(index, size);
        if (time) appointment.confirmTime(index);
        else appointment.confirmPlace(index);
    }
    @Transactional
    public AppointmentResponse setPenalty(String userId, String appointmentId,
                                          CreateAppointmentRequest.PenaltyRequest request) {
        Appointment appointment = findAccessible(userId, appointmentId);
        requireHost(appointment, userId);
        appointment.updatePenalty(request.toDomain());
        if (penaltyAgreementRepository.findByAppointmentIdAndUserId(appointmentId, userId).isEmpty()) {
            penaltyAgreementRepository.save(new PenaltyAgreement(appointmentId, userId));
        }
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

    @Transactional
    public AppointmentResponse rename(String userId, String appointmentId, String name) {
        Appointment appointment = findAccessible(userId, appointmentId);
        rooms.requireMember(appointment.getRoomId(), userId);
        requireHost(appointment, userId);
        if (name == null || name.isBlank() || name.strip().length() > 50) {
            throw new BusinessException(ErrorCode.BAD_REQUEST);
        }
        appointment.rename(name.strip());
        return toResponse(appointment);
    }

    public boolean isMember(String appointmentId, String userId) {
        return memberRepository.existsByAppointmentIdAndUserId(appointmentId, userId);
    }

    private void removeMemberData(String appointmentId, String userId) {
        AppointmentMember member = memberRepository.findByAppointmentIdAndUserId(appointmentId, userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.MEMBER_NOT_FOUND));
        participation.remove(member);
    }

    private Appointment findAccessible(String userId, String id) {
        Appointment appointment = repository.findByIdForUpdate(id)
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
        var allVotes = voteRepository.findByAppointmentIdOrderByIdAsc(appointment.getId());
        Map<Integer, List<String>> timeVotes = new LinkedHashMap<>();
        allVotes.stream().filter(vote -> vote.getType() == VoteType.TIME).forEach(vote ->
                timeVotes.computeIfAbsent(vote.getOptionIndex(), ignored -> new ArrayList<>()).add(vote.getUserId()));
        Map<Integer, List<String>> placeVotes = new LinkedHashMap<>();
        allVotes.stream().filter(vote -> vote.getType() == VoteType.PLACE).forEach(vote ->
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
