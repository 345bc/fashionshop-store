import Link from "next/link";

export default function AuthNavbar() {
  return (
    <header className="sticky top-0 z-50 flex h-16 shrink-0 items-center justify-center border-b border-black/10 bg-white lg:h-18">
      <Link
        href="/"
        className="whitespace-nowrap text-[18px] font-bold tracking-[0.2em] text-[#1d211c] lg:text-[22px]"
        aria-label="Trang chủ ZELLA"
      >
        ZELLA
      </Link>
    </header>
  );
}
