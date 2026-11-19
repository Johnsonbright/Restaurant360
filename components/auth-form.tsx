"use client";

import Link from "next/link";
import { useActionState } from "react";
import { FadeUp } from "@/components/animations";
import { GoogleSignInButton } from "@/components/google-sign-in-button";
import { Button } from "@/components/ui/button";
import { loginAction, registerAction } from "@/app/actions/auth";

type AuthFormProps = Readonly<{
  mode: "login" | "register";
  oauthError?: boolean;
}>;

export function AuthForm({ mode, oauthError = false }: AuthFormProps) {
  const isRegister = mode === "register";
  const action = isRegister ? registerAction : loginAction;
  const [state, formAction, isPending] = useActionState(action, {});

  return (
    <main className="flex min-h-[calc(100vh-2rem)] flex-1 items-center justify-center px-5 py-12">
      <FadeUp className="w-full max-w-md">
        <section className="rounded-xl border border-border bg-card p-6 shadow-xl shadow-black/5 sm:p-9">
          <Link className="font-display text-xl font-semibold text-primary" href="/">
            Restaurant360
          </Link>
          <p className="mt-8 text-xs font-semibold uppercase tracking-[0.2em] text-primary">
            Welcome
          </p>
          <h1 className="mt-2 font-display text-4xl tracking-tight">
            {isRegister ? "Join us at the table" : "Welcome back"}
          </h1>
          <p className="mt-3 text-sm text-muted-foreground">
            {isRegister
              ? "Create an account to get started."
              : "Sign in to your Restaurant360 account."}
          </p>
          <form action={formAction} className="mt-7 space-y-4">
            {isRegister && (
              <label className="block space-y-2 text-sm font-medium">
                Full name
                <input
                  autoComplete="name"
                  className="h-11 w-full rounded-lg border border-input bg-background px-3 text-foreground placeholder:text-muted-foreground"
                  name="fullName"
                  placeholder="Your name"
                  required
                />
              </label>
            )}
            <label className="block space-y-2 text-sm font-medium">
              Email address
              <input
                autoComplete="email"
                className="h-11 w-full rounded-lg border border-input bg-background px-3 text-foreground placeholder:text-muted-foreground"
                name="email"
                placeholder="you@example.com"
                required
                type="email"
              />
            </label>
            <label className="block space-y-2 text-sm font-medium">
              Password
              <input
                autoComplete={isRegister ? "new-password" : "current-password"}
                className="h-11 w-full rounded-lg border border-input bg-background px-3 text-foreground"
                minLength={8}
                name="password"
                required
                type="password"
              />
            </label>
            {(state.error || state.message || oauthError) && (
              <p
                aria-live="polite"
                className={
                  state.error || oauthError
                    ? "text-sm text-destructive"
                    : "text-sm text-muted-foreground"
                }
                role={state.error || oauthError ? "alert" : "status"}
              >
                {state.error ||
                  (oauthError
                    ? "Google sign-in could not be completed. Please try again or use your email and password."
                    : state.message)}
              </p>
            )}
            <Button className="h-11 w-full rounded-lg" disabled={isPending} type="submit">
              {isPending
                ? "Please wait..."
                : isRegister
                  ? "Create account"
                  : "Log in"}
            </Button>
          </form>
          <div className="my-6 flex items-center gap-3" aria-hidden="true">
            <span className="h-px flex-1 bg-border" />
            <span className="text-xs uppercase tracking-[0.15em] text-muted-foreground">
              Or
            </span>
            <span className="h-px flex-1 bg-border" />
          </div>
          <GoogleSignInButton />
          <p className="mt-6 text-center text-sm text-muted-foreground">
            {isRegister ? "Already registered? " : "New to Restaurant360? "}
            <Link
              className="font-semibold text-primary underline-offset-4 hover:underline"
              href={isRegister ? "/login" : "/register"}
            >
              {isRegister ? "Log in" : "Create an account"}
            </Link>
          </p>
        </section>
      </FadeUp>
    </main>
  );
}
