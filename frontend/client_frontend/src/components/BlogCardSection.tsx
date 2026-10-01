"use client";
import React from 'react';
import BlogCard from './BlogCard';

export default function BlogCardSection() {
  const blogs = [
    {
      id: 1,
      title: "5 cách phối linen thanh lịch cho nàng công sở",
      summary: "Khám phá cách biến tấu những chiếc áo sơ mi linen mộc mạc thành set đồ trang nhã nhưng không kém phần cuốn hút.",
      image: "/assets/images/v7_1750.png",
      created_at: "16 Th09, 2026",
      category: "Phong cách"
    },
    {
      id: 2,
      title: "Chọn trang phục tối giản theo từng vóc dáng",
      summary: "Tôn vinh đường nét cơ thể tự nhiên với những mẹo chọn phom dáng đầm midi và quần ống suông chuẩn xác.",
      image: "/assets/images/v7_1754.png",
      created_at: "14 Th09, 2026",
      category: "Mẹo vặt"
    },
    {
      id: 3,
      title: "Chăm sóc vải lụa và linen để bền đẹp theo năm tháng",
      summary: "Cẩm nang giặt, ủi và bảo quản trang phục từ sợi tự nhiên luôn mềm mại, giữ màu tốt qua từng mùa thời trang.",
      image: "/assets/images/v7_1758.png",
      created_at: "10 Th09, 2026",
      category: "Bảo quản"
    }
  ];

  return (
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
  );
}
