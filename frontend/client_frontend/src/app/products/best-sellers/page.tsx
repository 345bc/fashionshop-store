import Header from "@/components/Header";
import Footer from "@/components/Footer";
import HomeProductShowcase from "@/components/HomeProductShowcase";

export default function BestSellersPage() {
  return (
    <>
      <Header />
      <main className="main-content modern-main">
        <HomeProductShowcase listing />
      </main>
      <Footer />
    </>
  );
}
