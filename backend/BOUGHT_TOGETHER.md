# Gợi ý mua kèm và khai phá luật kết hợp

Vào **SẢN PHẨM & KHO → Gợi ý mua kèm** bằng vai trò ADMIN hoặc MARKETING.

## Thuật toán

FP-Growth khai thác đệ quy các conditional FP-tree, tìm toàn bộ tập phổ biến từ cấp 1 đến n (n là số sản phẩm lớn nhất của tập phổ biến tìm được), không giới hạn ở cặp.

- Tập L phổ biến khi support(L) ≥ minsup.
- Số đơn cần đạt = ceil(N × minsup), không có ngưỡng số đơn mua chung bổ sung.
- Tập cấp 1 không sinh luật. Với mỗi tập L có từ 2 sản phẩm, chọn từng sản phẩm làm vế trái X để sinh X → L\X.
- Vế trái có đúng 1 sản phẩm; vế phải khác rỗng, không giao với vế trái. Chỉ sinh luật 1 → 1 và 1 → nhiều.
- Confidence = count(X ∪ Y) / count(X). Giữ luật confidence ≥ minconf.
- Lift = confidence / support(Y). Bảng kết quả khai phá hiển thị cả luật có lift ≤ 1; lift chỉ là bộ lọc khi chọn gợi ý.

Trang quản trị có bảng tập phổ biến, lọc theo cấp, bảng luật và phân trang. Các sản phẩm trong tập/luật được biểu diễn bằng ID.

## Gợi ý

Sản phẩm đang xem tạo ngữ cảnh một phần tử. API nhiều sản phẩm hỗ trợ ngữ cảnh giỏ hàng. Chỉ áp dụng luật mà sản phẩm ở vế trái nằm trong ngữ cảnh; gợi ý các sản phẩm ở vế phải chưa có trong ngữ cảnh. Không sinh luật có nhiều sản phẩm ở vế trái.

Luật được xếp theo confidence, lift, số lần xuất hiện giảm dần, sau đó ID hai vế để ổn định thứ tự. Mỗi sản phẩm lấy luật tốt nhất, không lặp sản phẩm, không gợi ý lại sản phẩm đã có. Chỉ hiển thị sản phẩm đang bán, danh mục đang hoạt động và có biến thể còn tồn khả dụng. Các chỉ số trong kết quả gợi ý thuộc toàn bộ luật tương ứng, không phải chỉ cặp sản phẩm.

Bộ lọc lift áp dụng nghiêm ngặt (lift > ngưỡng), số gợi ý bị giới hạn bởi cấu hình đã lưu. Không đủ điều kiện thì ẩn mục trên trang khách.

## Dữ liệu và cấu hình

Dùng đơn DELIVERED/RETURNED có lịch sử giao đầu tiên trong khoảng thời gian xét. Trừ hàng trả đã RECEIVED/COMPLETED; gộp biến thể thành sản phẩm, mỗi đơn tính một lần. Đơn trả hết vẫn nằm trong mẫu số.

Cấu hình lưu trong database bằng bảng V49, giữ qua restart/deploy. Không sửa migration V49 đã phát hành, không cần migration mới. Cột `min_cooccurrence` cũ được giữ để tương thích schema nhưng không đọc, không dùng và không hiển thị trong quản lý.

Mặc định: bật, lịch sử 180 ngày, minsup 1%, minconf 10%, bộ lọc gợi ý lift > 1, tối đa 8 sản phẩm. UI nhập support/confidence theo %, API dùng tỷ lệ 0–1.

Mô hình lưu bộ nhớ 15 phút. Đổi khoảng thời gian/minsup sẽ tính lại ở yêu cầu tiếp theo. Đổi minconf sẽ sinh lại luật từ tập phổ biến; thay lift/giới hạn/bật tắt áp dụng ngay. Nút tính lại lấy dữ liệu đơn mới theo cấu hình đã lưu.

Khai thác đầy đủ có số tập và luật tăng theo cấp số mũ khi một giỏ chứa nhiều sản phẩm; cần chọn minsup phù hợp với dữ liệu vận hành.

## API

API quản trị yêu cầu ADMIN hoặc MARKETING và cơ chế xác thực/CSRF hiện có:

- GET /api/v1/admin/bought-together/settings
- PUT /api/v1/admin/bought-together/settings
- GET /api/v1/admin/bought-together/status
- POST /api/v1/admin/bought-together/rebuild
- GET /api/v1/admin/bought-together/itemsets?page=0&size=20&level=0 (0: tất cả cấp)
- GET /api/v1/admin/bought-together/rules?page=0&size=20
- GET /api/v1/admin/bought-together/preview?productIds=1,2
- GET /api/v1/admin/bought-together/preview/{productId} (tương thích ngữ cảnh một sản phẩm)

Ví dụ lưu cấu hình:

```json
{"windowDays":180,"minSupport":0.01,"minConfidence":0.1,"minLift":1,"maxRecommendations":8,"enabled":true}
```

API khách:

- GET /api/v1/product/{id}/bought-together?size=24
- GET /api/v1/product/bought-together?productIds=1,2&size=24

Ngữ cảnh từ 1–50 ID nguyên dương. Gợi ý trả thêm antecedent/consequent để giải thích luật áp dụng.

## Kiểm chứng

FpGrowthTest đối chiếu mọi cấp tập phổ biến với đếm vét cạn trên 100 bộ giỏ ngẫu nhiên; kiểm tra tập 4 phần tử chỉ sinh 4 luật 1 → 3, không sinh luật có vế trái nhiều phần tử, tính đúng support/confidence/lift, ngưỡng confidence bao gồm dấu bằng.

BoughtTogetherServiceTest kiểm tra không yêu cầu thêm số lần mua chung, không lọc kết quả khai phá bằng lift, áp dụng đầy đủ vế trái, cache, cấu hình và tình trạng sản phẩm. BoughtTogetherManagementTest kiểm tra validation, lưu cấu hình và phân quyền. Flutter kiểm tra lưu cấu hình, xem tập cấp 3/luật nhiều sản phẩm và kiểm tra ngữ cảnh nhiều ID.

Kiểm thử không kết nối database thực tế.
