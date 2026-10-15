import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Link from "next/link";
import Image from "next/image";

export default function ArticleDetailPage() {
  return (
    <>
      <Header />
      <main className="main-content" style={{ minHeight: "80vh", paddingBottom: "80px" }}>
        
        <div className="breadcrumb">
          <Link href="/">Trang chủ</Link>
          <span className="divider">/</span>
          <Link href="/blog">Zella Post</Link>
          <span className="divider">/</span>
          <span className="current">Phong cách</span>
        </div>

        {/* Cover Image & Header - Elegant full-width container */}
        <section style={{ maxWidth: "1280px", margin: "0 auto", padding: "40px 0", textAlign: "center" }}>

          <h1 style={{ 
            fontSize: "clamp(2rem, 4vw, 3.2rem)", 
            fontWeight: 400, 
            lineHeight: 1.2, 
            color: "var(--ink-primary)", 
            maxWidth: "800px", 
            margin: "0 auto 24px",
            fontFamily: "var(--font-sans)",
            letterSpacing: "-0.01em"
          }}>
            Linen - Hơi thở của tự nhiên trong thời trang đương đại
          </h1>

          <div style={{ 
            display: "flex", 
            alignItems: "center", 
            justifyContent: "center", 
            gap: "16px", 
            color: "var(--ink-secondary)", 
            fontSize: "0.9rem",
            textTransform: "uppercase",
            letterSpacing: "0.5px"
          }}>
            <span>By Zella Team</span>
            <span>—</span>
            <span>12 Tháng 9, 2026</span>
            <span>—</span>
            <span>5 phút đọc</span>
          </div>
          
        </section>

        {/* Big Cover Image */}
        <div style={{ maxWidth: "1280px", margin: "0 auto 64px", padding: "0 24px" }}>
          <div style={{ borderRadius: "4px", overflow: "hidden", aspectRatio: "21/9", position: "relative" }}>
             <Image 
               src="https://images.unsplash.com/photo-1515347619252-8bbfa678d407?w=1600&q=80" 
               alt="Linen - Hơi thở của tự nhiên" 
               fill
               style={{ objectFit: "cover" }} 
               priority
             />
          </div>
        </div>

        {/* Article Body - Full width container */}
        <article style={{ maxWidth: "1280px", margin: "0 auto", padding: "0 24px", color: "var(--ink-primary)", fontSize: "1.1rem", lineHeight: 1.8 }}>
          
          <p style={{ marginBottom: "24px", fontSize: "1.2rem", color: "var(--ink-secondary)" }}>
            Giữa nhịp sống hối hả, con người ngày càng có xu hướng tìm về những gì mộc mạc và nguyên bản nhất. Trong thời trang, Linen (vải lanh) chính là đại diện tiêu biểu cho tinh thần &quot;back to nature&quot; ấy – một chất liệu thô mộc nhưng chứa đựng sự thanh lịch vượt thời gian.
          </p>

          <h2 style={{ fontSize: "1.8rem", fontWeight: 500, margin: "48px 0 24px", fontFamily: "var(--font-sans)", letterSpacing: "-0.01em" }}>
            Chất liệu mang dòng chảy thời gian
          </h2>
          <p style={{ marginBottom: "24px" }}>
            Linen là một trong những loại vải lâu đời nhất trên thế giới, được dệt từ sợi của thân cây lanh. Phải mất rất nhiều công sức và thời gian để thu hoạch, xử lý, kéo sợi và dệt nên những thước vải Linen. Chính quy trình thủ công tỉ mỉ này khiến Linen mang trong mình vẻ đẹp của sự nguyên bản.
          </p>
          <p style={{ marginBottom: "24px" }}>
            Không phẳng phiu hoàn hảo như vải nhân tạo, Linen sở hữu bề mặt thô mộc đặc trưng. Từng sợi vải không đồng đều tạo nên một kết cấu tự nhiên, mang lại cảm giác dễ chịu và gần gũi vô cùng khi chạm vào.
          </p>

          {/* Elegant Quote Block */}
          <div style={{ 
            margin: "56px 0", 
            padding: "40px 0", 
            borderTop: "1px solid var(--border-light)", 
            borderBottom: "1px solid var(--border-light)",
            textAlign: "center" 
          }}>
            <p style={{ 
              fontSize: "1.5rem", 
              fontStyle: "italic", 
              fontWeight: 300, 
              color: "var(--ink-primary)", 
              lineHeight: 1.5,
              margin: 0
            }}>
              &quot;Mặc Linen không chỉ là khoác lên mình một bộ trang phục, mà là đang ôm vào lòng hơi thở của tự nhiên, của sự tự do và thanh thản.&quot;
            </p>
          </div>

          <h2 style={{ fontSize: "1.8rem", fontWeight: 500, margin: "48px 0 24px", fontFamily: "var(--font-sans)", letterSpacing: "-0.01em" }}>
            Đặc tính vượt trội của Linen
          </h2>
          <p style={{ marginBottom: "24px" }}>
            Vượt xa vẻ đẹp bên ngoài, Linen thực sự chinh phục người mặc bởi những đặc tính ưu việt:
          </p>
          <ul style={{ paddingLeft: "24px", marginBottom: "32px", color: "var(--ink-primary)" }}>
            <li style={{ marginBottom: "16px", paddingLeft: "8px" }}>
              <strong style={{ fontWeight: 500 }}>Thoáng mát tuyệt đối:</strong> Kết cấu sợi thưa giúp Linen thấm hút mồ hôi nhanh và bay hơi cũng rất nhanh, lý tưởng cho những ngày hè rực nắng.
            </li>
            <li style={{ marginBottom: "16px", paddingLeft: "8px" }}>
              <strong style={{ fontWeight: 500 }}>Bền bỉ với thời gian:</strong> Khác với nhiều loại vải dễ bị sờn cũ, Linen càng giặt lại càng trở nên mềm mại và bền chắc hơn.
            </li>
            <li style={{ marginBottom: "16px", paddingLeft: "8px" }}>
              <strong style={{ fontWeight: 500 }}>Thân thiện với môi trường:</strong> Việc trồng cây lanh cần rất ít nước và hoàn toàn không sử dụng hóa chất độc hại. Vải Linen cũng có khả năng phân hủy sinh học 100%.
            </li>
          </ul>

          <div style={{ marginBottom: "48px", borderRadius: "4px", overflow: "hidden" }}>
             <Image 
               src="https://images.unsplash.com/photo-1596755094514-f87e32f85e23?w=800&q=80" 
               alt="Áo sơ mi Linen" 
               width={800} 
               height={500} 
               style={{ width: "100%", height: "auto", objectFit: "cover" }} 
             />
             <p style={{ textAlign: "center", fontSize: "0.85rem", color: "var(--ink-secondary)", marginTop: "12px", fontStyle: "italic" }}>
               Thiết kế sơ mi Linen với phom dáng suông rộng, thoải mái.
             </p>
          </div>

          <h2 style={{ fontSize: "1.8rem", fontWeight: 500, margin: "48px 0 24px", fontFamily: "var(--font-sans)", letterSpacing: "-0.01em" }}>
            Nét quyến rũ từ những nếp nhăn
          </h2>
          <p style={{ marginBottom: "24px" }}>
            Nhiều người e ngại Linen vì chúng dễ nhăn. Nhưng với những ai đã phải lòng chất liệu này, nếp nhăn tự nhiên ấy lại chính là nét duyên ngầm, là dấu ấn cá nhân của người mặc. Nó phản ánh sự chuyển động chân thực, sự tự do không bị gò bó bởi những khuôn mẫu cứng nhắc.
          </p>
          <p style={{ marginBottom: "48px" }}>
            Tại Zella, chúng tôi trân trọng vẻ đẹp nguyên sơ đó. Bộ sưu tập Linen mới nhất được thiết kế với những đường cắt tối giản, tôn lên chất liệu và mang lại cho bạn một phong thái thanh lịch, hiện đại nhưng vẫn đầy thư thái.
          </p>

          {/* Social Share or Tags */}
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", borderTop: "1px solid var(--border-light)", paddingTop: "24px", marginTop: "48px" }}>
            <div style={{ display: "flex", gap: "8px" }}>
              <span style={{ padding: "6px 12px", background: "var(--bg-subtle)", borderRadius: "99px", fontSize: "0.85rem", color: "var(--ink-secondary)" }}>#Linen</span>
              <span style={{ padding: "6px 12px", background: "var(--bg-subtle)", borderRadius: "99px", fontSize: "0.85rem", color: "var(--ink-secondary)" }}>#ThoiTrangBenVung</span>
              <span style={{ padding: "6px 12px", background: "var(--bg-subtle)", borderRadius: "99px", fontSize: "0.85rem", color: "var(--ink-secondary)" }}>#Minimalism</span>
            </div>
          </div>

        </article>
      </main>
      <Footer />
    </>
  );
}
