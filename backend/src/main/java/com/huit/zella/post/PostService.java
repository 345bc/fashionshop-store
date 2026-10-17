package com.huit.zella.post;

import com.huit.zella.common.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;

import java.time.Instant;
import java.text.Normalizer;
import java.util.*;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PostService {
    private final PostRepository posts;
    private final PostCategoryRepository categories;

    public Page<PostResponse> list(boolean admin, String q, Long categoryId, PostStatus status, int page, int size) {
        Instant now = Instant.now();
        Specification<Post> spec = (root, query, cb) -> {
            var rules = new ArrayList<jakarta.persistence.criteria.Predicate>();
            if (!admin) {
                rules.add(cb.equal(root.get("status"), PostStatus.PUBLISHED));
                rules.add(cb.lessThanOrEqualTo(root.get("publishedAt"), now));
                rules.add(cb.isTrue(root.get("category").get("active")));
            } else if (status != null) rules.add(cb.equal(root.get("status"), status));
            if (categoryId != null) rules.add(cb.equal(root.get("category").get("id"), categoryId));
            if (q != null && !q.isBlank()) {
                String term = "%" + q.trim().toLowerCase(Locale.ROOT).replace("!", "!!").replace("%", "!%").replace("_", "!_") + "%";
                rules.add(cb.like(cb.lower(root.get("title")), term, '!'));
            }
            return cb.and(rules.toArray(jakarta.persistence.criteria.Predicate[]::new));
        };
        return posts.findAll(spec, PageRequest.of(Math.max(0, page), Math.max(1, Math.min(100, size)),
                Sort.by(Sort.Order.desc(admin ? "updatedAt" : "publishedAt"), Sort.Order.desc("id")))).map(p -> PostResponse.from(p, false));
    }

    public List<PostCategory> categories(boolean admin) {
        return admin ? categories.findAll(Sort.by("name")) : categories.findByActiveTrueOrderByNameAsc();
    }

    public PostResponse get(Long id) {
        return PostResponse.from(require(id), true);
    }

    public PostResponse read(String slug) {
        Post p = posts.findBySlug(slug).orElseThrow(this::missing);
        if (!visible(p, Instant.now())) throw missing();
        return PostResponse.from(p, true);
    }

    public List<PostResponse> recommendations() {
        return recommendations(null);
    }

    public List<PostResponse> recommendations(Long categoryId) {
        Instant now = Instant.now();
        Specification<Post> published = (root, query, cb) -> cb.and(
                cb.equal(root.get("status"), PostStatus.PUBLISHED),
                cb.lessThanOrEqualTo(root.get("publishedAt"), now),
                cb.isTrue(root.get("category").get("active")));
        if (categoryId != null) published = published.and((root, query, cb) ->
                cb.equal(root.get("category").get("id"), categoryId));
        List<Post> latest = posts.findAll(published, PageRequest.of(0, 3,
                Sort.by(Sort.Order.desc("publishedAt"), Sort.Order.desc("id")))).getContent();
        Set<Long> excluded = new HashSet<>();
        latest.forEach(p -> excluded.add(p.getId()));
        List<PostResponse> result = new ArrayList<>();
        latest.stream().skip(1).forEach(p -> result.add(PostResponse.from(p, false)));
        Specification<Post> popular = published.and((root, query, cb) -> excluded.isEmpty()
                ? cb.conjunction() : cb.not(root.get("id").in(excluded)));
        posts.findAll(popular, PageRequest.of(0, 2, Sort.by(Sort.Order.desc("viewCount"),
                Sort.Order.desc("publishedAt"), Sort.Order.desc("id"))))
                .forEach(p -> result.add(PostResponse.from(p, false)));
        return result;
    }

    static boolean visible(Post p, Instant now) {
        return p.getStatus() == PostStatus.PUBLISHED && p.getCategory().isActive() && p.getPublishedAt() != null && !p.getPublishedAt().isAfter(now);
    }

    @Transactional
    public PostResponse save(Long id, PostRequest r, Long authorId) {
        String content = PostContent.validate(r.content());
        Post p = id == null ? new Post() : require(id);
        String title = r.title().trim();
        String slug = p.getSlug();
        if (id == null || !title.equals(p.getTitle())) {
            slug = Normalizer.normalize(title, Normalizer.Form.NFD)
                    .replaceAll("\\p{InCombiningDiacriticalMarks}+", "")
                    .toLowerCase(Locale.ROOT).replace('đ', 'd')
                    .replaceAll("[^a-z0-9]+", "-").replaceAll("^-|-$", "");
            if (slug.isEmpty()) throw new BusinessException(HttpStatus.BAD_REQUEST,
                    "INVALID_POST_TITLE", "Tiêu đề không thể tạo đường dẫn bài viết");
            if (id == null ? posts.existsBySlug(slug) : posts.existsBySlugAndIdNot(slug, id)) {
                slug += "-" + System.currentTimeMillis();
            }
        }
        PostCategory c = categories.findById(r.categoryId()).orElseThrow(() -> error("POST_CATEGORY_NOT_FOUND", "Danh mục không tồn tại"));
        if (r.status() == PostStatus.PUBLISHED && !c.isActive())
            throw error("POST_CATEGORY_INACTIVE", "Cần bật danh mục trước khi xuất bản");
        if (id == null) p.setAuthorId(authorId);
        p.setCategory(c);
        p.setTitle(title);
        p.setSlug(slug);
        p.setSummary(r.summary() == null ? null : r.summary().trim());
        p.setThumbnail(r.thumbnail().trim());
        p.setContent(content);
        p.setStatus(r.status());
        p.setPublishedAt(r.status() == PostStatus.PUBLISHED ? (r.publishedAt() != null ? r.publishedAt() : (p.getPublishedAt() != null ? p.getPublishedAt() : Instant.now())) : null);
        p.setUpdatedAt(Instant.now());
        return PostResponse.from(posts.save(p), true);
    }

    @Transactional
    public PostCategory saveCategory(Long id, PostCategoryRequest r) {
        PostCategory c = id == null ? new PostCategory() : categories.findById(id).orElseThrow(() -> error("POST_CATEGORY_NOT_FOUND", "Danh mục không tồn tại"));
        String name = r.name().trim();
        String slug = c.getSlug();
        if (id == null || !name.equals(c.getName())) {
            slug = Normalizer.normalize(name, Normalizer.Form.NFD)
                    .replaceAll("\\p{InCombiningDiacriticalMarks}+", "")
                    .toLowerCase(Locale.ROOT).replace('đ', 'd')
                    .replaceAll("[^a-z0-9]+", "-").replaceAll("^-|-$", "");
            if (slug.isEmpty()) throw new BusinessException(HttpStatus.BAD_REQUEST,
                    "INVALID_POST_CATEGORY_NAME", "Tên danh mục không thể tạo đường dẫn");
            if (id == null ? categories.existsBySlug(slug) : categories.existsBySlugAndIdNot(slug, id)) {
                slug += "-" + System.currentTimeMillis();
            }
        }
        c.setName(name);
        c.setSlug(slug);
        c.setActive(r.active());
        if (r.thumbnail() != null) c.setThumbnail(r.thumbnail().trim());
        return categories.save(c);
    }

    @Transactional
    public void delete(Long id) {
        Post p = require(id);
        if (p.getStatus() != PostStatus.DRAFT)
            throw error("POST_DELETE_FORBIDDEN", "Chỉ xóa bản nháp; hãy chuyển bài đã xuất bản sang ẩn");
        posts.delete(p);
    }

    private Post require(Long id) {
        return posts.findById(id).orElseThrow(this::missing);
    }

    private BusinessException missing() {
        return new BusinessException(HttpStatus.NOT_FOUND, "POST_NOT_FOUND", "Không tìm thấy bài viết");
    }

    private BusinessException error(String code, String message) {
        return new BusinessException(HttpStatus.CONFLICT, code, message);
    }
}
