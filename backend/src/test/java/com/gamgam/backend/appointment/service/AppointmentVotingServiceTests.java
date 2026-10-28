package com.gamgam.backend.appointment.service;

import static com.gamgam.backend.appointment.AppointmentFixtures.*;
import static org.assertj.core.api.Assertions.*;

import com.gamgam.backend.appointment.dto.AppointmentVotingResponse;
import com.gamgam.backend.appointment.dto.TimeCandidateRequest;
import java.time.ZoneOffset;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest.PlaceRequest;
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
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

@SpringBootTest
class AppointmentVotingServiceTests {
    private static final String USER = "u-yeeun";
    private static final String OTHER = "u-doyun";
    @Autowired AppointmentVotingService service;
    @Autowired AppointmentService appointments;
    @Autowired AppointmentParticipantRepository participants;
    @Autowired AppointmentVoteRepository votes;
    @Autowired PlatformTransactionManager transactionManager;
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
    void 후보_추가만으로_신청되지_않고_새_후보에_투표할_수_있다() {
        var proposed = service.addPlaceCandidate(id, USER, new PlaceRequest("  새 카페  ", 37.5, 127.0));
        assertThat(proposed.participating()).isFalse();
        assertThat(proposed.placeOptions()).hasSize(3);
        assertThat(proposed.placeOptions().get(2).place().name()).isEqualTo("새 카페");
        assertThat(proposed.placeOptions().get(2).voteCount()).isZero();
        assertThat(service.votePlace(id, USER, Set.of(2)).placeOptions().get(2).votedByMe()).isTrue();
        assertThat(service.get(id, OTHER).placeOptions().get(2).voterIds()).containsExactly(USER);
    }

    @Test
    void 같은_장소_제안은_거부하고_좌표가_다른_동명_장소는_허용한다() {
        service.addPlaceCandidate(id, USER, new PlaceRequest("Cafe", 37.5, 127.0));
        error(() -> service.addPlaceCandidate(id, OTHER, new PlaceRequest(" cafe ", 37.5, 127.0)),
                ErrorCode.DUPLICATE_CANDIDATE);
        assertThat(service.addPlaceCandidate(id, OTHER, new PlaceRequest("Cafe", 37.6, 127.0)).placeOptions()).hasSize(4);
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
    void 방_멤버가_아니면_조회_투표_제안_신청을_할_수_없다() {
        error(() -> service.get(id, "outsider"), ErrorCode.ROOM_ACCESS_DENIED);
        error(() -> service.voteTime(id, "outsider", Set.of(0)), ErrorCode.ROOM_ACCESS_DENIED);
        error(() -> service.votePlace(id, "outsider", Set.of(0)), ErrorCode.ROOM_ACCESS_DENIED);
        error(() -> service.addPlaceCandidate(id, "outsider", place("다른 장소")), ErrorCode.ROOM_ACCESS_DENIED);
        error(() -> service.participateRegardless(id, "outsider", true), ErrorCode.ROOM_ACCESS_DENIED);
        error(() -> appointments.create("demo-room", "outsider", both()), ErrorCode.ROOM_ACCESS_DENIED);
    }

    @Test
    void 확정된_약속은_투표_제안_신청을_변경할_수_없다() {
        String confirmed = appointments.create("demo-room", USER, all()).id();
        error(() -> service.voteTime(confirmed, USER, Set.of(0)), ErrorCode.NOT_COORDINATING);
        error(() -> service.votePlace(confirmed, USER, Set.of()), ErrorCode.NOT_COORDINATING);
        error(() -> service.addPlaceCandidate(confirmed, USER, place("다른 장소")), ErrorCode.NOT_COORDINATING);
        error(() -> service.participateRegardless(confirmed, USER, true), ErrorCode.NOT_COORDINATING);
    }

    @Test
    void 조율하지_않는_항목과_없는_약속은_거부한다() {
        String timeOnly = appointments.create("demo-room", USER, timeOnly()).id();
        String placeOnly = appointments.create("demo-room", USER, placeOnly()).id();
        error(() -> service.votePlace(timeOnly, USER, Set.of()), ErrorCode.VOTE_NOT_ALLOWED);
        error(() -> service.addPlaceCandidate(timeOnly, USER, place("다른 장소")), ErrorCode.VOTE_NOT_ALLOWED);
        error(() -> service.voteTime(placeOnly, USER, Set.of()), ErrorCode.VOTE_NOT_ALLOWED);
        error(() -> service.get("missing", USER), ErrorCode.APPOINTMENT_NOT_FOUND);
    }

    @Test
    void 같은_방의_다른_약속에_투표와_신청이_섞이지_않는다() {
        String otherId = appointments.create("demo-room", USER, both()).id();
        service.voteTime(id, USER, Set.of(0));
        service.addPlaceCandidate(id, USER, place("추가 장소"));
        var other = service.get(otherId, USER);
        assertThat(other.participantIds()).isEmpty();
        assertThat(other.timeOptions()).allMatch(option -> option.voteCount() == 0);
        assertThat(other.placeOptions()).hasSize(2);
    }

    @Test
    void 생성과_후보_추가를_같은_트랜잭션에서_해도_불변_리스트_오류가_없다() {
        new TransactionTemplate(transactionManager).executeWithoutResult(status -> {
            String created = appointments.create("demo-room", USER, both()).id();
            assertThat(service.addPlaceCandidate(created, USER, place("추가 장소")).placeOptions()).hasSize(3);
            status.setRollbackOnly();
        });
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
    void 동시_후보_추가는_기존_순서를_유지하고_서로_다른_인덱스를_받는다() throws Exception {
        parallel(List.of(
                () -> service.addPlaceCandidate(id, USER, place("추가 A")),
                () -> service.addPlaceCandidate(id, OTHER, place("추가 B"))));
        var result = service.get(id, USER);
        assertThat(result.placeOptions()).extracting(option -> option.place().name())
                .startsWith("성수 카페거리", "서울숲").contains("추가 A", "추가 B");
        assertThat(result.placeOptions()).extracting(AppointmentVotingResponse.PlaceOption::index).containsExactly(0, 1, 2, 3);
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

    @Test
    void 시간_후보_추가는_기존_순서와_투표를_보존하고_자동_신청하지_않는다() {
        service.voteTime(id, OTHER, Set.of(0));
        var before = service.get(id, USER);
        var time = future(5);
        var added = service.addTimeCandidate(id, USER, new TimeCandidateRequest(time));
        assertThat(added.participating()).isFalse();
        assertThat(added.participantIds()).containsExactly(OTHER);
        assertThat(added.timeOptions()).hasSize(3);
        assertThat(added.timeOptions().subList(0, 2)).isEqualTo(before.timeOptions());
        assertThat(added.timeOptions().get(2).time().toInstant()).isEqualTo(time.toInstant());
        assertThat(added.timeOptions().get(2).time().getOffset()).isEqualTo(ZoneOffset.ofHours(9));
        assertThat(added.timeOptions().get(2).voteCount()).isZero();
        assertThat(service.voteTime(id, USER, Set.of(2)).timeOptions().get(2).votedByMe()).isTrue();
    }

    @Test
    void 시간_오프셋이_달라도_같은_순간이면_중복이다() {
        var time = future(5);
        service.addTimeCandidate(id, USER, new TimeCandidateRequest(time));
        error(() -> service.addTimeCandidate(id, OTHER,
                new TimeCandidateRequest(time.withOffsetSameInstant(ZoneOffset.ofHours(-4)))),
                ErrorCode.DUPLICATE_CANDIDATE);
        assertThat(service.get(id, USER).timeOptions()).hasSize(3);
    }

    @Test
    void 시간_후보_추가도_권한_상태_템플릿과_미래시각을_검사한다() {
        var request = new TimeCandidateRequest(future(5));
        error(() -> service.addTimeCandidate(id, "outsider", request), ErrorCode.ROOM_ACCESS_DENIED);
        error(() -> service.addTimeCandidate("missing", USER, request), ErrorCode.APPOINTMENT_NOT_FOUND);
        String confirmed = appointments.create("demo-room", USER, all()).id();
        error(() -> service.addTimeCandidate(confirmed, USER, request), ErrorCode.NOT_COORDINATING);
        String placeOnly = appointments.create("demo-room", USER, placeOnly()).id();
        error(() -> service.addTimeCandidate(placeOnly, USER, request), ErrorCode.VOTE_NOT_ALLOWED);
        error(() -> service.addTimeCandidate(id, USER,
                new TimeCandidateRequest(java.time.OffsetDateTime.now().minusDays(1))), ErrorCode.BAD_REQUEST);
        error(() -> service.addTimeCandidate(id, USER, new TimeCandidateRequest(null)), ErrorCode.BAD_REQUEST);
        String timeOnly = appointments.create("demo-room", USER, timeOnly()).id();
        assertThat(service.addTimeCandidate(timeOnly, USER, request).timeOptions()).hasSize(3);
    }

    @Test
    void 생성_직후_시간_후보를_추가해도_불변_리스트_오류가_없다() {
        new TransactionTemplate(transactionManager).executeWithoutResult(status -> {
            String created = appointments.create("demo-room", USER, both()).id();
            service.participateRegardless(created, USER, true);
            var result = service.addTimeCandidate(created, USER, new TimeCandidateRequest(future(5)));
            assertThat(result.timeOptions()).hasSize(3);
            assertThat(result.participatingRegardless()).isTrue();
            status.setRollbackOnly();
        });
    }

    @Test
    void 동시_시간_후보_추가도_기존_후보를_보존한다() throws Exception {
        var first = new TimeCandidateRequest(future(5));
        var second = new TimeCandidateRequest(future(6));
        parallel(List.of(
                () -> service.addTimeCandidate(id, USER, first),
                () -> service.addTimeCandidate(id, OTHER, second)));
        var result = service.get(id, USER);
        assertThat(result.timeOptions()).extracting(AppointmentVotingResponse.TimeOption::index)
                .containsExactly(0, 1, 2, 3);
        assertThat(result.timeOptions().subList(2, 4)).extracting(option -> option.time().toInstant())
                .containsExactlyInAnyOrder(first.time().toInstant(), second.time().toInstant());
        assertThat(result.participantIds()).isEmpty();
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
