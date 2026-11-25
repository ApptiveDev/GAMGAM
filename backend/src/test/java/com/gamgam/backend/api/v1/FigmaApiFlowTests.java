package com.gamgam.backend.api.v1;

import com.fasterxml.jackson.databind.*;
import com.gamgam.backend.auth.dto.*;
import com.gamgam.backend.auth.service.AuthService;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.vo.VoteType;
import java.time.*;
import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.*;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
class FigmaApiFlowTests {
    @Autowired WebApplicationContext context;
    @Autowired AuthService auth;
    @Autowired AppointmentRepository appointments;
    @Autowired PlatformTransactionManager transactions;
    MockMvc mvc;
    ObjectMapper json=new ObjectMapper();
    String owner,other,outsider,ownerId,otherId,room,id,code;
    @BeforeEach void setup() throws Exception {
        mvc=MockMvcBuilders.webAppContextSetup(context).build();
        String[] a=account("Owner"),b=account("Other"),c=account("Outside");
        owner=a[0];ownerId=a[1];other=b[0];otherId=b[1];outsider=c[0];
        room=data(call(post("/api/v1/rooms"),owner,"{\"name\":\"Group\"}",201)).path("id").asText();
        code=data(call(get("/api/v1/rooms/"+room+"/invite"),owner,null,200)).path("inviteCode").asText();
        call(post("/api/v1/rooms/join"),other,json.writeValueAsString(Map.of("inviteCode",code)),200);
        id=data(call(post("/api/v1/rooms/"+room+"/appointments"),owner,"{\"name\":\"Hike\"}",201)).path("id").asText();
    }
    String[] account(String name) {
        String email=UUID.randomUUID()+"@figma.test";
        String uid=auth.signup(new SignupRequest(email,"password123",name)).id();
        return new String[]{auth.login(new LoginRequest(email,"password123")).accessToken(),uid};
    }
    ResultActions call(MockHttpServletRequestBuilder req,String token,String body,int statusCode) throws Exception {
        req.header("Authorization","Bearer "+token);
        if(body!=null)req.contentType(MediaType.APPLICATION_JSON).content(body);
        return mvc.perform(req).andExpect(status().is(statusCode));
    }
    JsonNode data(ResultActions r) throws Exception {return json.readTree(r.andReturn().getResponse().getContentAsString()).path("data");}
    String path(String suffix) {return "/api/v1/appointments/"+id+suffix;}
    String time(int days) throws Exception {
        var result=data(call(post(path("/time-candidates")),owner,json.writeValueAsString(Map.of("time",OffsetDateTime.now().plusDays(days).toString())),200));
        return result.path("timeOptions").get(result.path("timeOptions").size()-1).path("candidateId").asText();
    }
    void place() throws Exception {call(post(path("/place-candidates")),owner,"{\"name\":\"Cafe\",\"latitude\":37.5,\"longitude\":127.0,\"address\":\"Seoul\",\"category\":\"Cafe\"}",200);}
    String ballot(String... ids) throws Exception {return json.writeValueAsString(Map.of("candidateIds",ids));}
    String settings(boolean anonymous) {return "{\"multipleSelection\":false,\"anonymous\":"+anonymous+",\"allowAddingOptions\":false,\"durationMinutes\":30}";}

    @Test void invitationIsIdempotentRevocableAndProtected() throws Exception {
        call(post("/api/v1/rooms/join"),other,json.writeValueAsString(Map.of("inviteCode",code)),200).andExpect(jsonPath("$.data.memberCount").value(2));
        call(get("/api/v1/rooms/"+room+"/members"),outsider,null,403);
        call(get("/api/v1/rooms/"+room+"/members"),owner,null,200).andExpect(jsonPath("$.data.length()").value(2));
        call(post("/api/v1/rooms/"+room+"/invite/rotate"),other,null,403);
        call(post("/api/v1/rooms/"+room+"/invite/rotate"),owner,null,200);
        call(post("/api/v1/rooms/join"),outsider,json.writeValueAsString(Map.of("inviteCode",code)),404);
    }
    @Test void pollPermissionsSingleSelectionAndAnonymousPrivacyApplyEverywhere() throws Exception {
        String a=time(1),b=time(2);place();
        call(put(path("/polls/TIME")),other,settings(true),403);
        call(put(path("/polls/TIME")),owner,settings(true),200);
        call(put(path("/votes/time")),other,ballot(a,b),400);
        call(post(path("/time-candidates")),other,json.writeValueAsString(Map.of("time",OffsetDateTime.now().plusDays(3).toString())),403);
        call(put(path("/votes/time")),other,ballot(a),200)
                .andExpect(jsonPath("$.data.timeOptions[0].voteCount").value(1))
                .andExpect(jsonPath("$.data.timeOptions[0].voterIds.length()").value(0))
                .andExpect(jsonPath("$.data.timeOptions[0].votedByMe").value(true));
        call(get(path("")),owner,null,200).andExpect(jsonPath("$.data.timeVotes").isEmpty());
        call(get("/api/v1/home"),owner,null,200).andExpect(jsonPath("$.data.items[0].timeVotes").isEmpty());
        call(put(path("/polls/TIME")),owner,settings(false),409);
        call(get(path("/votes")),outsider,null,403);
    }
    @Test void closingOnePollDoesNotCloseTheOtherAndGiftDrawIsIdempotent() throws Exception {
        String t=time(1);place();
        String gift=settings(false).replace("}",",\"giftDescription\":\"Coffee\",\"giftMethod\":\"FIRST_COME\",\"winnerCount\":1}");
        call(put(path("/polls/TIME")),owner,gift,200);
        call(put(path("/votes/time")),other,ballot(t),200);
        call(put(path("/votes/time")),owner,ballot(t),200);
        call(put(path("/votes/time")),other,ballot(t),200); // An identical PUT must preserve first-come priority.
        call(post(path("/polls/TIME/gift/draw")),owner,null,400);
        call(post(path("/polls/TIME/close")),other,null,403);
        call(post(path("/polls/TIME/close")),owner,null,200).andExpect(jsonPath("$.data.timePoll.state").value("CLOSED"));
        call(put(path("/votes/time")),other,ballot(),409);
        call(post(path("/polls/TIME/gift/draw")),owner,null,200).andExpect(jsonPath("$.data.timePoll.winnerIds[0]").value(otherId));
        call(post(path("/polls/TIME/gift/draw")),owner,null,200).andExpect(jsonPath("$.data.timePoll.winnerIds[0]").value(otherId));
        String p=data(call(get(path("/votes")),owner,null,200)).path("placeOptions").get(0).path("candidateId").asText();
        call(put(path("/votes/place")),other,ballot(p),200);
        call(post(path("/confirm/time")),owner,"{\"candidateId\":\""+t+"\"}",200);
    }
    @Test void expirationIsEnforcedWithoutBackgroundJob() throws Exception {
        String t=time(1);call(put(path("/polls/TIME")),owner,settings(false),200);
        new TransactionTemplate(transactions).executeWithoutResult(tx->{
            var a=appointments.findByIdForUpdate(id).orElseThrow();
            org.springframework.test.util.ReflectionTestUtils.setField(a.mutablePoll(VoteType.TIME),"endsAt",Instant.now().minusSeconds(1));
        });
        call(get(path("/votes")),owner,null,200).andExpect(jsonPath("$.data.timePoll.state").value("CLOSED"));
        call(put(path("/votes/time")),other,ballot(t),409);
        call(delete(path("/time-candidates/"+t)),owner,null,409);
    }
    @Test void editingCandidateClearsOnlyAffectedVotesAndDeletingCannotLeaveOrphans() throws Exception {
        String a=time(1),b=time(2);place();
        call(put(path("/votes/time")),other,ballot(a,b),200);
        call(put(path("/time-candidates/"+a)),other,json.writeValueAsString(Map.of("time",OffsetDateTime.now().plusDays(5).toString())),403);
        call(put(path("/time-candidates/"+a)),owner,json.writeValueAsString(Map.of("time",OffsetDateTime.now().plusDays(5).toString())),200)
                .andExpect(jsonPath("$.data.timeOptions[0].voteCount").value(0)).andExpect(jsonPath("$.data.timeOptions[1].voteCount").value(1));
        call(delete(path("/time-candidates/"+b)),owner,null,200).andExpect(jsonPath("$.data.timeOptions.length()").value(1));
        call(put(path("/votes/time")),other,ballot(b),400);
        call(get(path("")),owner,null,200).andExpect(jsonPath("$.data.members.length()").value(1));
    }
    @Test void homeFiltersAndAppearancePersistAndDoNotExposeOtherRooms() throws Exception {
        call(put(path("/appearance")),other,"{\"cardText\":\"Hi\"}",403);
        call(put(path("/appearance")),owner,"{\"coverImageUrl\":\"https://example.com/card.png\",\"cardText\":\"See you\",\"cardStyle\":\"LETTER\"}",200);
        call(get("/api/v1/home?filter=UPCOMING&query=Hike"),other,null,200)
                .andExpect(jsonPath("$.data.items[0].cardText").value("See you")).andExpect(jsonPath("$.data.totalCount").value(1));
        call(get("/api/v1/home"),outsider,null,200).andExpect(jsonPath("$.data.items.length()").value(0));
        call(get("/api/v1/rooms/"+room+"/dashboard?filter=COMPLETED"),owner,null,200).andExpect(jsonPath("$.data.items.length()").value(0));
        call(get("/api/v1/home?filter=INVALID"),owner,null,400);
        call(get("/api/v1/home?size=1000"),owner,null,400);
        call(put(path("/appearance")),owner,"{\"coverImageUrl\":\"javascript:alert(1)\"}",400);
    }
    void confirmNow() throws Exception {
        String t=data(call(post(path("/time-candidates")),owner,json.writeValueAsString(Map.of("time",OffsetDateTime.now().plusMinutes(5).toString())),200))
                .path("timeOptions").get(0).path("candidateId").asText();place();
        String p=data(call(get(path("/votes")),owner,null,200)).path("placeOptions").get(0).path("candidateId").asText();
        call(put(path("/votes/time")),other,ballot(t),200);
        call(post(path("/confirm/time")),owner,"{\"candidateId\":\""+t+"\"}",200);
        call(post(path("/confirm/place")),owner,"{\"candidateId\":\""+p+"\"}",200);
    }
    @Test void attendancePokeCooldownInboxAndLocationOptOutWorkEndToEnd() throws Exception {
        confirmNow();
        call(put(path("/attendance/me")),other,"{\"state\":\"EN_ROUTE\",\"transport\":\"WALK\",\"etaMinutes\":5,\"statusMessage\":\"On my way\"}",200);
        call(put(path("/location")),other,"{\"latitude\":37.5,\"longitude\":127.0,\"sharingEnabled\":true}",200);
        call(get(path("/map?latitude=37.5&longitude=127.0")),owner,null,200).andExpect(jsonPath("$.data.participants.length()").value(1));
        var roster=data(call(get(path("/attendance")),owner,null,200));
        assertThat(roster.path("totalCount").asInt()).isEqualTo(2);
        String notification=data(call(post(path("/members/"+otherId+"/poke")),owner,null,200)).path("id").asText();
        call(post(path("/members/"+otherId+"/poke")),owner,null,429);
        call(get("/api/v1/notifications"),other,null,200).andExpect(jsonPath("$.data[0].id").value(notification));
        call(put("/api/v1/notifications/"+notification+"/read"),owner,null,404);
        call(put("/api/v1/notifications/"+notification+"/read"),other,null,200).andExpect(jsonPath("$.data.readAt").isNotEmpty());
        call(delete(path("/location")),other,null,200);
        call(get(path("/map?latitude=37.5&longitude=127.0")),owner,null,200).andExpect(jsonPath("$.data.participants.length()").value(0));
        call(put(path("/attendance/me")),other,"{\"state\":\"ARRIVED\"}",200).andExpect(jsonPath("$.data.arrivedCount").value(1));
        call(get(path("/attendance")),outsider,null,403);
        call(delete(path("/members/"+otherId)),owner,null,200);
        call(get(path("/attendance")),other,null,403);
    }
    @Test void invalidAttendanceAndLocationSharingWindowAreRejected() throws Exception {
        call(put(path("/attendance/me")),owner,"{\"state\":\"ARRIVED\",\"etaMinutes\":10}",400);
        call(put(path("/attendance/me")),owner,"{\"state\":\"ARRIVED\"}",403);
        call(get(path("/map?latitude=999&longitude=0")),owner,null,400);
    }
    @Test void savedPlacesArePrivateAndRecommendationsCarryMetadata() throws Exception {
        String body="{\"place\":{\"name\":\"Cafe\",\"latitude\":37.5,\"longitude\":127,\"address\":\"Seoul\",\"category\":\"Cafe\"},\"context\":\"FRIENDS\"}";
        String savedId=data(call(post("/api/v1/places/saved"),owner,body,200)).path("id").asText();
        call(get(path("/recommendations?context=FRIENDS&latitude=37.5&longitude=127")),owner,null,200)
                .andExpect(jsonPath("$.data[0].place.address").value("Seoul")).andExpect(jsonPath("$.data[0].distanceMeters").value(0));
        call(get("/api/v1/places/saved"),other,null,200).andExpect(jsonPath("$.data.length()").value(0));
        call(delete("/api/v1/places/saved/"+savedId),other,null,404);
        call(get(path("/recommendations")),outsider,null,403);
        call(get("/api/v1/places/search?query=Cafe"),owner,null,503);
        call(get("/api/v1/places/search?query=Cafe&latitude=NaN&longitude=127"),owner,null,400);
        call(delete("/api/v1/places/saved/"+savedId),owner,null,200);
    }
    @Test void validatorsRejectUnsupportedPollDurationGiftAndTypes() throws Exception {
        time(1);
        call(put(path("/polls/TIME")),owner,settings(false).replace("30","31"),400);
        call(put(path("/polls/TIME")),owner,settings(false).replace("}",",\"giftMethod\":\"RANDOM\"}"),400);
        call(put(path("/polls/BOGUS")),owner,settings(false),400);
        mvc.perform(get("/api/v1/notifications")).andExpect(status().isUnauthorized());
    }
    @Test void uploadedImagesRequireOwnershipOrAnAccessibleReference() throws Exception {
        var bytes=new java.io.ByteArrayOutputStream();
        javax.imageio.ImageIO.write(new java.awt.image.BufferedImage(2,2,java.awt.image.BufferedImage.TYPE_INT_RGB),"png",bytes);
        var file=new org.springframework.mock.web.MockMultipartFile("file","cover.png","image/png",bytes.toByteArray());
        var uploaded=data(mvc.perform(multipart("/api/v1/media").file(file).header("Authorization","Bearer "+owner)).andExpect(status().isCreated()));
        String imageId=uploaded.path("id").asText(),url=uploaded.path("url").asText();
        call(get("/api/v1/media/"+imageId),owner,null,200);
        call(get("/api/v1/media/"+imageId),other,null,404);
        String otherAppointment=data(call(post("/api/v1/rooms/"+room+"/appointments"),other,"{\"name\":\"Other meeting\"}",201)).path("id").asText();
        call(put("/api/v1/appointments/"+otherAppointment+"/appearance"),other,json.writeValueAsString(Map.of("coverImageUrl",url)),404);
        call(post(path("/place-candidates")),other,json.writeValueAsString(Map.of("name","Private image","imageUrl",url)),404);
        call(put(path("/appearance")),owner,json.writeValueAsString(Map.of("coverImageUrl",url)),200);
        call(get("/api/v1/media/"+imageId),other,null,200);
        call(get("/api/v1/media/"+imageId),outsider,null,404);
        var fake=new org.springframework.mock.web.MockMultipartFile("file","evil.png","image/png","not an image".getBytes());
        mvc.perform(multipart("/api/v1/media").file(fake).header("Authorization","Bearer "+owner)).andExpect(status().isBadRequest());
        call(patch("/api/v1/rooms/"+room),owner,json.writeValueAsString(Map.of("name","New group","coverImageUrl",url)),200)
                .andExpect(jsonPath("$.data.coverImageUrl").value(url));
        call(patch("/api/v1/auth/me"),owner,json.writeValueAsString(Map.of("name","Owner","avatarUrl",url)),200)
                .andExpect(jsonPath("$.data.avatarUrl").value(url));
    }
    @Test void duplicatePokesAreSerializedAcrossConcurrentRequests() throws Exception {
        confirmNow();
        var pool=java.util.concurrent.Executors.newFixedThreadPool(2);
        var gate=new java.util.concurrent.CountDownLatch(1);
        try {
            java.util.concurrent.Callable<Integer> task=()->{gate.await();return mvc.perform(post(path("/members/"+otherId+"/poke"))
                    .header("Authorization","Bearer "+owner)).andReturn().getResponse().getStatus();};
            var first=pool.submit(task);var second=pool.submit(task);gate.countDown();
            assertThat(java.util.List.of(first.get(15,java.util.concurrent.TimeUnit.SECONDS),second.get(15,java.util.concurrent.TimeUnit.SECONDS)))
                    .containsExactlyInAnyOrder(200,429);
        } finally {pool.shutdownNow();}
    }
    @Test void optOutRemainsAvailableAfterSharingWindowCloses() throws Exception {
        confirmNow();
        call(put(path("/location")),other,"{\"latitude\":37.5,\"longitude\":127,\"sharingEnabled\":true}",200);
        new TransactionTemplate(transactions).executeWithoutResult(tx->{
            var a=appointments.findByIdForUpdate(id).orElseThrow();
            org.springframework.test.util.ReflectionTestUtils.setField(a,"confirmedTime",OffsetDateTime.now().minusDays(1));
        });
        call(delete(path("/location")),other,null,200);
        var data=data(call(get(path("/attendance")),owner,null,200));
        for(var person:data.path("participants")) assertThat(person.path("latitude").isNull()).isTrue();
    }

    @Test void openApiIncludesScreenRoutes() throws Exception {
        mvc.perform(get("/v3/api-docs")).andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/v1/appointments/{id}/attendance']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/media']").exists());
    }

}
