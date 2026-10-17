"use client";

import ConnectionError from "@/components/ConnectionError";
import { useRouter } from "next/navigation";

export default function ConnectionErrorPage() {
  const router = useRouter();
  return <main><ConnectionError fullPage onRetry={() => window.history.length > 1 ? router.back() : router.push("/")} /></main>;
}
