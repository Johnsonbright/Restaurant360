import { Suspense } from "react";
import { AuthForm } from "@/components/auth-form";
import { LoginPageContent } from "@/components/login-page-content";

export default function LoginPage() {
  return (
    <Suspense fallback={<AuthForm mode="login" />}>
      <LoginPageContent />
    </Suspense>
  );
}
