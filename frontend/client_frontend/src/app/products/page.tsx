import { redirect } from "next/navigation";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import ProductCatalog from "@/components/ProductCatalog";

export default async function ProductsPage({ searchParams }: { searchParams: Promise<{ q?: string | string[]; cat?: string | string[]; categoryName?: string | string[]; new?: string | string[] }> }) {
  const params = await searchParams;
  if (Object.values(params).some(value => Array.isArray(value))) redirect("/");
  const query = typeof params.q === "string" ? params.q.trim() : "";
  const category = typeof params.cat === "string" ? params.cat : "";
  const categoryName = typeof params.categoryName === "string" ? params.categoryName : "";
  if (params.cat !== undefined && (!/^[1-9]\d*$/.test(category) || !Number.isSafeInteger(Number(category)))) redirect("/");
  if (params.new !== undefined) redirect("/");
  if (!category && !query) redirect("/");
  return (
    <>
      <Header />
      <main className="main-content modern-main container mx-auto py-18">
        <ProductCatalog
          key={`${query}-${category}`}
          initialQuery={query}
          initialCategory={category}
          initialCategoryName={categoryName}
        />
      </main>
      <Footer />
    </>
  );
}
