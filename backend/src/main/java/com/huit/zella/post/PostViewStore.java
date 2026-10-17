package com.huit.zella.post;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.time.*;
import java.util.Optional;

@Repository @RequiredArgsConstructor
public class PostViewStore {
    private final JdbcTemplate jdbc;
    public record Session(String token, Long postId, String browserId, Instant startedAt) {}
    private OffsetDateTime date(Instant time) { return time.atOffset(ZoneOffset.UTC); }
    public void start(Session s) {
        jdbc.update("INSERT INTO post_view_sessions(token,post_id,browser_id,started_at) VALUES (?,?,?,?)",
                s.token(),s.postId(),s.browserId(),date(s.startedAt()));
    }
    public Optional<Session> session(String token) {
        return jdbc.query("SELECT token,post_id,browser_id,started_at FROM post_view_sessions WHERE token=?",
                (rs,n) -> new Session(rs.getString("token"),rs.getLong("post_id"),rs.getString("browser_id"),
                        rs.getObject("started_at",OffsetDateTime.class).toInstant()), token).stream().findFirst();
    }
    public Optional<Instant> lastCount(Long postId,String browserId) {
        return jdbc.query("SELECT counted_at FROM post_view_readers WHERE post_id=? AND browser_id=?",
                (rs,n) -> rs.getObject(1,OffsetDateTime.class).toInstant(),postId,browserId).stream().findFirst();
    }
    // Call only while holding the post row lock, so two tabs cannot insert or count together.
    public void counted(Long postId,String browserId,Instant now) {
        if (jdbc.update("UPDATE post_view_readers SET counted_at=? WHERE post_id=? AND browser_id=?",date(now),postId,browserId)==0) {
            jdbc.update("INSERT INTO post_view_readers(post_id,browser_id,counted_at) VALUES (?,?,?)",postId,browserId,date(now));
        }
        jdbc.update("INSERT INTO post_view_events(post_id,counted_at) VALUES (?,?)",postId,date(now));
    }
    public boolean consume(String token,Instant now) {
        return jdbc.update("UPDATE post_view_sessions SET completed_at=? WHERE token=? AND completed_at IS NULL",date(now),token)==1;
    }
    public void cleanup(Instant expiredSessions,Instant expiredReaders) {
        jdbc.update("DELETE FROM post_view_sessions WHERE started_at<?",date(expiredSessions));
        // Longer than the five-minute window; do not remove rows that could still suppress a duplicate.
        jdbc.update("DELETE FROM post_view_readers WHERE counted_at<?",date(expiredReaders));
        jdbc.update("DELETE FROM post_view_events WHERE counted_at<?",date(expiredReaders.minus(Duration.ofDays(7))));
    }
}
