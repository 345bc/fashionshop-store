import Header from "@/components/Header";
import Footer from "@/components/Footer";
import ProductCatalog from "@/components/ProductCatalog";
import Link from "next/link";

export default async function ProductsPage({ searchParams }: { searchParams: Promise<{ q?: string; cat?: string }> }) {
  const params = await searchParams;
  return (
    <>
      <Header />
      <main className="main-content modern-main">
        <div className="breadcrumb modern-breadcrumb">
          <Link href="/">Trang chủ</Link><span>/</span><span>Sản phẩm</span>
        </div>
        <ProductCatalog initialQuery={params.q ?? ""} initialCategory={params.cat ?? ""} />
      </main>
      <Footer />
    </>
  );
}
