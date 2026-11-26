package com.gamgam.backend.place;
import com.gamgam.backend.appointment.vo.Place;
import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;
@Entity @Getter @NoArgsConstructor(access=AccessLevel.PROTECTED)
@Table(name="saved_places",indexes=@Index(columnList="userId,createdAt"))
public class SavedPlace {
    @Id private String id;
    @Column(nullable=false) private String userId;
    @Embedded private Place place;
    @Enumerated(EnumType.STRING) private PlaceService.Context context;
    private Instant createdAt;
    public SavedPlace(String userId,Place place,PlaceService.Context context) {
        id=java.util.UUID.randomUUID().toString();this.userId=userId;this.place=place;this.context=context;createdAt=Instant.now();
    }
}
