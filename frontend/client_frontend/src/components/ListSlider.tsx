"use client";
import React from "react";
import { Swiper, SwiperSlide } from "swiper/react";
import { Navigation, Pagination, Autoplay } from "swiper/modules";

// Import Swiper styles
import "swiper/css";
import "swiper/css/navigation";
import "swiper/css/pagination";

interface ListSliderProps {
  children: React.ReactNode;
  fullWidthItems?: boolean;
  itemWidth?: string;
}

export default function ListSlider({ children, fullWidthItems = false, itemWidth = "260px" }: ListSliderProps) {
  if (fullWidthItems) {
    return (
      <Swiper
        modules={[Navigation, Pagination, Autoplay]}
        spaceBetween={0}
        slidesPerView={1}
        navigation
        pagination={{ clickable: true }}
        autoplay={{ delay: 5000, disableOnInteraction: false }}
        loop={true}
        style={{ width: "100%", height: "100%" }}
      >
        {React.Children.map(children, (child, index) => (
          <SwiperSlide key={index}>{child}</SwiperSlide>
        ))}
      </Swiper>
    );
  }

  return (
    <div style={{ position: "relative" }}>
      <Swiper
        modules={[Navigation]}
        spaceBetween={16}
        slidesPerView="auto"
        navigation
        style={{ paddingBottom: "16px" }}
        className="multi-item-swiper"
      >
        {React.Children.map(children, (child, index) => (
          <SwiperSlide key={index} style={{ width: "auto" }}>
            <div style={{ width: itemWidth }}>{child}</div>
          </SwiperSlide>
        ))}
      </Swiper>
    </div>
  );
}
