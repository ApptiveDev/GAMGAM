package com.gamgam.backend.media;
import jakarta.persistence.*;
import lombok.*;
@Entity @Getter @NoArgsConstructor(access=AccessLevel.PROTECTED)
@Table(name="media_assets")
public class MediaAsset {
    @Id private String id;
    @Column(nullable=false) private String ownerId;
    @Column(nullable=false,length=2048) private String url;
    @Column(nullable=false) private String contentType;
    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.VARBINARY)
    @Column(nullable=false,columnDefinition="bytea") private byte[] content;
    public MediaAsset(String id,String ownerId,String url,String contentType,byte[] content) {
        this.id=id;this.ownerId=ownerId;this.url=url;this.contentType=contentType;this.content=content;
    }
}
