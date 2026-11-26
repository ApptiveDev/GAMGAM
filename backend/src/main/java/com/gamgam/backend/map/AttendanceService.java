package com.gamgam.backend.map;

import com.gamgam.backend.appointment.entity.Appointment;
import com.gamgam.backend.appointment.repository.*;
import com.gamgam.backend.appointment.vo.*;
import com.gamgam.backend.global.exception.*;
import jakarta.validation.constraints.*;
import java.time.*;
import java.util.*;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service @RequiredArgsConstructor @Transactional(readOnly=true)
public class AttendanceService {
    private final AppointmentRepository appointments;
    private final AppointmentMemberRepository members;
    private final AttendanceRepository attendance;
    private final LiveLocationRepository locations;
    private final PokeNotificationRepository pokes;
    public record StatusRequest(@NotNull Attendance.State state, Attendance.Transport transport,
            @Min(0) @Max(1440) Integer etaMinutes, @Size(max=200) String statusMessage) {
        @AssertTrue(message="ETA and transport are only valid while en route")
        public boolean isConsistent() { return state == Attendance.State.EN_ROUTE || etaMinutes == null && transport == null; }
    }
    public record Person(String id,String name,String avatarUrl,Attendance.State state,String statusMessage,
            Attendance.Transport transport,Integer etaMinutes,Instant arrivedAt,boolean sharingEnabled,
            Double latitude,Double longitude,Instant locationUpdatedAt,Instant nextPokeAt) {}
    public record Summary(String appointmentId,Instant serverTime,java.time.OffsetDateTime confirmedTime,
            Long secondsUntilAppointment,int totalCount,long arrivedCount,long notDepartedCount,List<Person> participants) {}
    public record Notification(String id,String appointmentId,String senderId,String recipientId,Instant createdAt,Instant readAt) {
        static Notification of(PokeNotification p) { return new Notification(p.getId(),p.getAppointmentId(),p.getSenderId(),p.getRecipientId(),p.getCreatedAt(),p.getReadAt()); }
    }

    public Summary get(String id,String user) {
        Appointment a=load(id,user,false);
        var now=Instant.now();
        var statuses=attendance.findByAppointmentId(id).stream().collect(Collectors.toMap(Attendance::getUserId,s->s));
        var coords=locations.findByRoomIdAndSharingEnabledTrue(id).stream().filter(l->l.updatedAt().isAfter(now.minusSeconds(60)))
                .collect(Collectors.toMap(LiveLocation::userId,l->l));
        boolean inWindow=inWindow(a,now);
        var people=members.findAllByAppointmentIdOrderByJoinedAtAsc(id).stream().map(m->{
            String uid=m.getUser().getId(); var s=statuses.get(uid); var l=inWindow?coords.get(uid):null;
            Instant next=pokes.findFirstByAppointmentIdAndSenderIdAndRecipientIdOrderByCreatedAtDesc(id,user,uid)
                    .map(p->p.getCreatedAt().plusSeconds(300)).filter(t->t.isAfter(now)).orElse(null);
            boolean fresh=s!=null && s.getUpdatedAt()!=null && s.getUpdatedAt().isAfter(now.minusSeconds(300));
            return new Person(uid,m.getUser().getName(),m.getUser().getAvatarUrl(),s==null?Attendance.State.NOT_DEPARTED:s.getState(),
                    s==null?null:s.getStatusMessage(),s==null?null:s.getTransport(),fresh?s.getEtaMinutes():null,
                    s==null?null:s.getArrivedAt(),l!=null,l==null?null:l.latitude(),l==null?null:l.longitude(),l==null?null:l.updatedAt(),next);
        }).sorted(Comparator.comparing(Person::arrivedAt,Comparator.nullsLast(Comparator.naturalOrder())).thenComparing(Person::id)).toList();
        return new Summary(id,now,com.gamgam.backend.global.util.KstTimeConverter.toKst(a.getConfirmedTime()),
                a.getConfirmedTime()==null?null:Duration.between(now,a.getConfirmedTime().toInstant()).getSeconds(),people.size(),
                people.stream().filter(p->p.state()==Attendance.State.ARRIVED).count(),
                people.stream().filter(p->p.state()==Attendance.State.NOT_DEPARTED).count(),people);
    }
    @Transactional
    public Summary update(String id,String user,StatusRequest request) {
        Appointment a=load(id,user,true);
        if(!inWindow(a,Instant.now())) throw new BusinessException(ErrorCode.APPOINTMENT_ACCESS_DENIED);
        var s=attendance.findByAppointmentIdAndUserId(id,user).orElseGet(()->new Attendance(id,user));
        s.update(request); attendance.save(s); return get(id,user);
    }
    @Transactional
    public void disableSharing(String id,String user) {
        load(id,user,true);
        locations.findByRoomIdAndUserId(id,user).ifPresent(l->l.update(l.latitude(),l.longitude(),false));
    }
    @Transactional
    public Notification poke(String id,String sender,String recipient) {
        Appointment a=load(id,sender,true);
        if(!inWindow(a,Instant.now()) || sender.equals(recipient)) throw new BusinessException(ErrorCode.BAD_REQUEST);
        if(!members.existsByAppointmentIdAndUserId(id,recipient)) throw new BusinessException(ErrorCode.MEMBER_NOT_FOUND);
        var last=pokes.findFirstByAppointmentIdAndSenderIdAndRecipientIdOrderByCreatedAtDesc(id,sender,recipient);
        if(last.isPresent() && Instant.now().isBefore(last.get().getCreatedAt().plusSeconds(300))) throw new BusinessException(ErrorCode.POKE_COOLDOWN);
        return Notification.of(pokes.save(new PokeNotification(id,sender,recipient)));
    }
    public List<Notification> inbox(String user) { return pokes.findTop100ByRecipientIdOrderByCreatedAtDesc(user).stream().map(Notification::of).toList(); }
    @Transactional
    public Notification read(String user,String id) {
        var p=pokes.findById(id).filter(n->n.getRecipientId().equals(user)).orElseThrow(()->new BusinessException(ErrorCode.NOT_FOUND));
        p.markRead(); return Notification.of(p);
    }
    private Appointment load(String id,String user,boolean lock) {
        var a=(lock?appointments.findByIdForUpdate(id):appointments.findById(id)).orElseThrow(()->new BusinessException(ErrorCode.APPOINTMENT_NOT_FOUND));
        if(!members.existsByAppointmentIdAndUserId(id,user)) throw new BusinessException(ErrorCode.APPOINTMENT_ACCESS_DENIED);
        return a;
    }
    static boolean inWindow(Appointment a,Instant now) {
        if(a.getStatus()!=AppointmentStatus.CONFIRMED || a.getConfirmedTime()==null) return false;
        var p=a.getLocationSharing()==null?LocationSharingPolicy.defaults():a.getLocationSharing();
        var time=a.getConfirmedTime().toInstant();
        return !now.isBefore(time.minusSeconds(p.startMinutesBefore()*60L)) && !now.isAfter(time.plusSeconds(p.maxMinutesAfter()*60L));
    }
}
