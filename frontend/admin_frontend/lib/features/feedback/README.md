# Phản hồi sản phẩm — luồng FE

## Hai chế độ

- Cần xử lý: mặc định đánh giá đang hiển thị, chưa trả lời, mới nhất trước.
  Chọn phản hồi đọc/trả lời ngay ở vùng bên phải. Gửi & xem tiếp lưu câu trả lời
  và chuyển đến phản hồi tiếp theo trong bộ lọc hiện tại; khi hết hiện trạng thái rỗng.
  Lọc danh mục cha/con, số sao, trạng thái; tìm tên khách, nội dung, mã đơn, sản phẩm/SKU.
- Theo sản phẩm: chỉ sản phẩm có đánh giá, ưu tiên sản phẩm có phản hồi chưa trả lời,
  sau đó phản hồi mới nhất. Tìm tên/SKU, lọc danh mục cha/con, phân trang.
  Chọn sản phẩm xem đánh giá và điểm trung bình, trả lời ngay.
  Quay lại giữ bộ lọc và trang của danh sách sản phẩm.
- Mỗi chế độ và từng sản phẩm giữ trạng thái tìm kiếm/lọc riêng.
  Bản nháp câu trả lời được giữ trong bộ nhớ khi đổi phản hồi/chế độ.
  Lịch sử và ẩn/hiện mở trong dialog cho những thao tác ít dùng.
- Màn hình hẹp xếp danh sách và chi tiết theo chiều dọc.

## Dữ liệu và entity

Chỉ FE, dữ liệu mẫu trong bộ nhớ. ProductReview gắn Product, Order/OrderItem,
CustomerProfile nullable (khách vãng lai). Câu trả lời dùng admin_reply/replied_at
trong đánh giá hiện có. Danh mục dùng cấu trúc cha/con của Category hiện có.
Không thêm entity/bảng BE. Metadata sản phẩm/danh mục và lịch sử trong FE là dữ liệu
trình bày mẫu; khi tích hợp BE phải xác minh khách đã mua và quyền thao tác.
Điểm sao sản phẩm chỉ tính đánh giá đang hiển thị; số tổng có cả đánh giá ẩn.
Phản hồi ẩn không nằm trong hàng chờ mặc định, vẫn truy cập bằng bộ lọc Đã ẩn.

Repository chứa dữ liệu mẫu; provider xử lý state/bộ lọc/phân trang/chuyển tiếp;
widgets tách bộ lọc danh mục, danh sách sản phẩm, workspace đọc/trả lời.
Khi nối BE cần phân trang/tìm kiếm ở server và chỉ tải đánh giá sản phẩm được chọn;
bản demo hiện giữ bộ dữ liệu nhỏ trong bộ nhớ, không thực hiện gọi API.
