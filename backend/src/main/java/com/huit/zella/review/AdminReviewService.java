package com.huit.zella.review;

import com.huit.zella.common.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;

@Service @RequiredArgsConstructor @Transactional(readOnly = true)
public class AdminReviewService {
    private final ProductReviewRepository reviews;

    public Page<AdminReviewResponse> list(Pageable page) {
        return reviews.findAll(page).map(AdminReviewResponse::from);
    }

    public AdminReviewResponse get(long id) { return AdminReviewResponse.from(find(id)); }

    @Transactional
    public AdminReviewResponse reply(long id, ReviewReplyRequest request, String actor) {
        var r = findForUpdate(id);
        event(r, r.getAdminReply() == null ? "Trả lời khách hàng" : "Cập nhật câu trả lời", actor, request.text().strip());
        r.setAdminReply(request.text().strip());
        r.setRepliedAt(Instant.now());
        r.setUpdatedAt(Instant.now());
        return AdminReviewResponse.from(reviews.save(r));
    }

    @Transactional
    public AdminReviewResponse moderate(long id, ReviewModerationRequest request, String actor) {
        var r = findForUpdate(id);
        if (r.isHidden() != request.hidden()) {
            r.setHidden(request.hidden());
            r.setModerationReason(request.reason().strip());
            r.setUpdatedAt(Instant.now());
            event(r, request.hidden() ? "Ẩn đánh giá" : "Hiển thị lại đánh giá", actor, request.reason().strip());
            reviews.save(r);
        }
        return AdminReviewResponse.from(r);
    }

    private ProductReview find(long id) {
        return reviews.findById(id).orElseThrow(() -> new BusinessException(
                HttpStatus.NOT_FOUND, "REVIEW_NOT_FOUND", "Không tìm thấy đánh giá"));
    }

    private ProductReview findForUpdate(long id) {
        return reviews.findForUpdate(id).orElseThrow(() -> new BusinessException(
                HttpStatus.NOT_FOUND, "REVIEW_NOT_FOUND", "Không tìm thấy đánh giá"));
    }

    private void event(ProductReview r, String action, String actor, String note) {
        var h = new ReviewHistory();
        h.setReview(r); h.setAction(action); h.setActor(actor); h.setNote(note);
        r.getHistory().add(h);
    }
}
