import type { Metadata } from "next";
import type { ReactNode } from "react";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import "./pages.css";
import "../cart/cart.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Zella — Thời Trang Tối Giản & Bền Vững",
  description: "Zella - Thiết kế thanh lịch từ chất liệu tự nhiên, tôn vinh nét đẹp tinh tế trong từng khoảnh khắc thường nhật.",
  icons: {
    icon: "https://pub-830cafaa2d594f81ba2a433664da10a5.r2.dev/system-images/BrandLogo.png",
    shortcut: "https://pub-830cafaa2d594f81ba2a433664da10a5.r2.dev/system-images/BrandLogo.png",
    apple: "https://pub-830cafaa2d594f81ba2a433664da10a5.r2.dev/system-images/BrandLogo.png",
  },
};

import { AuthProvider } from "../auth/AuthContext";
import { CartProvider } from "../cart/CartContext";
import CartDrawer from "../cart/CartDrawer";
import ZellaAssistant from "../components/ZellaAssistant";
import { ConnectionErrorProvider } from "../components/ConnectionError";

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="vi" className={`${geistSans.variable} ${geistMono.variable}`}>
      <head>
        <link rel="icon" href="https://pub-830cafaa2d594f81ba2a433664da10a5.r2.dev/system-images/BrandLogo.png" />
        {/* eslint-disable-next-line @next/next/no-page-custom-font */}
        <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=swap" rel="stylesheet" />
      </head>
      <body>
        <AuthProvider><CartProvider><ConnectionErrorProvider>{children}<CartDrawer /><ZellaAssistant /></ConnectionErrorProvider></CartProvider></AuthProvider>
      </body>
    </html>
  );
}
