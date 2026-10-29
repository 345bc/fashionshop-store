import type { ReactNode } from "react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import AccountNav from "@/components/AccountNav";
import AccountSessionGuard from "./AccountSessionGuard";
import styles from "./AccountLayout.module.css";

export default function AccountLayout({ active, title, children }: { active: "orders" | "loyalty"; title: ReactNode; children: ReactNode }) {
  return <><Header /><AccountSessionGuard><main className="container mx-auto px-5 lg:px-10 py-10 text-gray-900">
    <div className={styles.shell}><AccountNav active={active} />
      <section className={styles.content}><h1 className="text-2xl font-bold mb-6">{title}</h1>{children}</section>
    </div></main></AccountSessionGuard><Footer /></>;
}
