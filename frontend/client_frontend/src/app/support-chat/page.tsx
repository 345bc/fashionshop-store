"use client";

import { FormEvent, useState } from "react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

type Message = { from: "bot" | "user"; text: string };

export default function SupportChatPage() {
  const [text, setText] = useState("");
  const [messages, setMessages] = useState<Message[]>([
    { from: "bot", text: "Xin chào! Zella có thể giúp gì cho bạn hôm nay?" },
    { from: "user", text: "Cho mình hỏi váy Sage Flow size M còn hàng không?" },
    { from: "bot", text: "Chào bạn, size M màu Sage hiện vẫn còn hàng. Bạn có thể thêm trực tiếp vào giỏ trên trang sản phẩm nhé." },
  ]);
  const send = (e: FormEvent) => { e.preventDefault(); if (!text.trim()) return; setMessages((m) => [...m,{from:"user",text:text.trim()},{from:"bot",text:"Zella đã nhận được tin nhắn. Nhân viên tư vấn sẽ tiếp tục hỗ trợ bạn ngay trong phiên chat này."}]); setText(""); };
  return (
    <>
      <Header />
      <main className="support-page-modern">
        <div className="support-intro"><span className="eyebrow">LIVE SUPPORT</span><h1>Trò chuyện cùng Zella</h1><p>Hỗ trợ về sản phẩm, kích cỡ, đơn hàng và đổi trả từ 08:00–22:00 mỗi ngày.</p></div>
        <section className="chat-modern">
          <div className="chat-modern-head"><div className="support-avatar">Z</div><div><strong>Zella Support</strong><span><i /> Đang trực tuyến</span></div></div>
          <div className="chat-modern-body">{messages.map((m,i) => <div key={i} className={`chat-bubble-modern ${m.from}`}>{m.text}</div>)}</div>
          <form className="chat-modern-input" onSubmit={send}><input value={text} onChange={(e) => setText(e.target.value)} placeholder="Nhập câu hỏi của bạn..." /><button aria-label="Gửi tin nhắn"><span className="material-symbols-outlined" style={{ fontSize: 17 }}>send</span></button></form>
        </section>
      </main>
      <Footer />
    </>
  );
}
