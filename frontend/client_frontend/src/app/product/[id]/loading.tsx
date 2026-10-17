import Header from "@/components/Header";
import Footer from "@/components/Footer";
import ProductDetailSkeleton from "@/components/skeleton-ui/ProductDetailSkeleton";

export default function Loading() {
  return (
    <>
      <Header />
      <ProductDetailSkeleton />
      <Footer />
    </>
  );
}
