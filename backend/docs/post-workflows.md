# Nghiệp vụ bài viết

- Admin và Marketing quản lý danh mục, viết/sửa bài, tìm theo tiêu đề, lọc danh mục/trạng thái và phân trang.
- Bài có tiêu đề, slug duy nhất, danh mục, tóm tắt, URL ảnh bìa và nội dung rich text. Admin dùng Flutter Quill với tiêu đề, đậm/nghiêng/gạch chân, gạch ngang, danh sách, trích dẫn, liên kết, căn lề, ảnh trong nội dung và xem trước. Website hiển thị bằng React, không thực thi HTML.
- Tác giả lấy từ phiên đăng nhập khi tạo; người sửa không thay tác giả.
- DRAFT: bản nháp, không công khai, có thể xóa. PUBLISHED: công khai khi publishedAt <= thời gian hiện tại. ARCHIVED: ẩn, vẫn giữ nội dung và lượt đọc.
- Để trống thời gian khi xuất bản lần đầu sẽ đăng ngay. Chọn thời gian tương lai để hẹn giờ; API tự kiểm tra thời gian mỗi lần đọc, không cần scheduler. Sửa bài đang xuất bản và bỏ trống thời gian giữ nguyên ngày xuất bản cũ. Chuyển về nháp/ẩn xóa thời gian xuất bản.
- Danh mục tắt sẽ ẩn tất cả bài liên quan, kể cả khi truy cập trực tiếp. Bật lại sẽ hiển thị các bài đủ điều kiện. Không cho xuất bản mới vào danh mục đang tắt.
- Khách đọc danh sách và chi tiết qua slug; bài chưa công khai trả 404. API chi tiết chỉ đọc dữ liệu, không tăng lượt xem. Lượt xem được ghi nhận bằng phiên đọc riêng sau 10 giây hiển thị bài; mỗi trình duyệt tối đa một lượt cho mỗi bài trong 5 phút.
- Slug bài viết tự sinh từ tiêu đề theo quy tắc sản phẩm: bỏ dấu tiếng Việt, chuyển chữ thường và phân tách bằng gạch ngang; trùng thì thêm hậu tố thời gian. Giữ nguyên slug khi sửa mà không đổi tiêu đề. Ảnh bìa chọn file JPG/PNG/GIF/WebP, tải lên Cloudflare R2 qua POST /api/v1/admin/posts/images (multipart field file), lưu URL cloud vào thumbnail. Kiểm tra chữ ký file và dung lượng theo app.storage.max-bytes. Nội dung tối đa 100.000 ký tự, tóm tắt 500 ký tự.

## API

Public: GET /api/v1/posts?q=&categoryId=&page=0&size=12; GET /api/v1/posts/categories; GET /api/v1/posts/{slug}.

Quản trị (ADMIN/MARKETING): GET/POST /api/v1/admin/posts; GET/PUT/DELETE /api/v1/admin/posts/{id}; GET/POST /api/v1/admin/posts/categories; PUT /api/v1/admin/posts/categories/{id}.

Dữ liệu dùng bảng post và post_categories từ V7. Không thêm dữ liệu mẫu. Tạo danh mục, tạo bài rồi xuất bản để hiển thị trên website. Thời gian quản trị nhập theo giờ của máy, gửi API dưới dạng UTC.

Ảnh được chọn có xem trước; tải lên khi lưu bài. Nếu lưu bài thất bại sau upload, lần thử lại dùng URL đã nhận. Đổi ảnh bìa không tự xóa ảnh cloud cũ để tránh làm hỏng các liên kết đang dùng. Cấu hình R2 dùng chung với ảnh sản phẩm; không đưa khóa cloud xuống frontend.

## Nội dung Quill

Trường content tiếp tục là chuỗi, không cần đổi schema. Bài mới lưu `zella-quill-v1:` theo sau bởi mảng Quill Delta JSON gồm các thao tác insert; bài cũ không có prefix được đọc là văn bản thuần và chuyển thành document khi mở editor. Lưu/mở lại giữ định dạng và URL ảnh. Backend kiểm tra cấu trúc, nội dung không rỗng, dòng kết thúc và URL http/https; từ chối ảnh data/file và liên kết javascript. Giới hạn 100.000 ký tự áp dụng cho chuỗi đã serialize, tối đa 10.000 thao tác.

Ảnh chèn trong nội dung được upload ngay khi chọn, dùng cùng endpoint R2 với ảnh bìa, rồi chèn URL vào document tại vị trí con trỏ. Không cho lưu/đóng editor trong lúc upload; lỗi upload không chèn URL vào bài. Ảnh đã upload không bị xóa nếu hủy soạn thảo. Xem trước dùng bản sao document chỉ đọc; nội dung không bị thay đổi. Cần cập nhật cả backend và website cùng bản admin mới để đọc định dạng này.

Slug danh mục cũng tự sinh từ tên theo cùng quy tắc bài viết. Khi tên không đổi, giữ nguyên slug hiện tại; khi trùng đường dẫn, thêm hậu tố thời gian. Giao diện và request không còn yêu cầu nhập slug danh mục.

## Lượt xem và đề xuất

- GET /api/v1/posts/{slug}: đọc bài, không thay đổi lượt xem.
- POST /api/v1/posts/{slug}/view-session: tạo token ngẫu nhiên gắn với bài, mã trình duyệt và thời gian server. Khi chưa có mã trình duyệt, server cấp cookie zella_reader (HttpOnly, SameSite=Lax, Secure theo cấu hình cookie JWT, hiệu lực 365 ngày). Hai endpoint POST cho phép khách, vẫn yêu cầu CSRF qua apiClient dùng chung.
- POST /api/v1/posts/{slug}/views với body {"token":"..."}: server từ chối nếu chưa đủ 10 giây, sai bài/sai trình duyệt, phiên quá 1 giờ hoặc bài không còn công khai. Một token chỉ được hoàn tất một lần. Thử lại sau lỗi mạng không tăng trùng.
- Khóa dòng bài viết trong transaction trước khi kiểm tra lượt xem gần nhất của trình duyệt, cập nhật mốc và tăng bộ đếm. Mở nhiều tab dùng cùng cookie vẫn chỉ được tính một lượt trong cửa sổ 300 giây tính từ lượt được ghi nhận gần nhất. Lượt bị bỏ qua không kéo dài cửa sổ. Đúng mốc 5 phút được tính lại bằng phiên đọc mới đủ thời gian.
- FE chỉ bắt đầu đo sau khi tải thành công nội dung. Chỉ cộng thời gian tab hiển thị, tạm dừng khi chuyển tab, hủy khi rời bài. Một lần mở bài chỉ gửi một lượt được xác nhận; không tự tạo lượt mới mỗi 5 phút khi giữ nguyên trang.
- Mã trình duyệt dựa trên cookie, không phải fingerprint; xóa cookie hoặc dùng chế độ ẩn danh tạo định danh mới. Không lưu địa chỉ IP hoặc tài khoản để chống trùng.
- Migration V42 tạo post_view_sessions và post_view_readers. Dọn phiên quá 1 giờ và dữ liệu chống trùng quá 1 ngày mỗi giờ; số lượt xem tổng trong post không bị xóa.
- GET /api/v1/posts/recommendations: lấy nhóm 3 bài công khai mới nhất theo publishedAt DESC, id DESC. Bài số 1 dành cho phần Bài viết mới nhất; đề xuất lấy bài số 2 và 3, sau đó 2 bài nhiều lượt xem nhất ngoài cả nhóm 3 bài. Lượt xem bằng nhau ưu tiên bài mới hơn rồi id lớn hơn. Chỉ dùng bài đã đến giờ xuất bản thuộc danh mục bật. Khi không đủ bài, trả số bài thực tế, không chèn dữ liệu mẫu.

## Trang danh mục bài viết

Danh mục lưu ảnh bìa `thumbnail` (migration V43). Admin chọn ảnh từ máy, tải lên cloud qua `POST /api/v1/admin/posts/images` rồi lưu URL cùng tên và trạng thái danh mục. Gửi thiếu thumbnail khi cập nhật giữ nguyên ảnh cũ.

Nhấp danh mục mở `/blog/category/{slug}`: banner từ ảnh bìa danh mục, tìm kiếm trong danh mục, bài mới nhất, đề xuất và lưới tất cả bài viết phân trang 12 bài. `GET /api/v1/posts/recommendations?categoryId=...` giới hạn cả bài mới và bài nhiều lượt xem trong danh mục; bỏ tham số giữ đề xuất toàn hệ thống. Danh mục cũ chưa có ảnh cần bổ sung trong admin.

## Bài viết được đọc nhiều trên trang chủ

Tạm thời `GET /api/v1/posts/popular` trả tối đa 1 bài có tổng `view_count` cao nhất, chưa lọc theo 7 ngày. Chỉ lấy bài công khai, đã đến giờ xuất bản, danh mục đang bật và có ít nhất một lượt xem. Bằng lượt xem thì ưu tiên ngày đăng mới hơn rồi ID lớn hơn. Banner dùng `viewCount`, không hiển thị nhãn thời gian; không có kết quả thì ẩn toàn bộ khối.

Lịch sử `post_view_events` vẫn ghi nhận lượt xem hợp lệ để có thể khôi phục thống kê 7 ngày sau này. Quy tắc đọc tối thiểu 10 giây và giới hạn một lượt mỗi trình duyệt/bài trong 5 phút giữ nguyên.
