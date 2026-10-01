"use client";

import { useState } from "react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import AccountNav from "@/components/AccountNav";
import Image from "next/image";
import Link from "next/link";

export default function PurchaseHistoryPage() {
  const [reviewOpen, setReviewOpen] = useState(false);
  const [rating, setRating] = useState(5);
  const [review, setReview] = useState("");
  const [submitted, setSubmitted] = useState(false);

  const submitReview = () => { setSubmitted(true); setTimeout(() => setReviewOpen(false), 900); };

  return (
    <>
      <Header />
      <main className="main-content modern-main account-modern-page">
        <div className="breadcrumb modern-breadcrumb"><Link href="/">Trang chủ</Link><span>/</span><span>Lịch sử mua</span></div>
        <div className="account-modern-layout">
          <AccountNav active="history" />
          <section className="account-content-modern">
            <span className="eyebrow">MY PURCHASES</span><h1>Lịch sử mua & đánh giá</h1><p className="account-lead">Bạn có thể đánh giá sản phẩm trong các đơn đã giao thành công.</p>
            <article className="purchase-card-modern">
              <div className="purchase-card-top"><div><strong>#ZEL88392</strong><span>Đã giao · 10/09/2026</span></div><div className="complete-pill"><span className="material-symbols-outlined" style={{ fontSize: 15 }}>check_circle</span> Hoàn tất</div></div>
              <div className="purchase-product-modern"><Image src="/assets/images/v7_2020.png" alt="Váy midi Sage Flow" width={96} height={128} /><div><small>WOMEN / DRESS</small><h3>Váy midi Sage Flow</h3><p>Sage · M · Số lượng 1</p><strong>679.000₫</strong></div><button onClick={() => { setSubmitted(false); setReviewOpen(true); }}>Đánh giá sản phẩm</button></div>
            </article>
            <article className="purchase-card-modern faded"><div className="purchase-card-top"><div><strong>#ZEL86704</strong><span>Đã giao · 22/08/2026</span></div><div className="complete-pill"><span className="material-symbols-outlined" style={{ fontSize: 15 }}>check_circle</span> Hoàn tất</div></div><div className="purchase-product-modern"><Image src="/assets/images/v7_1730.png" alt="Quần suông Soft Tailoring" width={96} height={128} /><div><small>WOMEN / PANTS</small><h3>Quần suông Soft Tailoring</h3><p>Cocoa · S · Số lượng 1</p><strong>549.000₫</strong></div><span className="reviewed-label">Đã đánh giá · 5★</span></div></article>
          </section>
        </div>
      </main>
      <Footer />

      {reviewOpen && <div className="modern-modal-backdrop" onClick={() => setReviewOpen(false)}><div className="modern-modal review-modal" onClick={(e) => e.stopPropagation()}><button className="modal-close" onClick={() => setReviewOpen(false)}><span className="material-symbols-outlined" style={{ fontSize: 20 }}>close</span></button>{submitted ? <div className="review-success"><span className="material-symbols-outlined" style={{ fontSize: 42 }}>check_circle</span><h2>Cảm ơn bạn!</h2><p>Đánh giá đã được ghi nhận.</p></div> : <><span className="eyebrow">PRODUCT REVIEW</span><h2>Đánh giá sản phẩm</h2><div className="review-product-mini"><Image src="/assets/images/v7_2020.png" alt="Váy midi Sage Flow" width={64} height={86} /><div><strong>Váy midi Sage Flow</strong><span>Sage · M</span></div></div><div className="star-picker"><span>Mức độ hài lòng</span><div>{[1,2,3,4,5].map((n) => <button key={n} onClick={() => setRating(n)} aria-label={`${n} sao`}><span className="material-symbols-outlined" style={{ fontSize: 28 }}>star</span></button>)}</div></div><label className="review-textarea"><span>Nhận xét của bạn</span><textarea value={review} onChange={(e) => setReview(e.target.value)} placeholder="Chia sẻ về chất liệu, phom dáng hoặc trải nghiệm sử dụng..." rows={5} /></label><button className="modern-submit" onClick={submitReview}>Gửi đánh giá {rating} sao</button></>}</div></div>}
    </>
  );
}
