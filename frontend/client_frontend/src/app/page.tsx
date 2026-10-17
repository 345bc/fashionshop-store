import GoogleSymbol from "@/components/ui/GoogleSymbol";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import FeaturedProducts from "@/components/FeaturedProducts";
import HomeJournal from "@/components/HomeJournal";
import CampaignDisplays from "@/components/CampaignDisplays";
import Link from "next/link";

export default function Home() {
  return (
    <>
      <Header />
      <main className="home-redesign">
        <div className="modern-container">
          <section className="modern-hero" style={{ height: "calc(100vh - 100px)", minHeight: "unset" }}>
            <div className="modern-hero-copy">
              <span className="eyebrow">AUTUMN / 2026</span>
              <h1>Quiet forms.<br />Strong presence.</h1>
              <p>Một tủ đồ hiện đại không cần quá nhiều. Chỉ cần phom dáng đẹp, màu sắc dễ phối và những món bạn muốn mặc lại nhiều lần.</p>
              <div className="hero-notes">
                <span>01 / Natural palette</span><span>02 / Easy tailoring</span><span>03 / Everyday pieces</span>
              </div>
            </div>
            <div className="modern-hero-visual">
              <video autoPlay muted loop playsInline preload="metadata" poster="/assets/images/v7_1705.png" aria-label="Zella Autumn 2026 fashion film">
                <source src="/assets/videos/zella-hero-main.mp4" type="video/mp4" />
              </video>
              <div className="hero-floating-card">
                <span>THE NEW EDIT</span>
                <strong>Warm neutrals</strong>
                <Link href="/products">Shop now <GoogleSymbol name="arrow_forward" size={16} /></Link>
              </div>
            </div>
          </section>


        </div>

        <FeaturedProducts />

        <CampaignDisplays />


        <HomeJournal />
      </main>
      <Footer />
    </>
  );
}

