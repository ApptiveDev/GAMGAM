package com.gamgam.backend.api.v1;

import static com.gamgam.backend.appointment.AppointmentFixtures.both;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.gamgam.backend.appointment.entity.AppointmentVote;
import com.gamgam.backend.appointment.entity.AppointmentParticipant;
import com.gamgam.backend.appointment.repository.*;
import com.gamgam.backend.appointment.service.AppointmentService;
import com.gamgam.backend.auth.security.JwtTokenProvider;
import com.gamgam.backend.user.entity.User;
import com.gamgam.backend.user.repository.UserRepository;
import com.gamgam.backend.room.CreateRoomRequest;
import com.gamgam.backend.room.RoomMember;
import com.gamgam.backend.room.RoomMemberRepository;
import com.gamgam.backend.room.RoomRepository;
import com.gamgam.backend.room.RoomService;
import java.util.UUID;
import com.gamgam.backend.appointment.vo.VoteType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Transactional
class AppointmentVotingReadTests {
    @Autowired WebApplicationContext context;
    @Autowired AppointmentService service;
    @Autowired AppointmentRepository appointments;
    @Autowired AppointmentVoteRepository votes;
    @Autowired AppointmentParticipantRepository participants;
    @Autowired JwtTokenProvider tokens;
    @Autowired UserRepository users;
    @Autowired RoomService rooms;
    @Autowired RoomRepository roomRepository;
    @Autowired RoomMemberRepository roomMembers;
    private String roomId;

    private String bearer(String userId) {
        return "Bearer " + tokens.create(users.findById(userId).orElseThrow()).value();
    }

    private void setUpUsersAndRoom() {
        for (String userId : new String[]{"u-yeeun", "u-doyun", "outsider"}) {
            users.save(User.builder().id(userId).email(userId + "@voting.test")
                    .name(userId).passwordHash("unused").build());
        }
        roomId = rooms.create("u-yeeun", new CreateRoomRequest("Voting test room")).id();
        roomMembers.save(new RoomMember(UUID.randomUUID().toString(),
                roomRepository.findById(roomId).orElseThrow(), users.findById("u-doyun").orElseThrow()));
    }

    private MockMvc mvc;
    private String id;

    @BeforeEach
    void setUp() {
        setUpUsersAndRoom();
        mvc = MockMvcBuilders.webAppContextSetup(context)
                .defaultRequest(get("/").header("Authorization", bearer("u-yeeun"))).build();
        id = service.create(roomId, "u-yeeun", both()).id();
    }

    @Test
    void emptyVotesStillReturnAllCandidates() throws Exception {
        mvc.perform(get("/api/v1/appointments/" + id + "/votes"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.roomId").value(roomId))
                .andExpect(jsonPath("$.data.participating").value(false))
                .andExpect(jsonPath("$.data.participantIds").isEmpty())
                .andExpect(jsonPath("$.data.timeOptions.length()").value(2))
                .andExpect(jsonPath("$.data.timeOptions[0].voteCount").value(0))
                .andExpect(jsonPath("$.data.placeOptions.length()").value(2));
    }

    @Test
    void storedVotesAreGroupedByCandidateAndCurrentUser() throws Exception {
        var appointment = appointments.findById(id).orElseThrow();
        votes.save(new AppointmentVote(appointment, "u-yeeun", VoteType.TIME, 0));
        votes.save(new AppointmentVote(appointment, "u-doyun", VoteType.TIME, 0));
        votes.save(new AppointmentVote(appointment, "u-doyun", VoteType.PLACE, 1));
        participants.save(new AppointmentParticipant(appointment, "u-yeeun"));
        participants.save(new AppointmentParticipant(appointment, "u-doyun"));
        var regardless = new AppointmentParticipant(appointment, "u-seoa");
        regardless.setRegardlessOfTimeAndPlace(true);
        participants.save(regardless);
        var otherId = service.create(roomId, "u-yeeun", both()).id();
        votes.save(new AppointmentVote(appointments.findById(otherId).orElseThrow(),
                "u-harin", VoteType.TIME, 0));

        mvc.perform(get("/api/v1/appointments/" + id + "/votes").header("Authorization", bearer("u-yeeun")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.participating").value(true))
                .andExpect(jsonPath("$.data.participantIds.length()").value(3))
                .andExpect(jsonPath("$.data.participatingRegardless").value(false))
                .andExpect(jsonPath("$.data.regardlessParticipantIds[0]").value("u-seoa"))
                .andExpect(jsonPath("$.data.timeOptions[0].voteCount").value(2))
                .andExpect(jsonPath("$.data.timeOptions[0].votedByMe").value(true))
                .andExpect(jsonPath("$.data.timeOptions[0].time", org.hamcrest.Matchers.endsWith("+09:00")))
                .andExpect(jsonPath("$.data.timeOptions[1].voteCount").value(0))
                .andExpect(jsonPath("$.data.placeOptions[0].voteCount").value(0))
                .andExpect(jsonPath("$.data.placeOptions[1].voterIds[0]").value("u-doyun"))
                .andExpect(jsonPath("$.data.placeOptions[1].votedByMe").value(false));
    }

    @Test
    void outsiderAndMissingAppointmentAreRejected() throws Exception {
        mvc.perform(get("/api/v1/appointments/" + id + "/votes").header("Authorization", bearer("outsider")))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("ROOM_ACCESS_DENIED"));
        mvc.perform(get("/api/v1/appointments/missing/votes"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("APPOINTMENT_NOT_FOUND"));
    }
}
