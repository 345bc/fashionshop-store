package com.huit.zella.post;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import java.time.*;
import java.util.List;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class PopularPostTest {
    @Test void queryUsesLifetimeViewsWithoutRequiringRecentEvents() throws Exception {
        var jdbc = mock(JdbcTemplate.class);
        var now = Instant.parse("2026-10-16T09:30:00Z");
        var service = new PopularPostService(jdbc, Clock.fixed(now, ZoneOffset.UTC));
        when(jdbc.query(anyString(),any(RowMapper.class),any(Object[].class))).thenAnswer(invocation -> {
            assertEquals(Integer.valueOf(1), invocation.getArgument(2, Integer.class));
            assertEquals(now.atOffset(ZoneOffset.UTC), invocation.getArgument(3));
            String sql=invocation.getArgument(0);
            assertTrue(sql.contains("ORDER BY p.view_count DESC"));
            assertFalse(sql.contains("post_view_events"));
            var rs = mock(java.sql.ResultSet.class);
            when(rs.getLong("id")).thenReturn(3L);
            when(rs.getInt("view_count")).thenReturn(900);
            when(rs.getObject("published_at",OffsetDateTime.class)).thenReturn(now.minus(Duration.ofDays(30)).atOffset(ZoneOffset.UTC));
            RowMapper<PopularPostService.PopularPost> mapper=invocation.getArgument(1);
            return List.of(mapper.mapRow(rs,0));
        });
        var result=service.mostViewed();
        assertEquals(900,result.getFirst().viewCount());
        assertTrue(result.getFirst().publishedAt().isBefore(now.minus(Duration.ofDays(7))));
    }

    @Test void popularEndpointReturnsEmptyArrayWithoutInventingRankings() throws Exception {
        var service=mock(PopularPostService.class);
        when(service.mostViewed()).thenReturn(List.of());
        MockMvcBuilders.standaloneSetup(new PopularPostController(service)).build()
                .perform(get("/api/v1/posts/popular"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data").isArray()).andExpect(jsonPath("$.data").isEmpty());
        verify(service).mostViewed();
    }

    @Test void sidebarCanRequestMultiplePopularPostsWithBoundedSize() throws Exception {
        var service=mock(PopularPostService.class);
        when(service.mostViewed(4)).thenReturn(List.of());
        when(service.mostViewed(5)).thenReturn(List.of());
        var mvc=MockMvcBuilders.standaloneSetup(new PopularPostController(service)).build();
        mvc.perform(get("/api/v1/posts/popular").param("size","4")).andExpect(status().isOk());
        mvc.perform(get("/api/v1/posts/popular").param("size","1000")).andExpect(status().isOk());
        verify(service).mostViewed(4);verify(service).mostViewed(5);
    }

    @Test void acceptedViewWritesAnEventAndCleanupKeepsMoreThanSevenDays() {
        var jdbc=mock(JdbcTemplate.class);
        var store=new PostViewStore(jdbc);
        var now=Instant.parse("2026-10-16T09:30:00Z");
        store.counted(3L,"browser",now);
        verify(jdbc).update("INSERT INTO post_view_events(post_id,counted_at) VALUES (?,?)",3L,now.atOffset(ZoneOffset.UTC));
        store.cleanup(now.minusSeconds(3600),now.minus(Duration.ofDays(1)));
        verify(jdbc).update("DELETE FROM post_view_events WHERE counted_at<?",now.minus(Duration.ofDays(8)).atOffset(ZoneOffset.UTC));
    }
}
