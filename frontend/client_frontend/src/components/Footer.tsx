import Link from "next/link";
import styles from "./Footer.module.css";

const linkGroups = [
  {
    title: "Khám phá",
    links: [
      { label: "Tất cả sản phẩm", href: "/products" },
      { label: "Journal & cảm hứng", href: "/blog" },
    ],
  },
  {
    title: "Chăm sóc khách hàng",
    links: [
      { label: "Theo dõi đơn hàng", href: "/orders" },
      { label: "Tư vấn trực tuyến", href: "/support-chat" },
      { label: "Điểm thưởng", href: "/loyalty" },
      { label: "Lịch sử mua hàng", href: "/purchase-history" },
    ],
  },
  {
    title: "Tài khoản",
    links: [
      { label: "Đăng nhập", href: "/login" },
      { label: "Đăng ký", href: "/register" },
      { label: "Hồ sơ cá nhân", href: "/profile" },
    ],
  },
];

export default function Footer() {
  return (
    <footer className={styles.footer} aria-label="Thông tin Zella Studio">
      <div className={styles.container}>
        <div className={styles.heading}>
          <div>
            <Link href="/" className={styles.logo} aria-label="Zella Studio - Trang chủ">
              ZELLA<span className={styles.logoDot}>.</span>
            </Link>
            <p className={styles.signature}>STUDIO / EVERYDAY ESSENTIALS</p>
          </div>
          <div className={styles.intro}>
            <p>Đơn giản trong lựa chọn.<br /><strong>Tinh tế trong từng ngày.</strong></p>
            <Link href="/products" className={styles.explore}>
              Khám phá Zella <span aria-hidden="true">↗</span>
            </Link>
          </div>
        </div>

        <div className={styles.main}>
          <nav className={styles.navigation} aria-label="Liên kết cuối trang">
            {linkGroups.map((group) => (
              <div className={styles.linkGroup} key={group.title}>
                <h2>{group.title}</h2>
                <ul>
                  {group.links.map((link) => (
                    <li key={link.href}><Link href={link.href}>{link.label}</Link></li>
                  ))}
                </ul>
              </div>
            ))}
          </nav>

          <div className={styles.contact}>
            <span className={styles.eyebrow}>LUÔN SẴN SÀNG LẮNG NGHE</span>
            <a href="tel:19006868" className={styles.phone}>
              1900 6868
              <span className={styles.phoneIcon} aria-hidden="true">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                  <path d="M8 3H5a2 2 0 0 0-2 2c0 8.8 7.2 16 16 16a2 2 0 0 0 2-2v-3l-5-2-2 2a13 13 0 0 1-6-6l2-2-2-5Z" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </span>
            </a>
            <p className={styles.hours}>Hỗ trợ mỗi ngày, 08:00 – 22:00</p>
            <a href="mailto:hello@zellastudio.vn" className={styles.email}>
              hello@zellastudio.vn <span aria-hidden="true">↗</span>
            </a>
          </div>
        </div>

        <div className={styles.bottom}>
          <p>© {new Date().getFullYear()} Zella Studio<span className={styles.copyrightNote}>. Thời trang cho nhịp sống hiện đại.</span></p>
          <div className={styles.social}>
            <span className={styles.socialLabel}>Kết nối cùng Zella</span>
            <a href="https://facebook.com/zellastudio" target="_blank" rel="noopener noreferrer" aria-label="Facebook Zella Studio (mở tab mới)">
              <svg viewBox="0 0 24 24" aria-hidden="true" fill="currentColor">
                <path d="M13.5 21v-8h2.7l.4-3h-3.1V8.1c0-.9.3-1.5 1.6-1.5H17V3.9c-.3 0-1.4-.1-2.5-.1-2.5 0-4.2 1.5-4.2 4.3V10H7.5v3h2.8v8h3.2Z" />
              </svg>
            </a>
            <a href="https://instagram.com/zellastudio" target="_blank" rel="noopener noreferrer" aria-label="Instagram Zella Studio (mở tab mới)">
              <svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="1.6">
                <rect x="3.5" y="3.5" width="17" height="17" rx="5" /><circle cx="12" cy="12" r="4" />
                <circle cx="17.4" cy="6.7" r="1" fill="currentColor" stroke="none" />
              </svg>
            </a>
            <a href="https://tiktok.com/@zellastudio" target="_blank" rel="noopener noreferrer" aria-label="TikTok Zella Studio (mở tab mới)">
              <svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <path d="M14 3v12a4 4 0 1 1-4-4M14 3c.5 3 2.5 5 6 5" />
              </svg>
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
