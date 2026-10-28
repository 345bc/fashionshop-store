import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  experimental: {
    // Image inference can outlast Next.js's default 30-second rewrite timeout.
    proxyTimeout: 130000,
  },
  async rewrites() {
    const backendApi = (process.env.BACKEND_API_BASE_URL || "").replace(/\/$/, "");
    const backendRoot = (process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:8080").replace(/\/$/, "");
    return [
      { source: "/api/v1/:path*", destination: `${backendApi}/:path*` },
      { source: "/oauth2/:path*", destination: `${backendRoot}/oauth2/:path*` },
      { source: "/login/oauth2/:path*", destination: `${backendRoot}/login/oauth2/:path*` },
    ];
  },
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "images.unsplash.com",
      },
      {
        protocol: "https",
        hostname: "fakestoreapi.com",
      },
      {
        protocol: "https",
        hostname: "pub-830cafaa2d594f81ba2a433664da10a5.r2.dev",
      },
    ],
  },
};

export default nextConfig;
