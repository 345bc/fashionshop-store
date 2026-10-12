import { createHmac, timingSafeEqual } from "node:crypto";

export const WORKFLOW_COOKIE = "zella_checkout_flow";
export type Workflow = { phase: "checkout" | "paid"; expiresAt: number };

function secret() {
  const value = process.env.WORKFLOW_COOKIE_SECRET;
  if (!value || value.length < 32) throw new Error("WORKFLOW_COOKIE_SECRET must contain at least 32 characters");
  return value;
}

export function signWorkflow(phase: Workflow["phase"]) {
  const value = Buffer.from(JSON.stringify({ phase, expiresAt: Date.now() + 3600_000 })).toString("base64url");
  return `${value}.${createHmac("sha256", secret()).update(value).digest("base64url")}`;
}

export function verifyWorkflow(value?: string): Workflow | null {
  if (!value || value.length > 512) return null;
  try {
    const parts = value.split(".");
    if (parts.length !== 2) return null;
    const expected = createHmac("sha256", secret()).update(parts[0]).digest();
    const received = Buffer.from(parts[1], "base64url");
    if (expected.length !== received.length || !timingSafeEqual(expected, received)) return null;
    const data = JSON.parse(Buffer.from(parts[0], "base64url").toString("utf8"));
    return ["checkout", "paid"].includes(data.phase) && Number.isFinite(data.expiresAt) && data.expiresAt > Date.now() ? data : null;
  } catch { return null; }
}
