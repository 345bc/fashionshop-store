package com.huit.zella.post;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.List;

@Service
public class PopularPostService {
    private final JdbcTemplate jdbc;
    private final Clock clock;
    @org.springframework.beans.factory.annotation.Autowired
    public PopularPostService(JdbcTemplate jdbc) { this(jdbc, Clock.systemUTC()); }
    PopularPostService(JdbcTemplate jdbc, Clock clock) { this.jdbc = jdbc; this.clock = clock; }

    public record PopularPost(Long id, String title, String slug, String summary, String thumbnail,
                              Long categoryId, String categoryName, Instant publishedAt,
                              int viewCount) {}

    @Transactional(readOnly = true)
    public List<PopularPost> mostViewed() { return mostViewed(1); }

    @Transactional(readOnly = true)
    public List<PopularPost> mostViewed(int size) {
        Instant now = clock.instant();
        return jdbc.query("""
                SELECT TOP (?) p.id,p.title,p.slug,p.summary,p.thumbnail,p.category_id,c.name AS category_name,
                       p.published_at,p.view_count
                FROM post p
                JOIN post_categories c ON c.id=p.category_id
                WHERE p.status='PUBLISHED' AND p.published_at<=? AND c.is_active=1 AND p.view_count>0
                ORDER BY p.view_count DESC,p.published_at DESC,p.id DESC
                """, (rs, row) -> new PopularPost(rs.getLong("id"),rs.getString("title"),rs.getString("slug"),
                rs.getString("summary"),rs.getString("thumbnail"),rs.getLong("category_id"),rs.getString("category_name"),
                rs.getObject("published_at",OffsetDateTime.class).toInstant(),rs.getInt("view_count")),
                Math.clamp(size,1,5),now.atOffset(ZoneOffset.UTC));
    }
}
