"use client";
import GoogleSymbol from "@/components/ui/GoogleSymbol";
import mobileStyles from "./HeaderMobile.module.css";
import catalogStyles from "./HeaderCatalog.module.css";


import { FormEvent, useEffect, useRef, useState } from "react";
import { flushSync } from "react-dom";
import Image from "next/image";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useAuth } from "../auth/AuthContext";
import { useCart } from "../cart/CartContext";
import { getCategories, getCategoriesParent } from "../service/categoriesApi";


interface category {
  id: number,
  name: string,
  slug: string,
  imageUrl: string
}

function MobileCategoryGroup({ parent, onNavigate }: { parent: category; onNavigate: () => void }) {
  const [expanded, setExpanded] = useState(false);
  const [result, setResult] = useState<{ items: category[]; error: boolean } | null>(null);

  useEffect(() => {
    if (!expanded || result) return;
    let disposed = false;
    getCategories(parent.id)
      .then(response => {
        if (!disposed) setResult({ items: Array.isArray(response?.data) ? response.data : [], error: false });
      })
      .catch(() => {
        if (!disposed) setResult({ items: [], error: true });
      });
    return () => { disposed = true; };
  }, [expanded, parent.id, result]);

  return <div>
    <button type="button" className={mobileStyles.categoryToggle}
      aria-expanded={expanded} aria-controls={`mobile-category-${parent.id}`}
      onClick={() => setExpanded(value => !value)}>
      {parent.name}
      <GoogleSymbol name={expanded ? "expand_less" : "expand_more"} size={18} />
    </button>
    {expanded && <div id={`mobile-category-${parent.id}`} className={mobileStyles.children}>
      {!result ? <p role="status">Đang tải danh mục...</p>
        : result.error ? <div role="alert"><p>Không tải được danh mục.</p><button type="button" onClick={() => setResult(null)}>Thử lại</button></div>
          : result.items.length === 0 ? <p>Chưa có danh mục con.</p>
            : result.items.map(item => <Link key={item.id}
              href={`/products?cat=${item.id}&categoryName=${encodeURIComponent(item.name)}`}
              onClick={onNavigate}>{item.name}</Link>)}
    </div>}
  </div>;
}

export default function Header() {
  const auth = useAuth();
  const pathname = usePathname();
  const router = useRouter();
  const [catalogOpen, setCatalogOpen] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [accountOpen, setAccountOpen] = useState(false);
  const accountRef = useRef<HTMLDivElement>(null);
  const cart = useCart();
  const [mobileProductsOpen, setMobileProductsOpen] = useState(false);
  const [activeSection, setActiveSection] = useState<number | null>(null);
  const [query, setQuery] = useState("");
  const searchRef = useRef<HTMLInputElement>(null);
  const mobileSearchRef = useRef<HTMLInputElement>(null);
  const mobileMenuRef = useRef<HTMLElement>(null);
  const [categoryParent, setCategoryParent] = useState<category[] | null>(null);
  const [category, setCategory] = useState<category[] | null>(null);
  const [loadingSubCategories, setLoadingSubCategories] = useState(false);


  useEffect(() => {
    if (!mobileOpen) return;
    const previousFocus = document.activeElement as HTMLElement | null;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const menu = mobileMenuRef.current;
    menu?.querySelector<HTMLElement>('button[aria-label="Đóng menu"]')?.focus();
    const trapFocus = (event: KeyboardEvent) => {
      if (event.key !== "Tab" || !menu) return;
      const focusable = Array.from(menu.querySelectorAll<HTMLElement>('a[href], button, input'))
        .filter(element => !element.hasAttribute("disabled") && element.getClientRects().length > 0);
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault(); last?.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault(); first?.focus();
      }
    };
    const desktop = window.matchMedia("(min-width: 1024px)");
    const closeOnDesktop = () => { if (desktop.matches) setMobileOpen(false); };
    desktop.addEventListener("change", closeOnDesktop);
    document.addEventListener("keydown", trapFocus);
    return () => {
      document.body.style.overflow = previousOverflow;
      document.removeEventListener("keydown", trapFocus);
      desktop.removeEventListener("change", closeOnDesktop);
      previousFocus?.focus({ preventScroll: true });
    };
  }, [mobileOpen]);



  useEffect(() => {
    async function fetchCategories() {
      try {
        const response = await getCategoriesParent();
        const categories = response?.data;

        setCategoryParent(categories);

        if (categories && categories.length > 0) {
          setActiveSection(categories[0].id);
        }
      } catch (error) {
        console.error("Lỗi khi fetch category:", error);
      }
    }

    fetchCategories();
  }, []);

  useEffect(() => {
    async function fetchSubCategories() {
      if (activeSection) {
        setLoadingSubCategories(true);
        try {
          const response = await getCategories(activeSection);
          setCategory(response?.data || []);
        } catch (error) {
          console.error("Lỗi khi fetch category con:", error);
          setCategory([]);
        } finally {
          setLoadingSubCategories(false);
        }
      }
    }

    fetchSubCategories();
  }, [activeSection]);

  useEffect(() => {
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setCatalogOpen(false);
        setMobileOpen(false);
      }
    };

    document.addEventListener("keydown", closeOnEscape);
    return () => document.removeEventListener("keydown", closeOnEscape);
  }, []);



  useEffect(() => {
    if (!accountOpen) return;
    const closeOutside = (event: PointerEvent) => {
      if (!accountRef.current?.contains(event.target as Node)) setAccountOpen(false);
    };
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setAccountOpen(false);
        accountRef.current?.querySelector<HTMLButtonElement>("button")?.focus();
      }
    };
    document.addEventListener("pointerdown", closeOutside);
    document.addEventListener("keydown", closeOnEscape);
    return () => {
      document.removeEventListener("pointerdown", closeOutside);
      document.removeEventListener("keydown", closeOnEscape);
    };
  }, [accountOpen]);

  const handleSearch = (event: FormEvent) => {
    event.preventDefault();
    const value = query.trim();
    if (!value) return;
    router.push(`/products?q=${encodeURIComponent(value)}`);
    setCatalogOpen(false);
    setMobileOpen(false);
  };

  const openSearch = () => {
    const desktop = window.matchMedia("(min-width: 1024px)").matches;
    // Apply the open state before focusing an input that was hidden.
    flushSync(() => {
      setAccountOpen(false);
      setCatalogOpen(desktop);
      setMobileOpen(!desktop);
    });
    const input = desktop ? searchRef.current : mobileSearchRef.current;
    input?.focus({ preventScroll: true });
  };

  const closeNavigation = () => {
    setAccountOpen(false);
    setCatalogOpen(false);
    setMobileOpen(false);
  };

  const openCart = () => {
    setAccountOpen(false);
    setCatalogOpen(false);
    setMobileOpen(false);
    cart.openCart();
  };


  return (
    <>
      <div className="flex h-9 items-center justify-center gap-4 bg-black px-4 text-[10px] font-bold tracking-[0.2em] text-white uppercase sm:text-[11px]">
        <span>Miễn phí giao hàng từ 600.000 VND</span>
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
            aria-controls="mobile-navigation"
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
            ZELLA
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
            <Link
              href="/blog"
              onClick={closeNavigation}
              className={`relative flex h-full items-center text-[13.5px] font-bold uppercase tracking-[0.06em] transition-colors after:absolute after:bottom-0 after:left-0 after:h-0.5 after:bg-black after:transition-all ${pathname.startsWith("/blog")
                ? "text-black after:w-full"
                : "text-black/90 after:w-0 hover:text-black hover:after:w-full"
                }`}
            >
              Bài viết
            </Link>
          </nav>

          {/* Tìm kiếm */}
          <div className="flex items-center justify-end gap-1.5">
            <button type="button" className="grid size-10 place-items-center rounded-full text-black transition-colors hover:bg-black/5" aria-label="Tìm kiếm" onClick={openSearch}>
              <span className="material-symbols-outlined" style={{ fontSize: 22 }}>search</span>
            </button>
            <button type="button" onClick={openCart} className="relative grid size-10 place-items-center rounded-full border-0 bg-transparent text-black transition-colors hover:bg-black/5" aria-label={`Mở giỏ hàng, ${cart.totalQuantity} sản phẩm`} aria-expanded={cart.drawerOpen}>
              <span className="material-symbols-outlined" style={{ fontSize: 22 }}>shopping_bag</span>
              <span className="absolute top-1.5 right-1.5 grid size-3.75 place-items-center rounded-full bg-black text-[8px] font-bold text-white shadow-sm">{cart.totalQuantity}</span>
            </button>
            <div ref={accountRef} className="relative">
              <button type="button" onClick={() => { setCatalogOpen(false); setMobileOpen(false); setAccountOpen(open => !open); }} aria-expanded={accountOpen} aria-controls="account-menu" className="grid size-10 place-items-center rounded-full text-black transition-colors hover:bg-black/5" aria-label="Mở menu tài khoản">
                {auth.user && (auth.user.avatar || auth.user.picture || auth.user.photoUrl || auth.user.imageUrl) ? (
                  <Image unoptimized width={28} height={28} src={(auth.user.avatar || auth.user.picture || auth.user.photoUrl || auth.user.imageUrl) as string} alt="Avatar" className="size-7 rounded-full object-cover border border-black/10" />
                ) : auth.user ? (
                  <div className="flex size-7 items-center justify-center rounded-full bg-black text-[12px] font-bold text-white">
                    {(String(auth.user.username || auth.user.email || "U")).charAt(0).toUpperCase()}
                  </div>
                ) : (
                  <span className="material-symbols-outlined" style={{ fontSize: 22 }}>person</span>
                )}
              </button>
              {/* Profile Dropdown */}
              <div id="account-menu" hidden={!accountOpen} className="absolute right-0 top-full mt-2 w-48 rounded-xl border border-black/10 bg-white p-1.5 shadow-lg">
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
                      <Link href="/profile" onClick={closeNavigation} className="flex items-center gap-2 rounded-lg px-2 py-1.5 text-[12px] font-medium text-black/80 transition-colors hover:bg-black/5 hover:text-black">
                        <span className="material-symbols-outlined text-[16px]">account_circle</span>
                        Hồ sơ
                      </Link>
                      <Link href="/orders" onClick={closeNavigation} className="flex items-center gap-2 rounded-lg px-2 py-1.5 text-[12px] font-medium text-black/80 transition-colors hover:bg-black/5 hover:text-black">
                        <span className="material-symbols-outlined text-[16px]">local_mall</span>
                        Đơn hàng
                      </Link>
                    </div>
                    <div className="mt-1.5 border-t border-black/10 pt-1.5">
                      <button type="button" onClick={() => { closeNavigation(); void auth.logout().then(() => router.push("/")).catch(console.error); }} className="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-left text-[12px] font-medium text-red-600 transition-colors hover:bg-red-50">
                        <span className="material-symbols-outlined text-[16px]">logout</span>
                        Đăng xuất
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className="p-2 text-center">
                    <h4 className="mb-1 text-[12px] font-semibold text-black">Tài khoản</h4>
                    <p className="mb-3 text-[11px] leading-relaxed text-black/60">Đăng nhập để xem đơn hàng và thông tin cá nhân.</p>
                    <div className="flex flex-col gap-1.5">
                      <Link href="/login" onClick={closeNavigation} className="flex w-full items-center justify-center rounded-lg bg-black px-3 py-2 text-[11px] font-bold text-white transition-colors hover:bg-black/80">
                        ĐĂNG NHẬP
                      </Link>
                      <Link href="/register" onClick={closeNavigation} className="flex w-full items-center justify-center rounded-lg border border-black/20 bg-white px-3 py-2 text-[11px] font-bold text-black transition-colors hover:bg-black/5">
                        TẠO TÀI KHOẢN
                      </Link>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Danh mục sản phẩm  */}
        <section
          id="catalog-menu"
          aria-label="Danh mục sản phẩm"
          aria-hidden={!catalogOpen}
          className={`absolute top-full left-0 w-full border-b border-black/10 bg-white shadow-[0_28px_60px_rgba(20,22,18,0.14)] z-50 transition-[opacity,transform,visibility] duration-200 ${catalogOpen ? "visible translate-y-0 opacity-100" : "invisible -translate-y-2 pointer-events-none opacity-0"}`}
        >
          <div className="container mx-auto max-h-[calc(100vh-100px)] overflow-y-auto px-8 pt-6 pb-7 xl:px-12">
            <div className="flex items-center justify-between border-b border-black/10">
              <div role="tablist" aria-label="Nhóm sản phẩm" className="flex items-center gap-7">
                {(categoryParent || []).map((category) => (
                  <button
                    type="button"
                    role="tab"
                    aria-selected={activeSection === category.id}
                    key={category.id}
                    className={`relative border-0 bg-transparent pb-4 text-[12px] font-semibold tracking-[0.08em] uppercase transition-colors after:absolute after:bottom-0 after:left-0 after:h-0.5 after:bg-[#1d211c] after:transition-all ${activeSection === category.id ? "text-[#1d211c] after:w-full" : "text-[#8a8d85] after:w-0 hover:text-[#1d211c]"}`}
                    onMouseEnter={() => setActiveSection(category.id)}
                    onFocus={() => setActiveSection(category.id)}
                    onClick={() => setActiveSection(category.id)}
                  >
                    {category.name}
                  </button>
                ))}
              </div>
              <button type="button" className="mb-3 grid size-9 place-items-center rounded-full text-[#555851] transition-colors hover:bg-black/5 hover:text-black" aria-label="Đóng danh mục" onClick={() => setCatalogOpen(false)}>
                <span className="material-symbols-outlined" style={{ fontSize: 19 }}>close</span>
              </button>
            </div>

            <form onSubmit={handleSearch} className="my-6 grid h-12 grid-cols-[22px_1fr_auto] items-center gap-3 rounded-full border border-black/15 bg-white px-5 transition-shadow focus-within:border-black/30 focus-within:shadow-[0_0_0_3px_rgba(29,33,28,0.05)]">
              <button type="button" aria-label="Nhập từ khóa tìm kiếm" onClick={() => searchRef.current?.focus()} className="grid place-items-center text-[#777a72]"><span className="material-symbols-outlined" style={{ fontSize: 19 }}>search</span></button>
              <input
                ref={searchRef}
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                className="min-w-0 border-0 bg-transparent text-[14px] text-[#1d211c] outline-none placeholder:text-[#96988f]"
                placeholder="Tìm áo, váy, quần hoặc chất liệu..."
                aria-label="Từ khóa tìm kiếm"
              />
              <button type="submit" className="rounded-full bg-[#1d211c] px-4 py-2 text-[10px] font-semibold tracking-[0.08em] text-white uppercase transition-colors hover:bg-black">Tìm kiếm</button>
            </form>

            {loadingSubCategories ? (
              <div className={`${catalogStyles.categories} animate-pulse`} aria-label="Đang tải danh mục" aria-busy="true">
                {Array.from({ length: 6 }).map((_, index) => (
                  <div key={index} className="min-w-0">
                    <div className={`${catalogStyles.image} bg-black/5`} />
                    <div className="mt-2.5 h-3.5 w-3/4 rounded bg-black/5" />
                  </div>
                ))}
              </div>
            ) : category && category.length > 0 ? (
              <div key={activeSection} role="tabpanel" tabIndex={0} aria-label="Danh mục sản phẩm, cuộn để xem thêm" className={catalogStyles.categories}>
                {category.map((item) => (
                  <Link
                    key={item.id}
                    href={`/products?cat=${item.id}&categoryName=${encodeURIComponent(item.name)}`}
                    onClick={closeNavigation}
                    className={`group ${catalogStyles.item}`}
                  >
                    <div className={catalogStyles.image}>
                      <Image
                        src={item.imageUrl || "/assets/images/v7_1795.png"}
                        alt={item.name || ""}
                        fill
                        sizes="104px"
                        className="object-contain transition-transform duration-500 ease-out group-hover:scale-[1.035]"
                      />
                    </div>
                    <div className={catalogStyles.label}>
                        {item.name}
                    </div>
                  </Link>
                ))}
              </div>
            ) : (
              <div className="py-14 text-center">
                <p className="text-[13.5px] font-medium text-[#2b2e29]">Chưa có danh mục sản phẩm</p>
                <p className="mt-1 text-[11.5px] text-[#8a8d85]">Danh mục này hiện chưa có sản phẩm nào được cập nhật.</p>
              </div>
            )}

            <div className="mt-6 border-t border-black/10 pt-4 text-[10px] text-[#777a72]">
              <p>Thiết kế có chủ đích · Chất liệu được tuyển chọn</p>
            </div>
          </div>
        </section>
      </header >

      {catalogOpen && (
        <button type="button" className="fixed inset-0 z-40 hidden cursor-default bg-[#171914]/25 backdrop-blur-[1px] lg:block" aria-label="Đóng danh mục sản phẩm" onClick={() => setCatalogOpen(false)} />
      )
      }

      <div className={`fixed inset-0 z-60 bg-[#171914]/35 transition-opacity duration-200 lg:hidden ${mobileOpen ? "visible opacity-100" : "invisible pointer-events-none opacity-0"}`} onClick={() => setMobileOpen(false)} />
      <aside ref={mobileMenuRef} id="mobile-navigation" role="dialog" aria-modal={mobileOpen ? true : undefined} aria-label="Menu điều hướng" inert={!mobileOpen} className={`${mobileStyles.drawer} fixed top-0 left-0 z-70 shadow-2xl transition-transform duration-300 ease-out lg:hidden ${mobileOpen ? "translate-x-0" : "-translate-x-full"}`} aria-hidden={!mobileOpen}>
        <div className={`${mobileStyles.head} flex items-center justify-between border-b border-black/10 pb-4`}>
          <Link href="/" onClick={closeNavigation} className="text-[19px] font-bold tracking-[0.2em] text-[#1d211c]">ZELLA</Link>
          <button type="button" onClick={() => setMobileOpen(false)} className={`${mobileStyles.close} grid place-items-center rounded-full bg-black/5`} aria-label="Đóng menu"><span className="material-symbols-outlined" style={{ fontSize: 20 }}>close</span></button>
        </div>

        <form onSubmit={handleSearch} className={`${mobileStyles.search} my-5 grid h-12 grid-cols-[20px_1fr] items-center gap-2 rounded-full border border-black/15 bg-white px-4`}>
          <button type="button" aria-label="Nhập từ khóa tìm kiếm" onClick={() => mobileSearchRef.current?.focus()} className="grid place-items-center text-[#777a72]"><span className="material-symbols-outlined" style={{ fontSize: 17 }}>search</span></button>
          <input ref={mobileSearchRef} value={query} onChange={(event) => setQuery(event.target.value)} className="min-w-0 border-0 bg-transparent text-[13px] outline-none placeholder:text-[#9a9c95]" placeholder="Tìm kiếm sản phẩm" aria-label="Từ khóa tìm kiếm" />
        </form>

        <nav aria-label="Điều hướng di động" className={`${mobileStyles.navigation} flex flex-col`}>
          <Link href="/" onClick={closeNavigation} className="border-b border-black/10 py-4 text-[14px] font-medium">Trang chủ</Link>
          <button type="button" className="flex items-center justify-between border-b border-black/10 bg-transparent py-4 text-left text-[14px] font-medium" aria-expanded={mobileProductsOpen} onClick={() => setMobileProductsOpen((open) => !open)}>
            Sản phẩm
            <span className={`material-symbols-outlined transition-transform ${mobileProductsOpen ? "rotate-180" : ""}`} style={{ fontSize: 16 }}>expand_more</span>
          </button>
          {mobileProductsOpen && <div className={mobileStyles.categories}>
            {categoryParent?.map(item => <MobileCategoryGroup key={item.id} parent={item} onNavigate={closeNavigation} />)}
          </div>}
          <Link href="/blog" onClick={closeNavigation} className="border-b border-black/10 py-4 text-[14px] font-medium">Bài viết</Link>

          <Link href="/loyalty" onClick={closeNavigation} className="border-b border-black/10 py-4 text-[14px] font-medium">Điểm thưởng</Link>
        </nav>

        <div className={mobileStyles.account}>
          <Link href={auth.user ? "/profile" : "/login"} onClick={closeNavigation} className="flex items-center justify-center gap-2 rounded-full border border-black/15 bg-white px-3 py-3 text-[11px] font-medium"><span className="material-symbols-outlined" style={{ fontSize: 16 }}>person</span> Tài khoản</Link>
        </div>
      </aside>
    </>
  );
}
