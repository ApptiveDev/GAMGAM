package com.gamgam.backend.place;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest.PlaceRequest;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.vo.Place;
import com.gamgam.backend.global.exception.*;
import com.gamgam.backend.room.RoomAccess;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service @RequiredArgsConstructor @Transactional(readOnly=true)
public class PlaceService {
    private final SavedPlaceRepository saved;
    private final AppointmentRepository appointments;
    private final RoomAccess access;
    private final com.gamgam.backend.media.MediaService media;
    public enum Context { ALL, SENIOR, COLLEAGUES, FRIENDS, RECENT }
    public record SaveRequest(@NotNull @Valid PlaceRequest place,@NotNull Context context) {}
    public record Saved(String id,Place place,Context context,java.time.Instant createdAt) {
        static Saved of(SavedPlace s) {return new Saved(s.getId(),s.getPlace(),s.getContext(),s.getCreatedAt());}
    }
    public record Recommendation(Place place,Long distanceMeters,Integer estimatedWalkMinutes,String source) {}
    @Transactional
    public Saved save(String user,SaveRequest r) {media.validateReference(user,r.place().imageUrl());return Saved.of(saved.save(new SavedPlace(user,r.place().toDomain(),r.context())));}
    public List<Saved> saved(String user) {return saved.findByUserIdOrderByCreatedAtDesc(user).stream().map(Saved::of).toList();}
    @Transactional
    public void delete(String user,String id) {
        var p=saved.findById(id).filter(s->s.getUserId().equals(user)).orElseThrow(()->new BusinessException(ErrorCode.NOT_FOUND));saved.delete(p);
    }
    public List<Recommendation> recommend(String user,String appointmentId,Context context,String query,Double lat,Double lon,int limit,boolean refresh) {
        LinkedHashMap<String,Place> candidates=new LinkedHashMap<>();
        for(var s:saved.findByUserIdOrderByCreatedAtDesc(user)) {
            if(context==Context.ALL || context==Context.RECENT || s.getContext()==context) add(candidates,s.getPlace());
        }
        if(appointmentId!=null) {
            var a=appointments.findById(appointmentId).orElseThrow(()->new BusinessException(ErrorCode.APPOINTMENT_NOT_FOUND));
            access.requireMember(a.getRoomId(),user);
            if(context==Context.ALL || context==Context.RECENT) for(var past:appointments.findByRoomIdOrderByCreatedAtDesc(a.getRoomId())) {
                if(past.getConfirmedPlace()!=null) add(candidates,past.getConfirmedPlace());
                past.getCandidatesPlace().forEach(c->add(candidates,c.getPlace()));
            }
        }
        var result=new ArrayList<>(candidates.values().stream().filter(p->p.name().toLowerCase(Locale.ROOT).contains(query.strip().toLowerCase(Locale.ROOT)))
                .map(p->{Long distance=lat==null || p.latitude()==null?null:distance(lat,lon,p.latitude(),p.longitude());
                    return new Recommendation(p,distance,distance==null?null:(int)Math.ceil(distance/80.0),"SAVED_OR_ROOM_HISTORY");}).toList());
        if(refresh) Collections.shuffle(result);
        else if(lat!=null && context!=Context.RECENT) result.sort(Comparator.comparing(Recommendation::distanceMeters,Comparator.nullsLast(Comparator.naturalOrder())));
        return result.stream().limit(limit).toList();
    }
    private void add(Map<String,Place> map,Place p) {map.putIfAbsent(p.name().strip().toLowerCase(Locale.ROOT)+"|"+p.latitude()+"|"+p.longitude(),p);}
    private long distance(double a,double b,double c,double d) {
        double x=Math.sin(Math.toRadians(c-a)/2),y=Math.sin(Math.toRadians(d-b)/2);
        double h=x*x+Math.cos(Math.toRadians(a))*Math.cos(Math.toRadians(c))*y*y;
        return Math.round(6371000*2*Math.asin(Math.sqrt(Math.min(1,h))));
    }
}
