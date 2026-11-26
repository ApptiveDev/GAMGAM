package com.gamgam.backend.media;
import com.gamgam.backend.appointment.repository.*;
import com.gamgam.backend.room.*;
import com.gamgam.backend.global.exception.*;
import java.io.*;
import javax.imageio.ImageIO;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service @Transactional(readOnly=true)
public class MediaService {
    private final MediaAssetRepository assets;
    private final AppointmentRepository appointments;
    private final AppointmentMemberRepository members;
    private final RoomRepository rooms;
    private final RoomMemberRepository roomMembers;
    private final String baseUrl;
    public MediaService(MediaAssetRepository assets,AppointmentRepository appointments,AppointmentMemberRepository members,
            RoomRepository rooms,RoomMemberRepository roomMembers,@Value("${app.media.base-url:http://localhost:8080}") String baseUrl) {
        this.assets=assets;this.appointments=appointments;this.members=members;this.rooms=rooms;this.roomMembers=roomMembers;this.baseUrl=baseUrl.replaceAll("/+$","");
    }
    public record Uploaded(String id,String url,String contentType,long size) {}
    @Transactional
    public Uploaded upload(String user,MultipartFile file) {
        if(file.isEmpty() || file.getSize()>5242880) throw new BusinessException(ErrorCode.BAD_REQUEST);
        try(var stream=ImageIO.createImageInputStream(file.getInputStream())) {
            var readers=ImageIO.getImageReaders(stream);
            if(!readers.hasNext()) throw new BusinessException(ErrorCode.BAD_REQUEST);
            var reader=readers.next();
            try {
                reader.setInput(stream);String format=reader.getFormatName().toLowerCase(java.util.Locale.ROOT);
                if(!java.util.Set.of("png","jpeg","jpg").contains(format) || reader.getWidth(0)>8192 || reader.getHeight(0)>8192
                        || (long)reader.getWidth(0)*reader.getHeight(0)>16000000) throw new BusinessException(ErrorCode.BAD_REQUEST);
                // Decode and re-encode to validate the image and strip uploaded metadata/trailing payloads.
                var buffer=new ByteArrayOutputStream();
                if(!ImageIO.write(reader.read(0),format,buffer) || buffer.size()>5242880) throw new BusinessException(ErrorCode.BAD_REQUEST);
                String id=java.util.UUID.randomUUID().toString(),url=baseUrl+"/api/v1/media/"+id;
                String type=format.equals("png")?"image/png":"image/jpeg";
                assets.save(new MediaAsset(id,user,url,type,buffer.toByteArray()));
                return new Uploaded(id,url,type,buffer.size());
            } finally {reader.dispose();}
        } catch(IOException | IllegalArgumentException e) {throw new BusinessException(ErrorCode.BAD_REQUEST);}
    }
    public void validateReference(String user,String url) {
        String prefix=baseUrl+"/api/v1/media/";
        if(url!=null && url.startsWith(prefix)) get(user,url.substring(prefix.length()));
    }
    public MediaAsset get(String user,String id) {
        var asset=assets.findById(id).orElseThrow(()->new BusinessException(ErrorCode.NOT_FOUND));
        if(asset.getOwnerId().equals(user)) return asset;
        for(var a:appointments.findAllForUser(user)) {
            if(asset.getUrl().equals(a.getCoverImageUrl()) || a.getCandidatesPlace().stream().anyMatch(c->asset.getUrl().equals(c.getPlace().imageUrl()))
                    || a.getConfirmedPlace()!=null && asset.getUrl().equals(a.getConfirmedPlace().imageUrl())) return asset;
            if(members.findAllByAppointmentIdOrderByJoinedAtAsc(a.getId()).stream().anyMatch(m->asset.getUrl().equals(m.getUser().getAvatarUrl()))) return asset;
        }
        for(var room:rooms.findAllForUser(user)) {
            if(asset.getUrl().equals(room.getCoverImageUrl()) || roomMembers.findByRoomIdOrderByIdAsc(room.getId()).stream()
                    .anyMatch(m->asset.getUrl().equals(m.getUser().getAvatarUrl()))) return asset;
        }
        throw new BusinessException(ErrorCode.NOT_FOUND);
    }
}
