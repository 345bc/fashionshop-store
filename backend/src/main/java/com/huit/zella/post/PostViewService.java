package com.huit.zella.post;

import com.huit.zella.common.exception.BusinessException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.scheduling.annotation.Scheduled;
import java.time.*;
import java.util.UUID;

@Service
public class PostViewService {
    private final PostRepository posts;
    private final PostViewStore store;
    private final Clock clock;
    @org.springframework.beans.factory.annotation.Autowired
    public PostViewService(PostRepository posts,PostViewStore store) { this(posts,store,Clock.systemUTC()); }
    PostViewService(PostRepository posts,PostViewStore store,Clock clock) { this.posts=posts;this.store=store;this.clock=clock; }
    public record Started(String token, int minimumSeconds) {}
    public record Counted(boolean counted,int viewCount) {}

    @Transactional public Started start(String slug,String browserId) {
        Post p=posts.findBySlug(slug).orElseThrow(this::missing);
        Instant now=clock.instant();
        if(!PostService.visible(p,now)) throw missing();
        String token=UUID.randomUUID().toString();
        store.start(new PostViewStore.Session(token,p.getId(),browserId,now));
        return new Started(token,10);
    }
    @Transactional public Counted count(String slug,String browserId,String token) {
        PostViewStore.Session session=store.session(token).orElseThrow(()->
                new BusinessException(HttpStatus.GONE,"POST_VIEW_SESSION_EXPIRED","Phiên đọc đã hết hạn"));
        if(!session.browserId().equals(browserId)) throw new BusinessException(HttpStatus.FORBIDDEN,"POST_VIEW_BROWSER_MISMATCH","Phiên đọc không hợp lệ");
        Post p=posts.lockForView(session.postId()).orElseThrow(this::missing);
        Instant now=clock.instant();
        if(!p.getSlug().equals(slug) || !PostService.visible(p,now)) throw missing();
        if(session.startedAt().plus(Duration.ofHours(1)).isBefore(now)) throw new BusinessException(HttpStatus.GONE,"POST_VIEW_SESSION_EXPIRED","Phiên đọc đã hết hạn");
        if(now.isBefore(session.startedAt().plusSeconds(10))) throw new BusinessException(HttpStatus.CONFLICT,"POST_VIEW_TOO_EARLY","Chưa đủ thời gian đọc");
        if(!store.consume(token,now)) return new Counted(false,p.getViewCount());
        boolean count=store.lastCount(p.getId(),browserId).map(last->!now.isBefore(last.plusSeconds(300))).orElse(true);
        int views=p.getViewCount();
        if(count) {
            store.counted(p.getId(),browserId,now);
            posts.incrementViews(p.getId());
            views++;
        }
        // A consumed session can never increment again, including retries after the five-minute window.
        return new Counted(count,views);
    }
    @Scheduled(fixedDelay=3600000) @Transactional
    public void cleanup() { Instant now=clock.instant();store.cleanup(now.minus(Duration.ofHours(1)),now.minus(Duration.ofDays(1))); }
    private BusinessException missing(){return new BusinessException(HttpStatus.NOT_FOUND,"POST_NOT_FOUND","Không tìm thấy bài viết");}
}
