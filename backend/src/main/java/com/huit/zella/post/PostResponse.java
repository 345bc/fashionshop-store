package com.huit.zella.post;

import java.time.Instant;

public record PostResponse(Long id, Long categoryId, String categoryName, Long authorId,
                           String title, String slug, String summary, String thumbnail, String content,
                           PostStatus status,
                           int viewCount, Instant publishedAt, Instant createdAt, Instant updatedAt) {
    static PostResponse from(Post p, boolean detail) {
        return from(p, detail, p.getViewCount());
    }

    static PostResponse from(Post p, boolean detail, int views) {
        return new PostResponse(p.getId(), p.getCategory().getId(), p.getCategory().getName(), p.getAuthorId(),
                p.getTitle(), p.getSlug(), p.getSummary(), p.getThumbnail(), detail ? p.getContent() : null, p.getStatus(),
                views, p.getPublishedAt(), p.getCreatedAt(), p.getUpdatedAt());
    }
}
