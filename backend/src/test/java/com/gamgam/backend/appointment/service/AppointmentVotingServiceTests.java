package com.gamgam.backend.appointment.service;

import static com.gamgam.backend.appointment.AppointmentFixtures.*;
import static org.assertj.core.api.Assertions.*;

import com.gamgam.backend.appointment.dto.AppointmentVotingResponse;
import com.gamgam.backend.appointment.repository.AppointmentParticipantRepository;
import com.gamgam.backend.appointment.repository.AppointmentVoteRepository;
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import org.assertj.core.api.ThrowableAssert.ThrowingCallable;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class AppointmentVotingServiceTests {
    private static final String USER = "u-yeeun";
    private static final String OTHER = "u-doyun";
    @Autowired AppointmentVotingService service;
    @Autowired AppointmentService appointments;
    @Autowired AppointmentParticipantRepository participants;
    @Autowired AppointmentVoteRepository votes;
    private String id;

    @BeforeEach
    void setUp() {
        id = appointments.create("demo-room", USER, both()).id();
    }

    @Test
    void 시간만_복수_투표해도_신청되고_재요청은_중복되지_않는다() {
        assertThat(service.get(id, USER).participating()).isFalse();
        service.voteTime(id, USER, Set.of(0, 1));
        var response = service.voteTime(id, USER, Set.of(0, 1));
        assertThat(response.participating()).isTrue();
        assertThat(response.participantIds()).containsExactly(USER);
        assertThat(response.timeOptions()).allSatisfy(option -> {
            assertThat(option.voteCount()).isEqualTo(1);
            assertThat(option.votedByMe()).isTrue();
            assertThat(option.time().getOffset().getTotalSeconds()).isEqualTo(9 * 3600);
        });
        assertThat(response.placeOptions()).allMatch(option -> option.voteCount() == 0);
    }

    @Test
    void 장소만_복수_투표해도_신청되고_내_선택만_교체된다() {
        service.votePlace(id, USER, Set.of(0, 1));
        service.votePlace(id, OTHER, Set.of(0));
        var response = service.votePlace(id, USER, Set.of(1));
        assertThat(response.participating()).isTrue();
        assertThat(response.placeOptions().get(0).voterIds()).containsExactly(OTHER);
        assertThat(response.placeOptions().get(1).voterIds()).containsExactly(USER);
        assertThat(response.participantIds()).containsExactlyInAnyOrder(USER, OTHER);
    }

    @Test
    void 다른_종류의_표가_남으면_신청을_유지하고_마지막_표를_취소하면_신청도_취소된다() {
        service.voteTime(id, USER, Set.of(0));
        service.votePlace(id, USER, Set.of(1));
        assertThat(service.voteTime(id, USER, Set.of()).participating()).isTrue();
        var response = service.votePlace(id, USER, Set.of());
        assertThat(response.participating()).isFalse();
        assertThat(response.participantIds()).isEmpty();
        assertThat(participants.findByAppointmentIdAndUserId(id, USER)).isEmpty();
        assertThat(votes.findByAppointmentIdOrderByIdAsc(id)).isEmpty();
        assertThat(service.votePlace(id, USER, Set.of()).participating()).isFalse();
    }

    @Test
    void 상관없이_참여는_시간과_장소_표를_모두_지우고_신청한다() {
        service.voteTime(id, USER, Set.of(0, 1));
        service.votePlace(id, USER, Set.of(0, 1));
        service.voteTime(id, OTHER, Set.of(0));
        var response = service.participateRegardless(id, USER, true);
        assertThat(response.participating()).isTrue();
        assertThat(response.participatingRegardless()).isTrue();
        assertThat(response.regardlessParticipantIds()).containsExactly(USER);
        assertThat(response.timeOptions()).noneMatch(AppointmentVotingResponse.TimeOption::votedByMe);
        assertThat(response.placeOptions()).allMatch(option -> option.voteCount() == 0);
        assertThat(response.timeOptions().get(0).voterIds()).containsExactly(OTHER);
        assertThat(service.participateRegardless(id, USER, true).participantIds()).hasSize(2);
        assertThat(service.participateRegardless(id, USER, false).participantIds()).containsExactly(OTHER);
    }

    @Test
    void 상관없이_참여에서_후보를_선택하면_후보_투표로_전환된다() {
        service.participateRegardless(id, USER, true);
        // 이미 비어 있는 후보 표의 취소는 상관없이 참여 선택을 해제하지 않는다.
        assertThat(service.voteTime(id, USER, Set.of()).participatingRegardless()).isTrue();
        var response = service.votePlace(id, USER, Set.of(0, 1));
        assertThat(response.participating()).isTrue();
        assertThat(response.participatingRegardless()).isFalse();
        assertThat(response.regardlessParticipantIds()).isEmpty();
        assertThat(response.placeOptions()).allMatch(AppointmentVotingResponse.PlaceOption::votedByMe);
    }

    @Test
    void 잘못된_후보는_기존_투표와_상관없이_참여를_변경하지_않는다() {
        service.voteTime(id, USER, Set.of(0));
        error(() -> service.voteTime(id, USER, Set.of(1, 9)), ErrorCode.INVALID_OPTION);
        assertThat(service.get(id, USER).timeOptions().get(0).votedByMe()).isTrue();
        service.participateRegardless(id, USER, true);
        error(() -> service.votePlace(id, USER, Set.of(-1)), ErrorCode.INVALID_OPTION);
        assertThat(service.get(id, USER).participatingRegardless()).isTrue();
    }

    @Test
    void 방_멤버가_아니면_조회_투표_신청을_할_수_없다() {
        error(() -> service.get(id, "outsider"), ErrorCode.ROOM_ACCESS_DENIED);
        error(() -> service.voteTime(id, "outsider", Set.of(0)), ErrorCode.ROOM_ACCESS_DENIED);
        error(() -> service.votePlace(id, "outsider", Set.of(0)), ErrorCode.ROOM_ACCESS_DENIED);
        error(() -> service.participateRegardless(id, "outsider", true), ErrorCode.ROOM_ACCESS_DENIED);
        error(() -> appointments.create("demo-room", "outsider", both()), ErrorCode.ROOM_ACCESS_DENIED);
    }

    @Test
    void 확정된_약속은_투표_신청을_변경할_수_없다() {
        String confirmed = appointments.create("demo-room", USER, all()).id();
        error(() -> service.voteTime(confirmed, USER, Set.of(0)), ErrorCode.NOT_COORDINATING);
        error(() -> service.votePlace(confirmed, USER, Set.of()), ErrorCode.NOT_COORDINATING);
        error(() -> service.participateRegardless(confirmed, USER, true), ErrorCode.NOT_COORDINATING);
    }

    @Test
    void 조율하지_않는_항목과_없는_약속은_거부한다() {
        String timeOnly = appointments.create("demo-room", USER, timeOnly()).id();
        String placeOnly = appointments.create("demo-room", USER, placeOnly()).id();
        error(() -> service.votePlace(timeOnly, USER, Set.of()), ErrorCode.VOTE_NOT_ALLOWED);
        error(() -> service.voteTime(placeOnly, USER, Set.of()), ErrorCode.VOTE_NOT_ALLOWED);
        error(() -> service.get("missing", USER), ErrorCode.APPOINTMENT_NOT_FOUND);
    }

    @Test
    void 동시_투표_교체는_서로_다른_요청의_선택을_합치지_않는다() throws Exception {
        parallel(List.of(
                () -> service.votePlace(id, USER, Set.of(0)),
                () -> service.votePlace(id, USER, Set.of(1))));
        var result = service.get(id, USER);
        assertThat(result.placeOptions().stream().filter(AppointmentVotingResponse.PlaceOption::votedByMe)).hasSize(1);
        assertThat(result.participantIds()).containsExactly(USER);
    }

    @Test
    void 상관없이_참여와_후보_투표가_겹쳐도_둘이_동시에_남지_않는다() throws Exception {
        parallel(List.of(
                () -> service.participateRegardless(id, USER, true),
                () -> service.voteTime(id, USER, Set.of(0))));
        var result = service.get(id, USER);
        assertThat(result.participantIds()).containsExactly(USER);
        assertThat(result.participatingRegardless() ^ result.timeOptions().get(0).votedByMe()).isTrue();
    }

    private static void error(ThrowingCallable action, ErrorCode expected) {
        assertThatThrownBy(action).isInstanceOfSatisfying(BusinessException.class,
                ex -> assertThat(ex.errorCode()).isEqualTo(expected));
    }

    private static void parallel(List<Callable<AppointmentVotingResponse>> operations) throws Exception {
        var ready = new CountDownLatch(operations.size());
        var start = new CountDownLatch(1);
        try (var executor = Executors.newFixedThreadPool(operations.size())) {
            List<Future<AppointmentVotingResponse>> futures = new ArrayList<>();
            for (var operation : operations) futures.add(executor.submit(() -> {
                ready.countDown();
                if (!start.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("Start timed out");
                return operation.call();
            }));
            try {
                assertThat(ready.await(10, TimeUnit.SECONDS)).isTrue();
            } finally {
                start.countDown();
            }
            for (var future : futures) future.get(20, TimeUnit.SECONDS);
        }
    }
}
