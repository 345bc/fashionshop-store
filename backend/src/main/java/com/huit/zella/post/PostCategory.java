package com.huit.zella.post;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Nationalized;
import java.time.Instant;
@Entity @Table(name="post_categories") @Getter @Setter
public class PostCategory {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 @Nationalized @Column(nullable=false,length=100) private String name;
 @Column(nullable=false,length=120) private String slug;
 @Column(length=500) private String thumbnail;
 @Column(name="is_active",nullable=false) private boolean active=true;
 @Column(name="created_at") private Instant createdAt=Instant.now();
}
