"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  ReactNode,
} from "react";
import { apiRequest, BACKEND_URL, clearCsrfToken } from "../api/apiClient";

const RETURN_TO_KEY = "auth_return_to";

export interface User {
  activeRole?: string;
  roles?: string[];
  profile?: Profile;
  [key: string]: unknown;
}

export interface Profile {
  fullname?: string;
  phone?: string;
  address?: string;
  membershipTier?: string;
  rewardPoints?: number;
  totalSpending?: number;
}

export interface AuthState {
  status: "loading" | "authenticated" | "anonymous" | "error";
  user: User | null;
  error: unknown | null;
}

export interface AuthContextType extends AuthState {
  refresh: () => Promise<unknown>;
  login: (email?: string, password?: string) => Promise<unknown>;
  register: (email?: string, password?: string, username?: string, fullName?: string, phone?: string) => Promise<unknown>;
  loginWithMicrosoft: (returnTo?: string) => void;
  mockLogin: (email: string) => Promise<unknown>;
  logout: () => Promise<void>;
  hasRole: (...allowedRoles: string[]) => boolean;
  selectRole: (role: string) => Promise<unknown>;
}

export const AuthContext = createContext<AuthContextType | null>(null);

function normalizeRole(role: unknown) {
  return String(role)
    .replace(/^ROLE_/, "")
    .toUpperCase();
}

function safeReturnTo(path: unknown) {
  if (typeof path !== "string") return "/";
  return path.startsWith("/") && !path.startsWith("//") ? path : "/";
}

export function takeLoginReturnTo() {
  const path = safeReturnTo(sessionStorage.getItem(RETURN_TO_KEY));
  sessionStorage.removeItem(RETURN_TO_KEY);
  return path;
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AuthState>({
    status: "loading",
    user: null,
    error: null,
  });

  const refresh = useCallback(async () => {
    try {
      const response = await apiRequest("/auth/me");
      setState({ status: "authenticated", user: response.data, error: null });
      return response.data;
    } catch (error: unknown) {
      const err = error as { status?: number };
      if (err?.status === 401) {
        setState({ status: "anonymous", user: null, error: null });
        return null;
      }
      setState({ status: "error", user: null, error });
      throw error;
    }
  }, []);

  useEffect(() => {
    const initAuth = async () => {
      try {
        await refresh();
      } catch {
        // ignore
      }
    };
    initAuth();
  }, [refresh]);

  const login = useCallback(
    async (email?: string, password?: string) => {
      const response = await apiRequest("/auth/login", {
        method: "POST",
        body: { email, password },
      });
      await refresh();
      return response;
    },
    [refresh],
  );

  const register = useCallback(
    async (email?: string, password?: string, username?: string, fullName?: string, phone?: string) => {
      const response = await apiRequest("/auth/register", {
        method: "POST",
        body: { email, password, username, fullName, phone },
      });
      await refresh();
      return response;
    },
    [refresh],
  );

  const loginWithMicrosoft = useCallback((returnTo = "/") => {
    sessionStorage.setItem(RETURN_TO_KEY, safeReturnTo(returnTo));
    // eslint-disable-next-line @next/next/no-location-assign-relative-destination
    window.location.href = `${BACKEND_URL}/oauth2/authorization/azure`;
  }, []);

  const mockLogin = useCallback(
    async (email: string) => {
      await apiRequest("/auth/mock-login", { method: "POST", body: { email } });
      return refresh();
    },
    [refresh],
  );

  const selectRole = useCallback(
    async (role: string) => {
      await apiRequest("/auth/select-role", { method: "POST", body: { role } });
      return refresh();
    },
    [refresh],
  );

  const logout = useCallback(async () => {
    try {
      await apiRequest("/auth/logout", { method: "POST" });
    } finally {
      clearCsrfToken();
      setState({ status: "anonymous", user: null, error: null });
    }
  }, []);

  const hasRole = useCallback(
    (...allowedRoles: string[]) => {
      const activeRole = state.user?.activeRole
        ? normalizeRole(state.user.activeRole)
        : null;
      if (!activeRole) return false;
      return allowedRoles.map(normalizeRole).includes(activeRole);
    },
    [state.user],
  );

  const value = useMemo(
    () => ({
      ...state,
      refresh,
      login,
      register,
      loginWithMicrosoft,
      mockLogin,
      logout,
      hasRole,
      selectRole,
    }),
    [
      state,
      refresh,
      login,
      register,
      loginWithMicrosoft,
      mockLogin,
      logout,
      hasRole,
      selectRole,
    ],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (!context)
    throw new Error("useAuth phải được dùng bên trong AuthProvider");
  return context;
}
