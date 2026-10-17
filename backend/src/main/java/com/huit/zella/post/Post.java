package com.huit.zella.post;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Nationalized;
import java.time.Instant;
@org.hibernate.annotations.DynamicUpdate
@Entity @Table(name="post") @Getter @Setter
public class Post {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="category_id",nullable=false) private PostCategory category;
 @Column(name="author_id",nullable=false) private Long authorId;
 @Nationalized @Column(nullable=false,length=255) private String title;
 @Column(nullable=false,length=270) private String slug;
 @Nationalized @Column(length=500) private String summary;
 @Column(nullable=false,length=500) private String thumbnail;
 @Nationalized @Column(nullable=false,columnDefinition="nvarchar(max)") private String content;
 @Enumerated(EnumType.STRING) @Column(nullable=false,length=20) private PostStatus status=PostStatus.DRAFT;
 @Column(name="view_count",nullable=false) private int viewCount;
 @Column(name="published_at") private Instant publishedAt;
 @Column(name="created_at") private Instant createdAt=Instant.now();
 @Column(name="updated_at") private Instant updatedAt=Instant.now();
}
