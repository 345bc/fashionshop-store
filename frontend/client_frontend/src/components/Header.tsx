"use client";

import { FormEvent, useEffect, useRef, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useAuth } from "../auth/AuthContext";

type CatalogSection = "Nữ" | "Nam" | "Phụ kiện" | "Bộ sưu tập";

type CatalogItem = {
  label: string;
  href: string;
  image: string;
};

const catalog: Record<CatalogSection, CatalogItem[]> = {
  "Nữ": [
    { label: "Áo & sơ mi", href: "/products?cat=nu-ao", image: "/assets/images/images2.png" },
    { label: "Váy & đầm", href: "/products?cat=nu-vay", image: "/assets/images/v7_1916.png" },
    { label: "Quần", href: "/products?cat=nu-quan", image: "/assets/images/v7_1730.png" },
    { label: "Áo khoác", href: "/products?cat=nu-khoac", image: "/assets/images/v7_1951.png" },
    { label: "Áo dệt kim", href: "/products?cat=nu-knit", image: "/assets/images/v7_2123.png" },
    { label: "Chân váy", href: "/products?cat=nu-chan-vay", image: "/assets/images/v7_2019.png" },
    { label: "Đồ mặc nhà", href: "/products?cat=nu-mac-nha", image: "/assets/images/v7_3793.png" },
    { label: "Xem tất cả", href: "/products?cat=nu", image: "/assets/images/v7_3778.png" },
  ],
  "Nam": [
    { label: "Áo thun", href: "/products?cat=nam-ao-thun", image: "/assets/images/v7_3034.png" },
    { label: "Sơ mi", href: "/products?cat=nam-ao-somi", image: "/assets/images/v7_3025.png" },
    { label: "Quần dài", href: "/products?cat=nam-quan", image: "/assets/images/v7_1730.png" },
    { label: "Áo khoác", href: "/products?cat=nam-khoac", image: "/assets/images/v7_1713.png" },
    { label: "Dệt kim", href: "/products?cat=nam-det-kim", image: "/assets/images/v7_1909.png" },
    { label: "Đồ mặc nhà", href: "/products?cat=nam-mac-nha", image: "/assets/images/v7_2111.png" },
    { label: "Linen", href: "/products?cat=nam-linen", image: "/assets/images/v7_1930.png" },
    { label: "Xem tất cả", href: "/products?cat=nam", image: "/assets/images/v7_1717.png" },
  ],
  "Phụ kiện": [
    { label: "Túi", href: "/products?cat=phu-kien-tui", image: "/assets/images/v7_1944.png" },
    { label: "Khăn", href: "/products?cat=phu-kien-khan", image: "/assets/images/v7_3025.png" },
    { label: "Mũ", href: "/products?cat=phu-kien-mu", image: "/assets/images/v7_3034.png" },
    { label: "Thắt lưng", href: "/products?cat=phu-kien-that-lung", image: "/assets/images/v7_1730.png" },
    { label: "Trang sức", href: "/products?cat=phu-kien-trang-suc", image: "/assets/images/v7_1725.png" },
    { label: "Phụ kiện tóc", href: "/products?cat=phu-kien-toc", image: "/assets/images/v7_1909.png" },
    { label: "Quà tặng", href: "/products?cat=qua-tang", image: "/assets/images/v7_1754.png" },
    { label: "Xem tất cả", href: "/products?cat=phu-kien", image: "/assets/images/v7_1827.png" },
  ],
  "Bộ sưu tập": [
    { label: "Soft Tailoring", href: "/products?cat=soft-tailoring", image: "/assets/images/v7_1754.png" },
    { label: "Natural Linen", href: "/products?cat=linen", image: "/assets/images/v7_1758.png" },
    { label: "Sage Notes", href: "/products?cat=sage", image: "/assets/images/v7_1916.png" },
    { label: "Modern Balance", href: "/products?cat=modern-balance", image: "/assets/images/v7_1951.png" },
    { label: "Quiet Knit", href: "/products?cat=quiet-knit", image: "/assets/images/v7_3793.png" },
    { label: "Studio Essentials", href: "/products?cat=essentials", image: "/assets/images/v7_1725.png" },
    { label: "New arrivals", href: "/products?cat=new", image: "/assets/images/v7_1705.png" },
    { label: "Xem tất cả", href: "/products", image: "/assets/images/v7_1795.png" },
  ],
};

const sections = Object.keys(catalog) as CatalogSection[];

export default function Header() {
  const auth = useAuth();
  const pathname = usePathname();
  const router = useRouter();
  const [catalogOpen, setCatalogOpen] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [cartOpen, setCartOpen] = useState(false);
  const [cartQuantity, setCartQuantity] = useState(1);
  const [mobileProductsOpen, setMobileProductsOpen] = useState(false);
  const [activeSection, setActiveSection] = useState<CatalogSection>("Nữ");
  const [query, setQuery] = useState("");
  const searchRef = useRef<HTMLInputElement>(null);
  const mobileSearchRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setCatalogOpen(false);
        setMobileOpen(false);
        setCartOpen(false);
      }
    };

    document.addEventListener("keydown", closeOnEscape);
    return () => document.removeEventListener("keydown", closeOnEscape);
  }, []);

  const handleSearch = (event: FormEvent) => {
    event.preventDefault();
    const value = query.trim();
    router.push(value ? `/products?q=${encodeURIComponent(value)}` : "/products");
    setCatalogOpen(false);
    setMobileOpen(false);
  };

  const openSearch = () => {
    if (window.matchMedia("(min-width: 1024px)").matches) {
      setCatalogOpen(true);
      requestAnimationFrame(() => searchRef.current?.focus());
      return;
    }

    setMobileOpen(true);
    requestAnimationFrame(() => mobileSearchRef.current?.focus());
  };

  const closeNavigation = () => {
    setCatalogOpen(false);
    setMobileOpen(false);
  };

  const openCart = () => {
    setCatalogOpen(false);
    setMobileOpen(false);
    setCartOpen(true);
  };

  const cartSubtotal = 679000 * cartQuantity;

  return (
    <>
      <div className="flex h-9 items-center justify-center gap-4 bg-black px-4 text-[10px] font-bold tracking-[0.2em] text-white uppercase sm:text-[11px]">
        <span>Miễn phí giao hàng từ 1.500.000₫</span>
        <span aria-hidden="true" className="text-white/30">•</span>
        <span className="hidden sm:inline">Đổi trả trong 14 ngày</span>
      </div>

      <header className="sticky top-0 z-50 border-b border-black/10 bg-white shadow-lg">
        <div className="container mx-auto grid h-16 grid-cols-[44px_1fr_auto] items-center gap-2 px-3.5 lg:h-18 lg:grid-cols-[180px_1fr_180px] lg:gap-6 lg:px-8">
          <button
            type="button"
            className="grid size-10 place-items-center rounded-full text-black transition-colors hover:bg-black/5 lg:hidden"
            aria-label="Mở menu"
            aria-expanded={mobileOpen}
            onClick={() => setMobileOpen(true)}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 24 }}>menu</span>
          </button>

          <Link
            href="/"
            onClick={closeNavigation}
            className="justify-self-center whitespace-nowrap text-[18px] font-bold tracking-[0.25em] text-black lg:justify-self-start lg:text-[22px]"
            aria-label="Zella Studio - Trang chủ"
          >
            ZELLA<span className="ml-2 hidden align-middle text-[9px] font-medium tracking-[0.2em] text-black/60 lg:inline">STUDIO</span>
          </Link>

          <nav className="hidden h-full items-center justify-center gap-8 lg:flex" aria-label="Điều hướng chính">
            <Link href="/" onClick={closeNavigation} className={`relative flex h-full items-center text-[13.5px] font-bold uppercase tracking-[0.06em] transition-colors after:absolute after:bottom-0 after:left-0 after:h-0.5 after:bg-black after:transition-all ${pathname === "/" ? "text-black after:w-full" : "text-black/90 after:w-0 hover:text-black hover:after:w-full"}`}>
              Trang chủ
            </Link>
            <button
              type="button"
              className={`relative flex h-full items-center gap-1.5 border-0 bg-transparent text-[13.5px] font-bold uppercase tracking-[0.06em] transition-colors after:absolute after:bottom-0 after:left-0 after:h-0.5 after:bg-black after:transition-all ${catalogOpen ? "text-black after:w-full" : "text-black/90 after:w-0 hover:text-black hover:after:w-full"}`}
              aria-expanded={catalogOpen}
              aria-controls="catalog-menu"
              onClick={() => setCatalogOpen((open) => !open)}
            >
              Sản phẩm
              <span className={`material-symbols-outlined transition-transform duration-300 ${catalogOpen ? "rotate-180" : ""}`} style={{ fontSize: 16 }}>expand_more</span>
            </button>
            <Link href="/blog" onClick={closeNavigation} className="relative flex h-full items-center text-[13.5px] font-bold uppercase tracking-[0.06em] text-black/90 transition-colors after:absolute after:bottom-0 after:left-0 after:h-0.5 after:w-0 after:bg-black after:transition-all hover:text-black hover:after:w-full">Journal</Link>
          </nav>

          <div className="flex items-center justify-end gap-1.5">
            <button type="button" className="grid size-10 place-items-center rounded-full text-black transition-colors hover:bg-black/5" aria-label="Tìm kiếm" onClick={openSearch}>
              <span className="material-symbols-outlined" style={{ fontSize: 22 }}>search</span>
            </button>
            <div className="group relative hidden lg:block">
              <Link href="/profile" className="grid size-10 place-items-center rounded-full text-black transition-colors hover:bg-black/5" aria-label="Tài khoản">
                {auth.user && (auth.user.avatar || auth.user.picture || auth.user.photoUrl || auth.user.imageUrl) ? (
                  <Image unoptimized width={28} height={28} src={(auth.user.avatar || auth.user.picture || auth.user.photoUrl || auth.user.imageUrl) as string} alt="Avatar" className="size-7 rounded-full object-cover border border-black/10" />
                ) : auth.user ? (
                  <div className="flex size-7 items-center justify-center rounded-full bg-black text-[12px] font-bold text-white">
                    {(String(auth.user.username || auth.user.email || "U")).charAt(0).toUpperCase()}
                  </div>
                ) : (
                  <span className="material-symbols-outlined" style={{ fontSize: 22 }}>person</span>
                )}
              </Link>
              {/* Profile Dropdown */}
              <div className="invisible absolute left-0 top-full mt-2 w-48 origin-top-left rounded-xl border border-black/10 bg-white p-1.5 opacity-0 shadow-lg transition-all duration-200 group-hover:visible group-hover:translate-y-0 group-hover:opacity-100 translate-y-2">
                {auth.user ? (
                  <div className="flex flex-col">
                    <div className="mb-1.5 flex items-center gap-2 border-b border-black/10 px-2 pb-2 pt-1">
                      {auth.user.avatar || auth.user.picture || auth.user.photoUrl || auth.user.imageUrl ? (
                        <Image unoptimized width={28} height={28} src={(auth.user.avatar || auth.user.picture || auth.user.photoUrl || auth.user.imageUrl) as string} alt="Avatar" className="size-7 shrink-0 rounded-full object-cover border border-black/10" />
                      ) : (
                        <div className="flex size-7 shrink-0 items-center justify-center rounded-full bg-black text-[11px] font-bold text-white">
                          {(String(auth.user.profile?.fullname || auth.user.email || "U")).charAt(0).toUpperCase()}
                        </div>
                      )}
                      <div className="flex min-w-0 flex-col">
                        <span className="truncate text-[12px] font-semibold text-black">
                          {(auth.user.username as string) || (auth.user.email as string)?.split("@")[0] || "Người dùng"}
                        </span>
                      </div>
                    </div>
                    <div className="flex flex-col gap-0.5">
                      <Link href="/profile" className="flex items-center gap-2 rounded-lg px-2 py-1.5 text-[12px] font-medium text-black/80 transition-colors hover:bg-black/5 hover:text-black">
                        <span className="material-symbols-outlined text-[16px]">account_circle</span>
                        Hồ sơ
                      </Link>
                      <Link href="/orders" className="flex items-center gap-2 rounded-lg px-2 py-1.5 text-[12px] font-medium text-black/80 transition-colors hover:bg-black/5 hover:text-black">
                        <span className="material-symbols-outlined text-[16px]">local_mall</span>
                        Đơn hàng
                      </Link>
                      <Link href="/wishlist" className="flex items-center gap-2 rounded-lg px-2 py-1.5 text-[12px] font-medium text-black/80 transition-colors hover:bg-black/5 hover:text-black">
                        <span className="material-symbols-outlined text-[16px]">favorite</span>
                        Yêu thích
                      </Link>
                    </div>
                    <div className="mt-1.5 border-t border-black/10 pt-1.5">
                      <button type="button" onClick={() => auth.logout()} className="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-left text-[12px] font-medium text-red-600 transition-colors hover:bg-red-50">
                        <span className="material-symbols-outlined text-[16px]">logout</span>
                        Đăng xuất
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className="p-2 text-center">
                    <div className="mx-auto mb-2 flex size-8 items-center justify-center rounded-full bg-black/5 text-black">
                      <span className="material-symbols-outlined text-[16px]">loyalty</span>
                    </div>
                    <h4 className="mb-0.5 text-[12px] font-bold text-black">Zella Studio</h4>
                    <p className="mb-3 text-[11px] leading-relaxed text-black/60">Đăng nhập để nhận đặc quyền.</p>
                    <div className="flex flex-col gap-1.5">
                      <Link href="/login" className="flex w-full items-center justify-center rounded-lg bg-black px-3 py-2 text-[11px] font-bold text-white transition-colors hover:bg-black/80">
                        ĐĂNG NHẬP
                      </Link>
                      <Link href="/register" className="flex w-full items-center justify-center rounded-lg border border-black/20 bg-white px-3 py-2 text-[11px] font-bold text-black transition-colors hover:bg-black/5">
                        TẠO TÀI KHOẢN
                      </Link>
                    </div>
                  </div>
                )}
              </div>
            </div>
            <button type="button" onClick={openCart} className="relative grid size-10 place-items-center rounded-full border-0 bg-transparent text-black transition-colors hover:bg-black/5" aria-label="Mở giỏ hàng, 1 sản phẩm" aria-expanded={cartOpen}>
              <span className="material-symbols-outlined" style={{ fontSize: 22 }}>shopping_bag</span>
              <span className="absolute top-1.5 right-1.5 grid size-3.75 place-items-center rounded-full bg-black text-[8px] font-bold text-white shadow-sm">1</span>
            </button>
          </div>
        </div>

        <section
          id="catalog-menu"
          aria-label="Danh mục sản phẩm"
          aria-hidden={!catalogOpen}
          className={`absolute top-full left-1/2 w-full -translate-x-1/2 overflow-y-auto border-b border-black/10 bg-(--z-bg) shadow-[0_28px_60px_rgba(20,22,18,0.14)] transition-[opacity,transform,visibility] duration-200 ${catalogOpen ? "visible translate-y-0 opacity-100" : "invisible -translate-y-2 pointer-events-none opacity-0"}`}
        >
          <div className="container mx-auto max-h-[calc(100vh-100px)] overflow-y-auto px-8 pt-6 pb-7 xl:px-12">
            <div className="flex items-center justify-between border-b border-black/10">
              <div role="tablist" aria-label="Nhóm sản phẩm" className="flex items-center gap-7">
                {sections.map((section) => (
                  <button
                    type="button"
                    role="tab"
                    aria-selected={activeSection === section}
                    key={section}
                    className={`relative border-0 bg-transparent pb-4 text-[12px] font-semibold tracking-[0.08em] uppercase transition-colors after:absolute after:bottom-0 after:left-0 after:h-0.5 after:bg-[#1d211c] after:transition-all ${activeSection === section ? "text-[#1d211c] after:w-full" : "text-[#8a8d85] after:w-0 hover:text-[#1d211c]"}`}
                    onMouseEnter={() => setActiveSection(section)}
                    onFocus={() => setActiveSection(section)}
                    onClick={() => setActiveSection(section)}
                  >
                    {section}
                  </button>
                ))}
              </div>
              <button type="button" className="mb-3 grid size-9 place-items-center rounded-full text-[#555851] transition-colors hover:bg-black/5 hover:text-black" aria-label="Đóng danh mục" onClick={() => setCatalogOpen(false)}>
                <span className="material-symbols-outlined" style={{ fontSize: 19 }}>close</span>
              </button>
            </div>

            <form onSubmit={handleSearch} className="my-6 grid h-12 grid-cols-[22px_1fr_auto] items-center gap-3 rounded-full border border-black/15 bg-white px-5 transition-shadow focus-within:border-black/30 focus-within:shadow-[0_0_0_3px_rgba(29,33,28,0.05)]">
              <span className={`material-symbols-outlined ${"text-[#777a72]"}`} style={{ fontSize: 19 }}>search</span>
              <input
                ref={searchRef}
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                className="min-w-0 border-0 bg-transparent text-[14px] text-[#1d211c] outline-none placeholder:text-[#96988f]"
                placeholder="Tìm áo, váy, quần hoặc chất liệu..."
                aria-label="Từ khóa tìm kiếm"
              />
              <button type="submit" className="rounded-full bg-[#1d211c] px-4 py-2 text-[10px] font-semibold tracking-[0.08em] text-white uppercase transition-colors hover:bg-black">Tìm kiếm</button>
            </form>

            <div role="tabpanel" className="grid grid-cols-4 gap-x-4 gap-y-6 xl:grid-cols-8">
              {catalog[activeSection].map((item) => (
                <Link key={`${activeSection}-${item.label}`} href={item.href} onClick={closeNavigation} className="group min-w-0">
                  <div className="relative aspect-4/3 overflow-hidden rounded-[10px] bg-[#eeece6]">
                    <Image src={item.image} alt="" fill sizes="(max-width: 1280px) 25vw, 160px" className="object-cover transition-transform duration-500 ease-out group-hover:scale-[1.035]" />
                  </div>
                  <div className="mt-2.5 flex items-center justify-between gap-2">
                    <span className="truncate text-[12px] font-medium text-[#2b2e29] transition-colors group-hover:text-black">{item.label}</span>
                    <span aria-hidden="true" className="translate-x-0 text-[13px] text-[#9a9c95] transition-all group-hover:translate-x-0.5 group-hover:text-black">→</span>
                  </div>
                </Link>
              ))}
            </div>

            <div className="mt-6 flex items-center justify-between border-t border-black/10 pt-4 text-[10px] text-[#777a72]">
              <p>Thiết kế có chủ đích · Chất liệu được tuyển chọn</p>
              <div className="flex items-center gap-5 font-medium text-[#3d403a]">
                <Link href="/products?cat=new" onClick={closeNavigation} className="hover:text-black">Hàng mới về</Link>
                <Link href="/products" onClick={closeNavigation} className="hover:text-black">Tất cả sản phẩm →</Link>
              </div>
            </div>
          </div>
        </section>
      </header>

      {catalogOpen && (
        <button type="button" className="fixed inset-0 z-40 hidden cursor-default bg-[#171914]/25 backdrop-blur-[1px] lg:block" aria-label="Đóng danh mục sản phẩm" onClick={() => setCatalogOpen(false)} />
      )}

      <button
        type="button"
        aria-label="Đóng giỏ hàng"
        onClick={() => setCartOpen(false)}
        className={`fixed inset-0 z-60 cursor-default bg-black/60 transition-opacity duration-300 ${cartOpen ? "visible opacity-100" : "invisible pointer-events-none opacity-0"}`}
      />
      <aside
        role="dialog"
        aria-modal="true"
        aria-label="Giỏ hàng"
        aria-hidden={!cartOpen}
        className={`fixed top-0 right-0 bottom-0 z-70 flex w-full max-w-95 flex-col bg-white shadow-[-10px_0_40px_rgba(0,0,0,0.15)] transition-transform duration-400 ease-[cubic-bezier(0.16,1,0.3,1)] ${cartOpen ? "translate-x-0" : "translate-x-full"}`}
      >
        <div className="flex h-19 shrink-0 items-center justify-between border-b border-[#e5e5e5] px-6 sm:px-7">
          <div className="flex flex-col gap-0.5">
            <h2 className="text-[18px] font-bold tracking-[-0.03em] text-[#111]">Giỏ hàng</h2>
            <span className="text-[11px] font-medium text-[#777] uppercase tracking-wider">1 sản phẩm</span>
          </div>
          <button type="button" onClick={() => setCartOpen(false)} className="grid size-9 place-items-center rounded-full border border-[#e5e5e5] bg-transparent text-[#111] transition-colors hover:border-[#111] hover:bg-[#111] hover:text-white" aria-label="Đóng giỏ hàng">
            <span className="material-symbols-outlined" style={{ fontSize: 16 }}>close</span>
          </button>
        </div>

        <div className="flex flex-1 flex-col overflow-y-auto px-6 py-6 sm:px-7">
          <article className="grid w-full grid-cols-[88px_minmax(0,1fr)] gap-5 rounded-none border-b border-[#e5e5e5] pb-6">
            <Link href="/product/3" onClick={() => setCartOpen(false)} className="relative aspect-3/4 overflow-hidden rounded-md bg-[#f4f4f4]">
              <Image src="/assets/images/v7_2020.png" alt="Váy midi Sage Flow" fill sizes="88px" className="object-cover" />
            </Link>
            <div className="flex flex-col min-w-0 pt-1">
              <div className="flex justify-between items-start gap-2">
                <div className="pr-2">
                  <span className="text-[9px] font-bold tracking-[0.15em] text-[#888] uppercase">Dress</span>
                  <Link href="/product/3" onClick={() => setCartOpen(false)} className="mt-1 block text-[14px] font-bold leading-snug text-[#111] hover:underline">Váy midi Sage Flow</Link>
                </div>
                <strong className="text-[14px] font-bold text-[#111]">{cartSubtotal.toLocaleString("vi-VN")}₫</strong>
              </div>
              <span className="mt-1.5 block text-[11px] font-medium text-[#666]">Màu: Sage</span>
              <div className="mt-auto pt-3 flex flex-wrap items-center justify-between gap-3">
                <label className="flex items-center gap-1.5 text-[11px] font-medium text-[#666]">
                  Size:
                  <select defaultValue="M" className="border-0 bg-transparent font-bold text-[#111] outline-none cursor-pointer">
                    <option>S</option><option>M</option><option>L</option>
                  </select>
                </label>
                <div className="grid h-8 grid-cols-[26px_24px_26px] items-center rounded-sm border border-[#d5d5d5] bg-white" aria-label="Số lượng">
                  <button type="button" className="grid h-full place-items-center text-[#111] hover:bg-[#f5f5f5]" onClick={() => setCartQuantity((quantity) => Math.max(1, quantity - 1))} aria-label="Giảm số lượng"><span className="material-symbols-outlined" style={{ fontSize: 16 }}>remove</span></button>
                  <span className="text-center text-[11px] font-bold text-[#111]">{cartQuantity}</span>
                  <button type="button" className="grid h-full place-items-center text-[#111] hover:bg-[#f5f5f5]" onClick={() => setCartQuantity((quantity) => quantity + 1)} aria-label="Tăng số lượng"><span className="material-symbols-outlined" style={{ fontSize: 16 }}>add</span></button>
                </div>
              </div>
            </div>
          </article>
        </div>

        <div className="shrink-0 border-t border-[#eee] bg-[#fafafa] px-6 pt-6 pb-8 sm:px-7">
          <div className="flex items-end justify-between gap-5 mb-2">
            <span className="text-[13px] font-medium text-[#666]">Tổng cộng</span>
            <strong className="text-[22px] font-bold tracking-[-0.03em] text-[#111]">{cartSubtotal.toLocaleString("vi-VN")}₫</strong>
          </div>
          <p className="text-[11px] text-[#888] mb-6">Phí vận chuyển và thuế được tính ở bước thanh toán.</p>
          <Link href="/checkout" onClick={() => setCartOpen(false)} className="group relative flex h-13 w-full items-center justify-center overflow-hidden rounded-full bg-[#111] text-[13px] font-bold tracking-[0.04em] text-white transition-transform hover:scale-[1.02]">
            <span className="relative z-10">Thanh toán an toàn</span>
            <div className="absolute inset-0 -translate-x-full bg-white/20 transition-transform duration-400 ease-out group-hover:translate-x-0" />
          </Link>
        </div>
      </aside>

      <div className={`fixed inset-0 z-60 bg-[#171914]/35 transition-opacity duration-200 lg:hidden ${mobileOpen ? "visible opacity-100" : "invisible pointer-events-none opacity-0"}`} onClick={() => setMobileOpen(false)} />
      <aside className={`fixed top-0 bottom-0 left-0 z-70 w-[min(390px,90vw)] overflow-y-auto bg-(--z-bg) px-5 py-5 shadow-2xl transition-transform duration-300 ease-out lg:hidden ${mobileOpen ? "translate-x-0" : "-translate-x-full"}`} aria-hidden={!mobileOpen}>
        <div className="flex items-center justify-between border-b border-black/10 pb-4">
          <Link href="/" onClick={closeNavigation} className="text-[19px] font-bold tracking-[0.2em] text-[#1d211c]">ZELLA</Link>
          <button type="button" onClick={() => setMobileOpen(false)} className="grid size-9 place-items-center rounded-full bg-black/5" aria-label="Đóng menu"><span className="material-symbols-outlined" style={{ fontSize: 20 }}>close</span></button>
        </div>

        <form onSubmit={handleSearch} className="my-5 grid h-11 grid-cols-[20px_1fr] items-center gap-2 rounded-full border border-black/15 bg-white px-4">
          <span className={`material-symbols-outlined ${"text-[#777a72]"}`} style={{ fontSize: 17 }}>search</span>
          <input ref={mobileSearchRef} value={query} onChange={(event) => setQuery(event.target.value)} className="min-w-0 border-0 bg-transparent text-[13px] outline-none placeholder:text-[#9a9c95]" placeholder="Tìm kiếm sản phẩm" aria-label="Từ khóa tìm kiếm" />
        </form>

        <nav aria-label="Điều hướng di động" className="flex flex-col">
          <Link href="/" onClick={closeNavigation} className="border-b border-black/10 py-4 text-[14px] font-medium">Trang chủ</Link>
          <button type="button" className="flex items-center justify-between border-b border-black/10 bg-transparent py-4 text-left text-[14px] font-medium" aria-expanded={mobileProductsOpen} onClick={() => setMobileProductsOpen((open) => !open)}>
            Sản phẩm
            <span className={`material-symbols-outlined transition-transform ${mobileProductsOpen ? "rotate-180" : ""}`} style={{ fontSize: 16 }}>expand_more</span>
          </button>
          <div className={`grid overflow-hidden transition-[grid-template-rows] duration-200 ${mobileProductsOpen ? "grid-rows-[1fr]" : "grid-rows-[0fr]"}`}>
            <div className="min-h-0">
              <div className="grid grid-cols-2 gap-2 border-b border-black/10 py-3">
                {catalog["Nữ"].slice(0, 6).map((item) => (
                  <Link key={item.label} href={item.href} onClick={closeNavigation} className="rounded-lg px-3 py-2.5 text-[12px] text-[#555851] hover:bg-black/5 hover:text-black">{item.label}</Link>
                ))}
              </div>
            </div>
          </div>
          <Link href="/products?cat=nu" onClick={closeNavigation} className="border-b border-black/10 py-4 text-[14px] font-medium">Thời trang nữ</Link>
          <Link href="/products?cat=nam" onClick={closeNavigation} className="border-b border-black/10 py-4 text-[14px] font-medium">Thời trang nam</Link>
          <Link href="/blog" onClick={closeNavigation} className="border-b border-black/10 py-4 text-[14px] font-medium">Journal</Link>
          <Link href="/orders" onClick={closeNavigation} className="border-b border-black/10 py-4 text-[14px] font-medium">Theo dõi đơn hàng</Link>
          <Link href="/loyalty" onClick={closeNavigation} className="border-b border-black/10 py-4 text-[14px] font-medium">Điểm thưởng</Link>
        </nav>

        <div className="mt-6">
          <Link href="/profile" onClick={closeNavigation} className="flex items-center justify-center gap-2 rounded-full border border-black/15 bg-white px-3 py-3 text-[11px] font-medium"><span className="material-symbols-outlined" style={{ fontSize: 16 }}>person</span> Tài khoản</Link>
        </div>
      </aside>
    </>
  );
}
