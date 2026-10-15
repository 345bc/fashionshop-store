# Phản hồi khách hàng — nghiệp vụ và tích hợp

Trang quản trị xử lý đánh giá sản phẩm đã được khách gửi từ đơn hàng. Chỉ ADMIN và CUSTOMER_SUPPORT được đọc và xử lý qua API. Không sửa nội dung/số sao và không xóa đánh giá của khách.

## Luồng nghiệp vụ

- Cần xử lý: mặc định đánh giá đang hiển thị, chưa trả lời, mới nhất trước. Trả lời ngay; gửi thành công mới xóa bản nháp và chọn phản hồi tiếp theo trong bộ lọc. Khi lỗi giữ nguyên phản hồi và bản nháp để thử lại.
- Theo sản phẩm: chỉ sản phẩm có đánh giá, ưu tiên sản phẩm có đánh giá chưa trả lời rồi đến phản hồi mới nhất. Xem tổng đánh giá, điểm trung bình và số chưa trả lời. Điểm trung bình chỉ tính đánh giá đang hiển thị.
- Tìm khách hàng, email, nội dung, mã đơn, sản phẩm/SKU; lọc danh mục cha/con, số sao và trạng thái. Mỗi chế độ/sản phẩm giữ bộ lọc riêng; đổi chế độ không gửi nhầm truy vấn đang chờ.
- Bản nháp giữ trong bộ nhớ theo mã đánh giá. Hộp chi tiết và vùng trả lời dùng chung bản nháp. Làm mới tải lại dữ liệu; không tự thay dữ liệu thật bằng dữ liệu mẫu khi API lỗi.
- Ẩn nội dung spam, vi phạm hoặc lộ thông tin cá nhân; không ẩn chỉ vì ít sao. Ẩn/hiện đều bắt buộc lý do, giữ nguyên nội dung và số sao. Đánh giá ẩn ra khỏi hàng chờ mặc định nhưng vẫn truy cập bằng bộ lọc Đã ẩn.
- Mỗi lần trả lời/cập nhật/ẩn/hiện lưu thời gian, người thao tác từ phiên đăng nhập và nội dung thao tác trong review_history. Lặp lại cùng trạng thái hiển thị không thêm sự kiện.

## API và validation

Base: `/api/v1/admin/reviews` (cookie đăng nhập và CSRF theo cơ chế hiện tại).

| Request | Validation |
| --- | --- |
| GET `?page=0&size=100` | page >= 0; size 1–100; kiểu số hợp lệ |
| GET `/{id}` | id là số nguyên dương; không tồn tại trả 404 |
| PUT `/{id}/reply` với `{text}` | id dương; text bắt buộc, không trắng, tối đa 1000 ký tự |
| PUT `/{id}/visibility` với `{hidden, reason}` | id dương; hidden bắt buộc; reason không trắng, tối đa 500 ký tự |

Body dùng Bean Validation qua @Valid; tham số dùng method validation. JSON sai/kiểu tham số sai trả 400 theo ApiError chung. Frontend kiểm tra giới hạn trước gửi; backend vẫn kiểm tra độc lập. Request lỗi không ghi dữ liệu. Ghi đánh giá và lịch sử trong cùng transaction; khóa bản ghi khi cập nhật để các thao tác đồng thời không làm mất lịch sử.

## Dữ liệu và vận hành

Migration V39 thêm moderation_reason và bảng review_history; V40 chuyển cột thời gian lịch sử sang DATETIMEOFFSET(7) phù hợp với Java Instant. Không tạo dữ liệu đánh giá mẫu. Chạy backend với Flyway để áp dụng migration trước khi dùng trang. Lịch sử trước khi tích hợp không được dựng giả; câu trả lời cũ vẫn hiển thị theo admin_reply/replied_at.

Repository mặc định gọi API thật. Constructor FeedbackRepository.demo() chỉ dành cho fixture kiểm thử. Metadata sản phẩm/danh mục lấy từ phản hồi backend, không dùng danh mục gán cứng khi chạy thật.

Giới hạn hiện tại: API phân trang 100 bản ghi/lần; frontend tải lần lượt toàn bộ các trang rồi tìm/lọc/phân trang trong bộ nhớ để giữ hai luồng hiện có. Với dữ liệu lớn cần chuyển tìm kiếm, bộ lọc, thống kê và danh sách sản phẩm sang truy vấn server. Bản nháp không tồn tại sau khi đóng ứng dụng. Các kiểm thử API cô lập không thay thế kiểm thử kết nối SQL Server và phiên đăng nhập thực tế.
