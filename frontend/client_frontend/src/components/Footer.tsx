import Link from "next/link";

export default function Footer() {
  return (
    <footer className="site-footer modern-footer">
      <div className="footer-inner modern-footer-grid">
        <div className="footer-brand">
          <div className="footer-logo">ZELLA</div>
          <p>Thời trang tối giản cho nhịp sống hiện đại — dễ mặc, dễ phối và có chủ đích.</p>
          <a href="mailto:hello@zellastudio.vn" className="footer-email-link">
            <span className="footer-email-icon"><span className="material-symbols-outlined" style={{ fontSize: 17 }}>mail</span></span>
            <span><small>Email hỗ trợ</small><strong>hello@zellastudio.vn</strong></span>
          </a>
          <div className="footer-social">
            <span>Kết nối với Zella</span>
            <div className="footer-social-links">
              <a href="https://facebook.com/zellastudio" target="_blank" rel="noreferrer" aria-label="Facebook Zella Studio">
                <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M14.2 8.2H17V4.3c-.5-.1-2.1-.3-4-.3-3.9 0-6.6 2.4-6.6 6.8v3.8H2v4.4h4.4v11h5.4V19h4.5l.7-4.4h-5.2v-3.4c0-1.3.4-3 2.4-3Z" transform="scale(.75) translate(4 -2)" /></svg>
              </a>
              <a href="https://instagram.com/zellastudio" target="_blank" rel="noreferrer" aria-label="Instagram Zella Studio">
                <svg viewBox="0 0 24 24" aria-hidden="true"><rect x="3.5" y="3.5" width="17" height="17" rx="5" /><circle cx="12" cy="12" r="4" /><circle cx="17.4" cy="6.7" r="1" className="fill-current stroke-none" /></svg>
              </a>
              <a href="https://tiktok.com/@zellastudio" target="_blank" rel="noreferrer" aria-label="TikTok Zella Studio">
                <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M14.5 4v10.2a4.5 4.5 0 1 1-3.8-4.4v3.1a1.6 1.6 0 1 0 .9 1.4V4h2.9Zm0 0c.4 2.4 1.8 3.8 4.1 4.2" /></svg>
              </a>
            </div>
          </div>
        </div>
        <div className="footer-col">
          <h4>Mua sắm</h4>
          <ul className="footer-links">
            <li><Link href="/products">Sản phẩm mới</Link></li>
            <li><Link href="/products?cat=nu">Nữ</Link></li>
            <li><Link href="/products?cat=nam">Nam</Link></li>
            <li><Link href="/blog">Journal</Link></li>
          </ul>
        </div>
        <div className="footer-col">
          <h4>Hỗ trợ</h4>
          <ul className="footer-links">
            <li><Link href="/orders">Theo dõi đơn hàng</Link></li>
            <li><Link href="/support-chat">Tư vấn trực tuyến</Link></li>
            <li><Link href="/loyalty">Điểm thưởng</Link></li>
            <li><Link href="/purchase-history">Lịch sử mua</Link></li>
          </ul>
        </div>
        <div className="footer-col">
          <h4>Tài khoản</h4>
          <ul className="footer-links">
            <li><Link href="/login">Đăng nhập</Link></li>
            <li><Link href="/register">Đăng ký</Link></li>
            <li><Link href="/profile">Hồ sơ cá nhân</Link></li>
            <li><Link href="/checkout">Thanh toán</Link></li>
          </ul>
        </div>
      </div>
      <div className="footer-bottom modern-footer-bottom">
        <span>© 2026 Zella Studio</span>
        <span>Hotline 1900 6868 · 08:00–22:00</span>
      </div>
    </footer>
  );
}
