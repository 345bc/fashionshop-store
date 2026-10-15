import GoogleSymbol from "@/components/ui/GoogleSymbol";
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
      { label: "Tra cứu đơn hàng", href: "/order-tracking" },
      { label: "Tư vấn trực tuyến", href: "/support-chat" },
      { label: "Điểm thưởng", href: "/loyalty" },
      { label: "Đơn hàng của tôi", href: "/orders" },
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
              Khám phá Zella <span aria-hidden="true"><GoogleSymbol name="north_east" size={18} /></span>
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
                <GoogleSymbol name="call" size={17} />
              </span>
            </a>
            <p className={styles.hours}>Hỗ trợ mỗi ngày, 08:00 – 22:00</p>
            <a href="mailto:hello@zellastudio.vn" className={styles.email}>
              hello@zellastudio.vn <span aria-hidden="true"><GoogleSymbol name="north_east" size={18} /></span>
            </a>
          </div>
        </div>

        <div className={styles.bottom}>
          <p>© {new Date().getFullYear()} Zella Studio<span className={styles.copyrightNote}>. Thời trang cho nhịp sống hiện đại.</span></p>
          <div className={styles.social}>
            <span className={styles.socialLabel}>Kết nối cùng Zella</span>
            <a href="https://facebook.com/zellastudio" target="_blank" rel="noopener noreferrer" title="Facebook" aria-label="Facebook Zella Studio (mở tab mới)">
              <GoogleSymbol name="public" size={16} />
            </a>
            <a href="https://instagram.com/zellastudio" target="_blank" rel="noopener noreferrer" title="Instagram" aria-label="Instagram Zella Studio (mở tab mới)">
              <GoogleSymbol name="photo_camera" size={16} />
            </a>
            <a href="https://tiktok.com/@zellastudio" target="_blank" rel="noopener noreferrer" title="TikTok" aria-label="TikTok Zella Studio (mở tab mới)">
              <GoogleSymbol name="music_note" size={16} />
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
