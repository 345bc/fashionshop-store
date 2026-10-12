"use client";
import { useEffect, useState } from "react";
import { useAuth } from "@/auth/AuthContext";
import { apiRequest } from "@/api/apiClient";
import { apiError } from "@/service/accountService";
import type { ApiResponse } from "@/type/api";

export default function useAccountQuery<T>(path: string | null, version = 0) {
  const auth = useAuth(); const userId = auth?.user?.id;
  const key = `${userId}:${path}:${version}`;
  const [state, setState] = useState<{ key: string; data: T | null; error: string }>({ key: "", data: null, error: "" });
  useEffect(() => {
    const controller = new AbortController();
    if (!userId || !path) return () => controller.abort();
    apiRequest(path, { signal: controller.signal }).then((response: ApiResponse<T>) => {
      if (!controller.signal.aborted) setState({ key, data: response.data, error: "" });
    }).catch(error => { if (!controller.signal.aborted) setState({ key, data: null, error: apiError(error) }); });
    return () => controller.abort();
  }, [key, path, userId]);
  return { data: state.key === key ? state.data : null, error: state.key === key ? state.error : "", loading: !!path && state.key !== key };
}
