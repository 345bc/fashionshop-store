# Admin Windows CI/CD

## Quy trình

PR vào main → Analyze → Test → Build Windows để kiểm chứng biên dịch.
Push vào main → cùng các quality gate → build ứng viên → ZIP + manifest + SHA-256.
Người phát hành chọn CI run đã thành công → duyệt môi trường admin-production → phát hành đúng ZIP đã kiểm thử lên GitHub Releases. Release không build lại.

Workflow: `.github/workflows/admin-ci.yml` và `.github/workflows/admin-release.yml`, đặt ở gốc repository. Không đặt trong thư mục frontend. Chỉ source đã push lên GitHub mới chạy được.

## Thiết lập GitHub

1. Settings → Secrets and variables → Actions → Variables → New repository variable:
   - ADMIN_API_BASE_URL: URL backend, kết thúc bằng /api/v1.
   - Hiện tại có thể dùng http://13.212.21.72:8080/api/v1 cho bản ứng viên nội bộ. Public Release bắt buộc URL https://.../api/v1; cấu hình HTTPS cho BE trước.
   - Đây là URL công khai, không phải secret. Không đưa JWT_SECRET, mật khẩu DB, R2 secret hoặc token đăng nhập vào app/.env hoặc GitHub variable này.
2. Settings → Environments → New environment → admin-production:
   - Deployment branches: chỉ main.
   - Required reviewers, Prevent self-review nếu gói GitHub/repository hỗ trợ. Nếu không hỗ trợ, workflow_dispatch chỉ là nút phát hành thủ công, không thay thế phê duyệt độc lập; dùng private repo với gói hỗ trợ hoặc quy trình duyệt bên ngoài.
3. Settings → Rules → Rulesets hoặc Branch protection cho main:
   - Bắt buộc PR, ít nhất một người review, xử lý hết trao đổi, không force-push.
   - Sau lần CI đầu, đặt check `Validate and build Windows` là bắt buộc. PR workflow chạy trên mọi PR vào main để tránh check bị pending vô hạn khi PR chỉ sửa BE; push workflow chỉ build ứng viên khi admin/pipeline thay đổi.
4. Settings → Actions → General: cho phép các action đã dùng và GITHUB_TOKEN ghi contents trong release job (job đã khai báo quyền tối thiểu).
5. Bảo vệ tag admin-v* khỏi sửa/xóa; bảo đảm release workflow vẫn được phép tạo tag. Thêm CODEOWNERS cho .github/workflows để thay đổi pipeline cần người phụ trách review.

## Dùng hằng ngày

- Tạo nhánh feature, sửa admin, mở PR vào main. CI đỏ thì sửa lỗi; không bỏ analyze/test hoặc thêm continue-on-error để phát hành.
- Tăng `version` trong pubspec.yaml trước mỗi bản công bố, ví dụ 1.0.1+1. Build number được lấy từ github.run_number.
- Merge PR. Actions → Admin CI → run của main → Artifacts → admin-windows-build để tải bản ứng viên. Artifact lưu 14 ngày; hết hạn thì chạy build mới bằng một push hợp lệ lên main. Run thủ công không được public release.
- Kiểm thử bản Windows trên máy sạch, đăng nhập, quyền truy cập và các luồng nghiệp vụ cần dùng; EC2 và RDS phải đang chạy, security group cho phép IP máy kiểm thử truy cập BE.
- Actions → Admin Release → Run workflow → branch main → nhập ci_run_id, là số cuối URL /actions/runs/123456789. Người duyệt kiểm tra kết quả test và SHA trước khi approve environment.
- Repo → Releases → admin-vX.Y.Z: tải ZIP, giải nén toàn bộ, chạy exe. SHA256SUMS.txt đối chiếu bằng Get-FileHash. ZIP là bản portable, chưa phải installer MSI/EXE.
- Rollback: tải lại phiên bản trước trên Releases, bảo đảm còn tương thích API/DB. Không sửa nội dung hay thay ZIP của release đã phát hành.

## Kiểm soát và giới hạn

- Flutter cố định 3.47.0 khớp SDK local; pubspec.lock được enforce. GitHub Actions được pin commit SHA; nâng phiên bản qua PR có review.
- Pipeline không gọi RDS/BE thật để chạy unit/widget test; .env kiểm thử chỉ có loopback. ZIP chỉ đóng gói API_BASE_URL công khai.
- Production release dùng GitHub environment và kiểm tra run thuộc Admin CI, event push, branch main, commit trong lịch sử main, SHA nguồn và checksum ZIP. Pull request và artifact build từ nhánh tùy ý không được phát hành.
- Chạy pipeline thật cần push workflow lên GitHub; xác minh Windows build cần hosted runner/Visual Studio thực tế. Kết quả analyze/test local không thay thế lượt build trên GitHub.
- Chưa có ký Authenticode, installer hoặc auto-update. Muốn phân phối rộng cần thêm ký bằng certificate/hệ thống ký bảo vệ riêng, verify chữ ký rồi tạo ZIP/checksum sau khi ký; không đưa khóa ký vào PR workflow. Thêm updater là một tính năng ứng dụng riêng.
- Không hứa build bit-for-bit giống nhau: pin Flutter/dependency/action giúp tái lập đầu vào, nhưng Windows runner image vẫn có cập nhật. Manifest ghi nguồn và hash của đúng artifact phát hành.
- Public EC2 IP có thể đổi sau Stop/Start. Dùng tên miền API ổn định để không phải build admin vì IP đổi. Nếu đổi ADMIN_API_BASE_URL thì cần build ứng viên mới; app đã cài không tự nhận biến GitHub mới.
- GitHub-hosted Windows runner có quota/phí tùy repo và gói GitHub, độc lập credit AWS.
