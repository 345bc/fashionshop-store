import PasswordRecoveryForm from "@/components/PasswordRecoveryForm";

export const metadata = { title: "Đặt lại mật khẩu | ZELLA", robots: { index: false, follow: false }, referrer: "no-referrer" as const };

export default function ResetPasswordPage() {
  return <PasswordRecoveryForm reset />;
}
