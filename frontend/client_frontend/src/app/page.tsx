import Header from "@/components/Header";
import Footer from "@/components/Footer";
import FeaturedProducts from "@/components/FeaturedProducts";
import HomeJournal from "@/components/HomeJournal";
import CampaignDisplays from "@/components/CampaignDisplays";

export default function Home() {
  return (
    <>
      <Header />
      <main className="home-redesign">
        <div className="modern-container">
          <section className="modern-hero" style={{ position: "relative", height: "calc(100svh - 100px)", minHeight: "unset" }}>
            <video
              src="/assets/videos/Thời Trang Nam The New ZARA Việt Nam.mp4"
              poster="/assets/images/image-landscape-1-fill-eda2b26b-395d-437e-a152-850b26c484a8-default_0.jpg"
              autoPlay
              muted
              loop
              playsInline
              controls
              preload="metadata"
              aria-label="Video thời trang nam The New"
              style={{ position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover", objectPosition: "center" }}
            />
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

