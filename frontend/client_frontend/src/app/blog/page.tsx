"use client";

import React from 'react';
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import BlogCard from "@/components/BlogCard";

export default function BlogPage() {
  const blogs = [
    {
      id: 1,
      title: "5 cách phối linen thanh lịch cho nàng công sở",
      summary: "Khám phá cách biến tấu những chiếc áo sơ mi linen mộc mạc thành set đồ trang nhã nhưng không kém phần cuốn hút.",
      image: "https://images.unsplash.com/photo-1515347619252-8bbfa678d407?w=600&q=80",
      created_at: "16 Th09, 2026",
      category: "Phong cách"
    },
    {
      id: 2,
      title: "Chọn trang phục tối giản theo từng vóc dáng",
      summary: "Tôn vinh đường nét cơ thể tự nhiên với những mẹo chọn phom dáng đầm midi và quần ống suông chuẩn xác.",
      image: "https://images.unsplash.com/photo-1542272454315-4c01d7abdf4a?w=600&q=80",
      created_at: "14 Th09, 2026",
      category: "Mẹo vặt"
    },
    {
      id: 3,
      title: "Chăm sóc vải lụa và linen để bền đẹp theo năm tháng",
      summary: "Cẩm nang giặt, ủi và bảo quản trang phục từ sợi tự nhiên luôn mềm mại, giữ màu tốt qua từng mùa thời trang.",
      image: "https://images.unsplash.com/photo-1572635196237-14b3f281501f?w=600&q=80",
      created_at: "10 Th09, 2026",
      category: "Bảo quản"
    },
    {
      id: 4,
      title: "Màu sắc của năm: Ứng dụng tone đất vào trang phục hàng ngày",
      summary: "Gợi ý những cách phối màu sáng tạo nhưng vẫn giữ được nét thanh lịch vốn có của thời trang bền vững.",
      image: "https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600&q=80",
      created_at: "05 Th09, 2026",
      category: "Xu hướng"
    },
    {
      id: 5,
      title: "Sự trở lại của phong cách retro thập niên 90",
      summary: "Nhìn lại những item huyền thoại đã làm nên tên tuổi của thời trang thập niên 90 và cách phối chúng ở hiện tại.",
      image: "https://images.unsplash.com/photo-1519689680058-324335c77eba?w=600&q=80",
      created_at: "01 Th09, 2026",
      category: "Phong cách"
    },
    {
      id: 6,
      title: "Túi xách da thật: Đầu tư thông minh cho tủ đồ",
      summary: "Tại sao một chiếc túi xách da thật luôn là lựa chọn hàng đầu của những người phụ nữ yêu thời trang?",
      image: "https://images.unsplash.com/photo-1582719508461-905c673771fd?w=600&q=80",
      created_at: "28 Th08, 2026",
      category: "Phụ kiện"
    }
  ];

  return (
    <>
      <Header />
      <main className="main-content" style={{ padding: "60px 24px", minHeight: "80vh", maxWidth: "1280px", margin: "0 auto" }}>
        
        <div style={{ textAlign: "center", marginBottom: "48px" }}>
          <h1 style={{ fontSize: "2.5rem", fontWeight: 500, color: "var(--ink-primary)", marginBottom: "16px", letterSpacing: "0.2px" }}>
            Zella Post
          </h1>
          <p style={{ color: "var(--ink-secondary)", maxWidth: "600px", margin: "0 auto", fontSize: "1.05rem", lineHeight: "1.6" }}>
            Nơi chia sẻ những góc nhìn, xu hướng thời trang và mẹo nhỏ giúp bạn định hình phong cách cá nhân một cách tinh tế.
          </p>
        </div>

        <div className="blog-card-grid">
          {blogs.map((blog) => (
            <BlogCard
              key={blog.id}
              title={blog.title}
              image={blog.image}
              date={blog.created_at}
              category={blog.category}
              description={blog.summary}
              href={`/blog/${blog.id}`}
            />
          ))}
        </div>

      </main>
      <Footer />
    </>
  );
}
