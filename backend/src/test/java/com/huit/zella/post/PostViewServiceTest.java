package com.huit.zella.post;

import com.huit.zella.common.exception.BusinessException;
import org.junit.jupiter.api.*;
import java.time.*;
import java.util.Optional;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class PostViewServiceTest {
    final Instant now=Instant.parse("2026-10-16T00:00:00Z");
    PostRepository posts;
    PostViewStore store;
    PostViewService service;
    Post post;
    @BeforeEach void setup(){
        posts=mock(PostRepository.class); store=mock(PostViewStore.class);
        service=new PostViewService(posts,store,Clock.fixed(now,ZoneOffset.UTC));
        post=new Post();post.setId(1L);post.setSlug("bai-viet");post.setViewCount(7);
        post.setStatus(PostStatus.PUBLISHED);post.setPublishedAt(now.minusSeconds(100));post.setCategory(new PostCategory());
    }
    void session(Instant started){
        when(store.session("token")).thenReturn(Optional.of(new PostViewStore.Session("token",1L,"browser",started)));
        when(posts.lockForView(1L)).thenReturn(Optional.of(post));
    }
    @Test void openingIssuesSessionWithServerTimeWithoutIncrementing(){
        when(posts.findBySlug("bai-viet")).thenReturn(Optional.of(post));
        var result=service.start("bai-viet","browser");
        assertEquals(10,result.minimumSeconds());
        verify(store).start(argThat(s->s.startedAt().equals(now)&&s.postId()==1L&&s.browserId().equals("browser")&&s.token().equals(result.token())));
        verify(posts,never()).incrementViews(anyLong());
    }
    @Test void beforeTenSecondsDoesNotConsumeOrCount(){
        session(now.minusSeconds(10).plusNanos(1));
        var error=assertThrows(BusinessException.class,()->service.count("bai-viet","browser","token"));
        assertEquals("POST_VIEW_TOO_EARLY",error.getCode());
        verify(store,never()).consume(anyString(),any());verify(posts,never()).incrementViews(anyLong());
    }
    @Test void atTenSecondsCountsOneAndLocksBeforeUpdating(){
        session(now.minusSeconds(10));when(store.consume("token",now)).thenReturn(true);
        when(store.lastCount(1L,"browser")).thenReturn(Optional.empty());
        var result=service.count("bai-viet","browser","token");assertTrue(result.counted());assertEquals(8,result.viewCount());
        var order=inOrder(posts,store);
        order.verify(store).session("token");order.verify(posts).lockForView(1L);
        order.verify(store).consume("token",now);order.verify(store).lastCount(1L,"browser");
        order.verify(store).counted(1L,"browser",now);order.verify(posts).incrementViews(1L);
    }
    @Test void withinFiveMinutesDoesNotCountAndDoesNotExtendWindow(){
        session(now.minusSeconds(10));when(store.consume("token",now)).thenReturn(true);
        when(store.lastCount(1L,"browser")).thenReturn(Optional.of(now.minusSeconds(299)));
        assertFalse(service.count("bai-viet","browser","token").counted());
        verify(store,never()).counted(anyLong(),anyString(),any());verify(posts,never()).incrementViews(anyLong());
    }
    @Test void atExactlyFiveMinutesCanCountAgain(){
        session(now.minusSeconds(10));when(store.consume("token",now)).thenReturn(true);
        when(store.lastCount(1L,"browser")).thenReturn(Optional.of(now.minusSeconds(300)));
        assertTrue(service.count("bai-viet","browser","token").counted());verify(posts).incrementViews(1L);
    }
    @Test void consumedSessionNeverCountsAgainEvenAfterFiveMinutes(){
        session(now.minusSeconds(600));when(store.consume("token",now)).thenReturn(false);
        assertFalse(service.count("bai-viet","browser","token").counted());
        verify(store,never()).lastCount(anyLong(),anyString());verify(posts,never()).incrementViews(anyLong());
    }
    @Test void tokenCannotBeUsedByAnotherBrowser(){
        when(store.session("token")).thenReturn(Optional.of(new PostViewStore.Session("token",1L,"other",now.minusSeconds(10))));
        assertThrows(BusinessException.class,()->service.count("bai-viet","browser","token"));verifyNoInteractions(posts);
    }
    @Test void archivedOrWrongArticleCannotCount(){
        session(now.minusSeconds(10));post.setStatus(PostStatus.ARCHIVED);
        assertThrows(BusinessException.class,()->service.count("bai-viet","browser","token"));
        post.setStatus(PostStatus.PUBLISHED);
        assertThrows(BusinessException.class,()->service.count("different","browser","token"));
        verify(store,never()).consume(anyString(),any());
    }
    @Test void expiredSessionCannotCount(){
        session(now.minusSeconds(3601));assertThrows(BusinessException.class,()->service.count("bai-viet","browser","token"));
        verify(store,never()).consume(anyString(),any());
    }
}
