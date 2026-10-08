import Header from "@/components/Header";
import Footer from "@/components/Footer";
import ProductCatalog from "@/components/ProductCatalog";

export default async function ProductsPage({ searchParams }: { searchParams: Promise<{ q?: string; cat?: string; categoryName?: string }> }) {
  const params = await searchParams;
  return (
    <>
      <Header />
      <main className="main-content modern-main container mx-auto py-18">
        <ProductCatalog
          key={`${params.q ?? ""}-${params.cat ?? ""}`}
          initialQuery={params.q ?? ""}
          initialCategory={params.cat ?? ""}
          initialCategoryName={params.categoryName ?? ""}
        />
      </main>
      <Footer />
    </>
  );
}
