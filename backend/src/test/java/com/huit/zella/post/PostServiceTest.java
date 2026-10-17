package com.huit.zella.post;
import com.huit.zella.common.exception.BusinessException;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import java.time.Instant;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
@ExtendWith(MockitoExtension.class)
class PostServiceTest {
 @Mock PostRepository posts;
 @Mock PostCategoryRepository categories;
 @InjectMocks PostService service;
 private Post post;
 private PostCategory category;
 @BeforeEach void setup() {
  category=new PostCategory();category.setId(2L);category.setName("Phong cách");
  post=new Post();post.setId(1L);post.setCategory(category);post.setAuthorId(3L);post.setSlug("phong-cach");post.setStatus(PostStatus.PUBLISHED);post.setPublishedAt(Instant.now().minusSeconds(10));
 }
 @Test void visibilityRequiresPublishedDueDateAndActiveCategory() {
  Instant now=Instant.now(); assertTrue(PostService.visible(post,now));
  post.setPublishedAt(now.plusSeconds(10));assertFalse(PostService.visible(post,now));
  post.setPublishedAt(now);assertTrue(PostService.visible(post,now));
  category.setActive(false);assertFalse(PostService.visible(post,now));category.setActive(true);
  post.setStatus(PostStatus.DRAFT);assertFalse(PostService.visible(post,now));
  post.setStatus(PostStatus.ARCHIVED);assertFalse(PostService.visible(post,now));
 }
 @Test void scheduledPostCannotBeReadOrCounted() {
  post.setPublishedAt(Instant.now().plusSeconds(3600));when(posts.findBySlug(post.getSlug())).thenReturn(Optional.of(post));
  assertThrows(BusinessException.class,()->service.read(post.getSlug()));verify(posts,never()).incrementViews(anyLong());
 }
 @Test void publicReadDoesNotCountAView() {
  post.setViewCount(10);when(posts.findBySlug(post.getSlug())).thenReturn(Optional.of(post));
  assertEquals(10,service.read(post.getSlug()).viewCount());verify(posts,never()).incrementViews(anyLong());assertEquals(10,post.getViewCount());
 }
 @Test void publishedPostCannotBeDeleted() {
  when(posts.findById(1L)).thenReturn(Optional.of(post));assertThrows(BusinessException.class,()->service.delete(1L));verify(posts,never()).delete(any(Post.class));
 }
 @Test void draftCanBeDeleted() {
  post.setStatus(PostStatus.DRAFT);when(posts.findById(1L)).thenReturn(Optional.of(post));service.delete(1L);verify(posts).delete(post);
 }
 private PostRequest request(PostStatus status,Instant date) {return new PostRequest(2L,"Tiêu đề",null,"https://example.com/cover.jpg","Nội dung",status,date);}
 @Test void publishingInactiveCategoryIsRejected() {
  category.setActive(false);when(categories.findById(2L)).thenReturn(Optional.of(category));
  assertThrows(BusinessException.class,()->service.save(null,request(PostStatus.PUBLISHED,null),3L));verify(posts,never()).save(any());
 }
 @Test void createAssignsAuthenticatedAuthorAndPublicationTime() {
  when(categories.findById(2L)).thenReturn(Optional.of(category));when(posts.save(any())).thenAnswer(i->i.getArgument(0));
  PostResponse saved=service.save(null,request(PostStatus.PUBLISHED,null),9L);
  assertEquals(9L,saved.authorId());assertNotNull(saved.publishedAt());
 }
 @Test void updatePreservesAuthorAndSchedule() {
  Instant scheduled=Instant.now().plusSeconds(3600);when(posts.findById(1L)).thenReturn(Optional.of(post));
  when(categories.findById(2L)).thenReturn(Optional.of(category));when(posts.save(any())).thenAnswer(i->i.getArgument(0));
  PostResponse saved=service.save(1L,request(PostStatus.PUBLISHED,scheduled),9L);
  assertEquals(3L,saved.authorId());assertEquals(scheduled,saved.publishedAt());
 }
 @Test void duplicateTitleGetsAutomaticUniqueSlug() {
  when(posts.existsBySlug("tieu-de")).thenReturn(true);
  when(categories.findById(2L)).thenReturn(Optional.of(category));when(posts.save(any())).thenAnswer(i->i.getArgument(0));
  PostResponse saved=service.save(null,request(PostStatus.DRAFT,null),3L);
  assertTrue(saved.slug().matches("tieu-de-[0-9]+"));
 }
 @Test void slugNormalizesVietnameseTitleWithoutClientSlug() {
  when(categories.findById(2L)).thenReturn(Optional.of(category));when(posts.save(any())).thenAnswer(i->i.getArgument(0));
  var r=new PostRequest(2L,"  Đầm Lụa: Phối Đồ & 2026!  ",null,"https://example.com/cover.jpg","Nội dung",PostStatus.DRAFT,null);
  assertEquals("dam-lua-phoi-do-2026",service.save(null,r,3L).slug());
 }
 @Test void titleWithNoLettersOrDigitsIsRejected() {
  var r=new PostRequest(2L,"!!!",null,"https://example.com/cover.jpg","Nội dung",PostStatus.DRAFT,null);
  assertThrows(BusinessException.class,()->service.save(null,r,3L));verify(posts,never()).save(any());
 }
 @Test void unchangedTitlePreservesExistingSuffixedSlug() {
  post.setTitle("Tiêu đề");post.setSlug("tieu-de-123");
  when(posts.findById(1L)).thenReturn(Optional.of(post));when(categories.findById(2L)).thenReturn(Optional.of(category));when(posts.save(any())).thenAnswer(i->i.getArgument(0));
  assertEquals("tieu-de-123",service.save(1L,request(PostStatus.DRAFT,null),3L).slug());
  verify(posts,never()).existsBySlugAndIdNot(anyString(),anyLong());
 }
 @Test void categorySlugIsGeneratedFromVietnameseName() {
  when(categories.save(any())).thenAnswer(i->i.getArgument(0));
  var saved=service.saveCategory(null,new PostCategoryRequest("  Câu chuyện Đầm & Áo  ",true));
  assertEquals("cau-chuyen-dam-ao",saved.getSlug());
 }
 @Test void duplicateCategorySlugGetsSuffix() {
  when(categories.existsBySlug("phong-cach")).thenReturn(true);
  when(categories.save(any())).thenAnswer(i->i.getArgument(0));
  assertTrue(service.saveCategory(null,new PostCategoryRequest("Phong cách",true)).getSlug().matches("phong-cach-[0-9]+"));
 }
 @Test void unchangedCategoryNameKeepsSlug() {
  category.setSlug("phong-cach-123");
  when(categories.findById(2L)).thenReturn(Optional.of(category));when(categories.save(any())).thenAnswer(i->i.getArgument(0));
  assertEquals("phong-cach-123",service.saveCategory(2L,new PostCategoryRequest("Phong cách",false)).getSlug());
 }
 @Test void categoryWithoutLettersOrDigitsIsRejected() {
  assertThrows(BusinessException.class,()->service.saveCategory(null,new PostCategoryRequest("!!!",true)));
  verify(categories,never()).save(any());
 }
 @Test void categoryCoverIsSavedAndPreservedWhenOmitted() {
  when(categories.save(any())).thenAnswer(i->i.getArgument(0));
  var saved=service.saveCategory(null,new PostCategoryRequest("Phong cách",true,"https://cloud.example/category.jpg"));
  assertEquals("https://cloud.example/category.jpg",saved.getThumbnail());
  saved.setId(2L);
  when(categories.findById(2L)).thenReturn(Optional.of(saved));
  assertEquals("https://cloud.example/category.jpg",service.saveCategory(2L,new PostCategoryRequest("Phong cách",false)).getThumbnail());
 }
}
