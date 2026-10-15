import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  async rewrites() {
    const backend = (process.env.BACKEND_API_BASE_URL ||"").replace(/\/$/, '');
    return [{ source: '/api/v1/:path*', destination: `${backend}/:path*` }];
  },
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'images.unsplash.com',
      },
      {
        protocol: 'https',
        hostname: 'fakestoreapi.com',
      },
      {
        protocol: 'https',
        hostname: 'pub-830cafaa2d594f81ba2a433664da10a5.r2.dev',
      },
    ],
  },
};

export default nextConfig;
