"use client";

import Link from "next/link";
import styles from "./Footer.module.css";

export default function Footer() {
  return (
    <footer className={styles.footer} aria-label="Thông tin Zella">
      <div className={`container mx-auto ${styles.container}`}>
        <div className={styles.grid}>
          {/* CỘT 1: THƯƠNG HIỆU, MẠNG XÃ HỘI & THÔNG TIN DOANH NGHIỆP */}
          <div className={styles.colBrand}>
            <Link href="/" className={styles.logo} aria-label="Zella - Trang chủ">
              <span className="font-extrabold tracking-[0.25em] text-[26px]">ZELLA</span>
            </Link>

            {/* Dòng biểu tượng mạng xã hội */}
            <div className={styles.badgeRow}>
              <div className={styles.socialIcons}>
                {/* Facebook */}
                <a
                  href="https://facebook.com"
                  target="_blank"
                  rel="noopener noreferrer"
                  className={styles.socialIcon}
                  aria-label="Facebook Zella"
                >
                  <svg width="19" height="19" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
                  </svg>
                </a>

                {/* Instagram */}
                <a
                  href="https://instagram.com"
                  target="_blank"
                  rel="noopener noreferrer"
                  className={styles.socialIcon}
                  aria-label="Instagram Zella"
                >
                  <svg
                    width="19"
                    height="19"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <rect x="2" y="2" width="20" height="20" rx="5" ry="5" />
                    <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z" />
                    <line x1="17.5" y1="6.5" x2="17.51" y2="6.5" />
                  </svg>
                </a>

                {/* TikTok */}
                <a
                  href="https://tiktok.com"
                  target="_blank"
                  rel="noopener noreferrer"
                  className={styles.socialIcon}
                  aria-label="TikTok Zella"
                >
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M19.59 6.69a4.83 4.83 0 0 1-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 0 1-5.2 1.74 2.89 2.89 0 0 1 2.31-4.64 2.93 2.93 0 0 1 .88.13V9.4a6.84 6.84 0 0 0-1-.05A6.33 6.33 0 0 0 3 15.68a6.34 6.34 0 0 0 10.82 4.47 6.27 6.27 0 0 0 1.88-4.48V8.3a8.16 8.16 0 0 0 4.89 1.63V6.69h-1z" />
                  </svg>
                </a>

                {/* Zalo */}
                <a
                  href="https://zalo.me"
                  target="_blank"
                  rel="noopener noreferrer"
                  className={styles.socialIcon}
                  aria-label="Zalo Zella"
                >
                  <span className={styles.zaloBadge}>Zalo</span>
                </a>
              </div>
            </div>

            {/* Thông tin thương hiệu & cam kết */}
            <div className={styles.companyInfo}>
              <p className={styles.brandSubtitle}>Thương hiệu thời trang ZELLA</p>
              <p className={styles.companyName}>
                CÔNG TY CỔ PHẦN SẢN XUẤT THƯƠNG MẠI ZELLA VIỆT NAM
              </p>
              <p className={styles.companyLegal}>
                GPKD số 0318076956 cấp ngày 03/10/2023 tại Sở Kế hoạch và Đầu tư Thành phố Hồ Chí
                Minh.
              </p>
              <p className={styles.companyAddress}>Địa chỉ trụ sở: C7/30QR3, Ấp 41, Xã Bình Hưng, TP. HCM</p>
              <p className={styles.note}>
                Miễn phí giao hàng từ 600.000đ • Đổi trả trong 14 ngày.
              </p>
            </div>
          </div>

          {/* CỘT 2: KHÁM PHÁ & SẢN PHẨM (CÁC CHỨC NĂNG CÓ SẴN TRONG HỆ THỐNG) */}
          <div>
            <h3 className={styles.colTitle}>Khám phá</h3>
            <ul className={styles.linkList}>
              <li>
                <Link href="/products" className={styles.linkItem}>
                  Tất cả sản phẩm
                </Link>
              </li>
              <li>
                <Link href="/products?cat=nu" className={styles.linkItem}>
                  Thời trang nữ
                </Link>
              </li>
              <li>
                <Link href="/products?cat=nam" className={styles.linkItem}>
                  Thời trang nam
                </Link>
              </li>
              <li>
                <Link href="/products?cat=tre-em" className={styles.linkItem}>
                  Thời trang trẻ em
                </Link>
              </li>
              <li>
                <Link href="/blog" className={styles.linkItem}>
                  Bài viết & Cảm hứng
                </Link>
              </li>
              <li>
                <Link href="/loyalty" className={styles.linkItem}>
                  Điểm thưởng Zella
                </Link>
              </li>
            </ul>
          </div>

          {/* CỘT 3: HỖ TRỢ KHÁCH HÀNG (CÁC CHỨC NĂNG CÓ SẴN TRONG HỆ THỐNG) */}
          <div>
            <h3 className={styles.colTitle}>Hỗ trợ khách hàng</h3>
            <ul className={styles.linkList}>
              <li>
                <Link href="/order-tracking" className={styles.linkItem}>
                  Tra cứu đơn hàng
                </Link>
              </li>
              <li>
                <Link href="/support-chat" className={styles.linkItem}>
                  Tư vấn trực tuyến
                </Link>
              </li>
              <li>
                <Link href="/orders" className={styles.linkItem}>
                  Đơn hàng của tôi
                </Link>
              </li>
              <li>
                <Link href="/purchase-history" className={styles.linkItem}>
                  Lịch sử mua hàng
                </Link>
              </li>
              <li>
                <Link href="/profile" className={styles.linkItem}>
                  Hồ sơ tài khoản
                </Link>
              </li>
              <li>
                <Link href="/register" className={styles.linkItem}>
                  Đăng ký thành viên
                </Link>
              </li>
            </ul>
          </div>

          {/* CỘT 4: LIÊN LẠC (THÔNG TIN LIÊN HỆ THỰC TẾ) */}
          <div>
            <h3 className={styles.colTitle}>Liên lạc</h3>
            <div className={styles.contactBlock}>
              <div className={styles.contactItem}>
                <span className={styles.contactLabel}>Đặt hàng trực tuyến (8h-21h)</span>
                <a href="tel:19006868" className={styles.hotline}>
                  1900 6868
                </a>
              </div>

              <div className={styles.contactItem}>
                <span className={styles.contactLabel}>Chăm sóc & Tư vấn</span>
                <a href="tel:02877708668" className={styles.hotline}>
                  028 77708668
                </a>
              </div>

              <div className={styles.contactItem}>
                <span className={styles.contactLabel}>Email hỗ trợ</span>
                <a href="mailto:hello@zellastudio.vn" className={styles.email}>
                  hello@zellastudio.vn
                </a>
              </div>
            </div>
          </div>
        </div>

      </div>
    </footer>
  );
}
