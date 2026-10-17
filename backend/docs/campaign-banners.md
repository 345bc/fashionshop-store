# Hiển thị chương trình và ưu đãi sản phẩm mới

## Chương trình giảm giá được quản lý

API quản lý `/api/v1/campaigns/promotion` chỉ chấp nhận targetMode=SELECTED. Tạo/sửa cần danh sách sản phẩm; NEW_PRODUCTS không xuất hiện trong danh sách và không được xem/sửa/bật/tắt qua API này. Voucher giữ luồng hiện có.

Admin chọn ảnh JPG/PNG/GIF/WebP tối đa 10 MB, tải lên cloud khi lưu qua `POST /api/v1/campaigns/images` (ADMIN/MARKETING). imageUrl/isDisplay bị bỏ khỏi request cập nhật sẽ giữ giá trị cũ. Bật isDisplay cần có ảnh.

`GET /api/v1/product/campaign-displays` công khai trả tất cả chương trình SELECTED đang hiệu lực, bật isDisplay, có ảnh và còn sản phẩm công khai đủ điều kiện. Mỗi khối gồm banner và tối đa 12 sản phẩm riêng, giá/ảnh/màu lấy từ dữ liệu thật. Sắp xếp mức giảm cao nhất rồi ID nhỏ nhất. Tắt chương trình, tắt display, chưa bắt đầu/đã hết hạn hoặc không có sản phẩm: ẩn cả khối. Click banner cuộn đến dãy sản phẩm của chính chương trình. Không dùng URL new=true.

## Ưu đãi sản phẩm mới tự động

Sản phẩm đang bán trong danh mục bật, có ngày tạo trong `(now - 7 ngày, now]`, tự hưởng giảm 5% không cần promotion. Đủ 7 ngày tự hết ưu đãi. Chọn mức giảm cao nhất với các chương trình SELECTED, không cộng dồn. Dùng chung cách làm tròn giá hiện tại. Giá gốc không bị thay đổi; giá chốt đơn giữ snapshot.

Migration V46 sao chép ảnh/tên/mô tả cũ sang `new_product_showcase`; giữ promotion cũ để bảo toàn lịch sử nhưng bỏ qua khi tính giá và quyết định hiển thị. Banner tự động xuất hiện nếu có ảnh và có sản phẩm mới đủ điều kiện, độc lập active/isDisplay/thời gian promotion cũ. Nếu thiếu ảnh thì không dựng banner giả, quy tắc giá vẫn hoạt động. Quy tắc giá không có giao diện chỉnh sửa.

API campaign-displays giữ hợp đồng FE và thêm khối tự động id=-1, targetMode=NEW_PRODUCTS, startsAt/endsAt=null, sau các khối SELECTED. Endpoint cũ `/api/v1/product/new-arrivals/spotlight` trả cùng khối tự động để giữ tương thích. Không có sản phẩm thì không hiển thị banner và dãy sản phẩm rỗng. Trang chủ không gọi dãy sản phẩm mới độc lập ngoài khối.

## Quản lý giao diện trang chủ

Admin/Marketing mở Giao diện trang chủ → Sản phẩm mới. `GET/PUT /api/v1/admin/home/new-products` quản lý title (bắt buộc, tối đa 200), description (500), imageUrl (HTTP/HTTPS, 500), isDisplay (Boolean bắt buộc). Upload ảnh dùng `/api/v1/campaigns/images`, giới hạn và kiểm tra cloud như chương trình hiện có. Không cập nhật bảng promotion hay quy tắc giảm giá qua API này.

Migration V47 thêm is_display mặc định true, giữ trạng thái hiện của các banner đã có. Tắt isDisplay ẩn cả banner + dãy sản phẩm; thiếu ảnh hay không có sản phẩm mới cũng ẩn cả khối. Tắt hiển thị không làm mất giảm giá tự động 5%. FE public không cần đổi endpoint.
