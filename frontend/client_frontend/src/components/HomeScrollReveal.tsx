"use client";

import { createContext, useContext, useLayoutEffect, useRef, useState, type ReactNode } from "react";
import styles from "./HomeScrollReveal.module.css";

const HomeSectionReady = createContext(true);

export function useHomeSectionReady() {
  return useContext(HomeSectionReady);
}

export default function HomeScrollReveal({ children, defer = false }: { children: ReactNode; defer?: boolean }) {
  const ref = useRef<HTMLDivElement>(null);
  const [ready, setReady] = useState(false);

  useLayoutEffect(() => {
    const element = ref.current;
    if (!element) return;
    if (!("IntersectionObserver" in window)) {
      if (!defer) return;
      const frame = requestAnimationFrame(() => setReady(true));
      return () => cancelAnimationFrame(frame);
    }

    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) reveal();
    });

    function reveal() {
      if (element?.dataset.reveal === "pending") {
        element.setAttribute("data-reveal", "visible");
      }
      if (defer) setReady(true);
      observer.disconnect();
    }

    const belowViewport = element.getBoundingClientRect().top >= window.innerHeight;
    if (belowViewport && !reducedMotion) {
      element.setAttribute("data-reveal", "pending");
    }
    if (defer || (belowViewport && !reducedMotion)) {
      observer.observe(element);
      element.addEventListener("focusin", reveal);
    }

    return () => {
      observer.disconnect();
      element.removeEventListener("focusin", reveal);
      element.removeAttribute("data-reveal");
    };
  }, [defer]);

  return <div ref={ref} className={styles.reveal}>
    {defer ? <HomeSectionReady.Provider value={ready}>{children}</HomeSectionReady.Provider> : children}
  </div>;
}
