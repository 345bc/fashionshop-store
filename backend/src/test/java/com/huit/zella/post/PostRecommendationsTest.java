package com.huit.zella.post;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;
class PostRecommendationsTest {
    @Test void returnsSecondAndThirdNewestThenTwoMostViewed(){
        PostRepository posts=mock(PostRepository.class);
        PostService service=new PostService(posts,mock(PostCategoryRepository.class));
        List<Post> latest=List.of(post(1),post(2),post(3));
        when(posts.findAll(any(Specification.class),any(Pageable.class))).thenReturn(new PageImpl<>(latest),new PageImpl<>(List.of(post(8),post(5))));
        assertEquals(List.of(2L,3L,8L,5L),service.recommendations().stream().map(PostResponse::id).toList());
        verify(posts).findAll(any(Specification.class),argThat((Pageable p)->p.getPageSize()==3&&p.getSort().getOrderFor("publishedAt").isDescending()));
        verify(posts).findAll(any(Specification.class),argThat((Pageable p)->p.getPageSize()==2&&p.getSort().getOrderFor("viewCount").isDescending()));
    }
    @Test void noPublishedPostsReturnsNoSuggestions(){
        var posts=mock(PostRepository.class);when(posts.findAll(any(Specification.class),any(Pageable.class))).thenReturn(Page.empty());
        assertTrue(new PostService(posts,mock(PostCategoryRepository.class)).recommendations().isEmpty());
    }
    @Test void bothNewestAndPopularQueriesAreRestrictedToSelectedCategory(){
        var posts=mock(PostRepository.class);
        when(posts.findAll(any(Specification.class),any(Pageable.class))).thenReturn(Page.empty());
        new PostService(posts,mock(PostCategoryRepository.class)).recommendations(7L);
        var specs=org.mockito.ArgumentCaptor.forClass(Specification.class);
        verify(posts,times(2)).findAll(specs.capture(),any(Pageable.class));
        jakarta.persistence.criteria.Root<Post> root=mock(jakarta.persistence.criteria.Root.class,RETURNS_DEEP_STUBS);
        var cb=mock(jakarta.persistence.criteria.CriteriaBuilder.class,RETURNS_DEEP_STUBS);
        for(var spec:specs.getAllValues()) spec.toPredicate(root,null,cb);
        verify(cb,times(2)).equal(root.get("category").get("id"),7L);
    }
    Post post(long id){Post p=new Post();p.setId(id);PostCategory c=new PostCategory();c.setId(1L);p.setCategory(c);return p;}
}
