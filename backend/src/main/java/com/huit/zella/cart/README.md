# Giỏ hàng

## Lưu trữ

- Khách chưa đăng nhập: localStorage `zella.guest-cart.v1`, lưu variantId và quantity.
- Tài khoản: bảng carts và cart_items có sẵn; userId luôn lấy từ principal.
- Khi đăng nhập, gộp giỏ khách vào tài khoản, cộng số lượng cùng biến thể. Chỉ xóa giỏ khách sau khi backend trả thành công. mergeKey lưu ở carts giúp gửi lại không cộng hai lần.
- Giỏ không giữ hàng. Giá, ảnh, màu, size, tồn khả dụng được đọc từ backend.
- Dòng hết hàng/ngừng bán vẫn hiển thị để sửa hoặc bỏ chọn. Tối đa 200 biến thể, 999 sản phẩm mỗi dòng.

## API

Tất cả response dùng ApiResponse<CartResponse>. Không phân trang giỏ hàng.

| Method | Đường dẫn | Ý nghĩa |
| --- | --- | --- |
| GET | /api/v1/cart | Giỏ tài khoản đang đăng nhập |
| POST | /api/v1/cart/quote | Tính giỏ khách: `{items:[{variantId,quantity}]}`; công khai, có CSRF |
| POST | /api/v1/cart/items | Thêm/cộng số lượng `{variantId,quantity}` |
| PATCH | /api/v1/cart/items/{variantId} | Đặt số lượng `{quantity}` |
| PUT | /api/v1/cart/items/{variantId} | Đổi biến thể `{variantId,quantity}` và gộp dòng đích trong cùng transaction |
| DELETE | /api/v1/cart/items/{variantId} | Xóa một dòng |
| DELETE | /api/v1/cart/items | Xóa toàn bộ |
| POST | /api/v1/cart/merge | Gộp `{mergeKey,items}`; cần đăng nhập |

## Checkout

- FE chọn các dòng muốn mua, gửi variantId/quantity cùng thông tin giao hàng qua API checkout hiện có. Giá và phí giao hàng do BE tính.
- Tạo đơn thành công: chỉ trừ số lượng đã mua khỏi giỏ; giữ hàng 5 phút trong đơn PENDING.
- checkoutKey là UUID do FE lưu trước request. Backend tận dụng checkout_token_hash và unique index để tránh tạo lại đơn khi gửi lại request.
- Token xem đơn chỉ lưu ở sessionStorage; không đưa vào URL. Poll trạng thái mỗi 5 giây và dừng khi đơn không còn PENDING.
- Hủy để sửa giỏ: POST /api/v1/checkout/orders/{code}/cancel với X-Checkout-Token. Chỉ cho hủy đơn PENDING chưa trả tiền, giải phóng tồn, rồi đưa các dòng về giỏ. Khôi phục có mergeKey để tránh lặp.
- Đơn hết hạn tự hủy theo job có sẵn; khách có thể đưa sản phẩm về giỏ. Đơn đã trả tiền giữ nguyên nội dung.
- Cổng thanh toán chưa tích hợp. Nút giả lập thanh toán hiện có ở admin dùng để kiểm tra luồng.

## Kiểm tra

1. Khách thêm cùng biến thể hai lần; giỏ cộng số lượng, reload vẫn giữ giỏ.
2. Đổi màu/size sang biến thể đã có trong giỏ; chỉ còn một dòng đích.
3. Đăng nhập; giỏ khách được gộp. Gửi lại mergeKey không cộng lần nữa.
4. Chọn một phần giỏ để đặt hàng; phần chưa mua vẫn còn.
5. Sửa tồn kho ở admin; giỏ báo thiếu hàng và không cho checkout dòng đó.
6. Tạo đơn, hủy về sửa giỏ; tồn được giải phóng và dòng được khôi phục một lần.
7. Để đơn hết 5 phút hoặc giả lập trả tiền ở admin; checkout cập nhật đúng trạng thái.

Migration mới: V24__cart_guest_merge_keys.sql. Không sửa các migration đã chạy.
