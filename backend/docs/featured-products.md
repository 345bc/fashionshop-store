# Sản phẩm nổi bật tự động

`GET /api/v1/product/featured?size=8` công khai, size giới hạn 1–24. Đã gắn khối FE trên trang chủ.

Response data: windowFrom/windowTo/computedAt (UTC), totalTransactions, baselineRating, title, description, isDisplay, products. Mỗi phần tử gồm product (ProductCardResponse chuẩn với ảnh/màu/giá thực tế), transactions, netQuantity, support (0–1), adjustedRating (1–5), score (0–1).

- Cửa sổ mặc định 30 ngày (admin chỉnh 1–365 ngày) lùi theo thời điểm giao thành công đầu tiên trong order_histories. Chỉ đơn DELIVERED/RETURNED có lịch sử DELIVERED thật; không suy đoán bằng ngày tạo/cập nhật, không tính giao thất bại.
- Mẫu số: tất cả giao dịch được giao thành công trong cửa sổ, gồm cả giao dịch đã trả hết. Tử số: số đơn còn giữ ít nhất một chiếc sản phẩm. Mua nhiều biến thể hay nhiều chiếc trong một đơn chỉ tính một lần xuất hiện.
- Trừ return_items của yêu cầu RECEIVED/COMPLETED có received_at không vượt thời điểm tính. Trả một phần giảm số lượng, trả hết các biến thể loại sản phẩm khỏi giao dịch. PENDING/APPROVED/REJECTED/CANCELLED không bị trừ.
- Support = transactions/totalTransactions. Điểm mua = support/maxSupport của tập sản phẩm đủ điều kiện lúc tính.
- Đánh giá dùng toàn bộ lịch sử công khai, sao hợp lệ 1–5, không lấy đánh giá ẩn/tương lai. C là sao trung bình toàn hệ thống (mặc định 3 nếu chưa có); v là số đánh giá, R là trung bình sản phẩm. adjustedRating=(v*R+10*C)/(v+10). Không đánh giá dùng C, không giả thành 5 sao.
- score=(purchaseWeight/100)*điểm mua+(reviewWeight/100)*(adjustedRating/5), mặc định 60/40. Xếp score giảm dần, bằng nhau số lượng bán ròng giảm dần, cuối cùng id tăng dần cho ổn định. Không xếp sản phẩm chưa có đơn hợp lệ.
- Chỉ trả sản phẩm đang bán, danh mục bật và có ít nhất một biến thể bật còn hàng khả dụng (stock-reserved>0). Kiểm tra lại điều kiện và giá/thẻ sản phẩm mỗi request. Ẩn cả mục FE nếu products rỗng, không thay bằng mẫu.
- Cache thống kê và thứ hạng 15 phút trong từng tiến trình, refresh có khóa để tránh tổng hợp trùng. Trả computedAt cho phép thấy tuổi dữ liệu. Không giữ thẻ sản phẩm/giá trong cache. Hàng trả/đánh giá mới ảnh hưởng thứ hạng sau tối đa 15 phút; thay đổi hoạt động/tồn kho được kiểm tra mỗi request.
- Không dùng FP-Growth cho xếp hạng một sản phẩm. FP-Growth dành cho bài toán mua cùng sau này.

## Quản lý trong admin

Giao diện trang chủ → Sản phẩm nổi bật. `GET/PUT /api/v1/admin/home/featured-products` dành cho ADMIN/MARKETING, nhận title (bắt buộc, 200), description (500), windowDays (1–365), purchaseWeight/reviewWeight (0–100, tổng=100), isDisplay (bắt buộc). Migration V48 lưu cấu hình riêng; không chọn sản phẩm thủ công. Số lượng trang chủ cố định tối đa 8.

Thay đổi số ngày/tỷ trọng làm cache hết hiệu lực ngay lần request tiếp theo. Sửa tiêu đề/mô tả không cần tổng hợp lại; nội dung mới trả ngay. Tắt hiển thị trả products rỗng, không tổng hợp thống kê; khi rỗng FE ẩn cả mục. Không áp dụng khoảng ngày xét lên đánh giá: đánh giá công khai dùng toàn bộ lịch sử.
