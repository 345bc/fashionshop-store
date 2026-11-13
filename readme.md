# Zella — Website bán thời trang

Zella là website shop thời trang thuộc đề tài CNTT-DACN048. Khách hàng có thể xem danh mục, chọn sản phẩm theo màu và kích cỡ, đặt hàng trực tuyến, theo dõi đơn hàng và sử dụng ưu đãi thành viên. quản lý cửa hàng qua ứng dụng Admin.

## Website khách hàng

**[Truy cập Zella](https://zella.id.vn/)**

- Xem sản phẩm, thêm vào giỏ hàng và thanh toán.
- Theo dõi đơn hàng và xem lịch sử mua hàng.
- Xem điểm thưởng, đổi voucher và nhận giảm giá theo hạng thành viên.

Mã nguồn giao diện khách hàng dùng Next.js. [Mã nguồn website](frontend/client_frontend/) · [Hướng dẫn chạy tại máy](docs/client-README.md)

## Ứng dụng quản trị

**[Tải Zella Admin cho Windows x64](https://github.com/345bc/fashionshop-store/releases)**

1. Mở bản phát hành có thẻ `admin-vX.Y.Z` và tải `zella-admin-windows-x64.zip` trong mục **Assets**.
2. Giải nén toàn bộ ZIP, sau đó mở tệp `.exe` trong thư mục đã giải nén.
3. Đăng nhập bằng tài khoản nhân viên đã được cấp quyền để quản lý sản phẩm, tồn kho, đơn hàng, khách hàng và khuyến mãi.

Ứng dụng quản trị được viết bằng Flutter. [Mã nguồn quản trị](frontend/admin_frontend/) · [Hướng dẫn build và phát hành](docs/admin-CI_CD.md)

## Backend

Website và ứng dụng quản trị dùng chung API Spring Boot với Java 21. [Mã nguồn backend](backend/)
