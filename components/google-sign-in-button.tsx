"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { createClient } from "@/lib/supabase/client";

export function GoogleSignInButton() {
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  async function signInWithGoogle() {
    setError("");
    setIsLoading(true);

    try {
      const { error: signInError } = await createClient().auth.signInWithOAuth({
        provider: "google",
        options: {
          redirectTo: `${window.location.origin}/auth/callback`,
        },
      });

      if (signInError) {
        setError("Google sign-in could not be started. Please try again.");
      }
    } catch (caught) {
      setError(
        caught instanceof Error
          ? caught.message
          : "Google sign-in could not be started. Please try again.",
      );
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div>
      <Button
        className="h-11 w-full rounded-lg"
        disabled={isLoading}
        onClick={signInWithGoogle}
        type="button"
        variant="outline"
      >
        <svg aria-hidden="true" className="mr-2 size-4" viewBox="0 0 48 48">
          <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5Z"/>
          <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.27 5.48-4.78 7.18l7.73 6C44.4 37.96 46.98 31.84 46.98 24.55Z"/>
          <path fill="#FBBC05" d="M10.53 28.59A14.4 14.4 0 0 1 9.75 24c0-1.59.27-3.13.75-4.59l-7.98-6.2A23.9 23.9 0 0 0 0 24c0 3.88.93 7.55 2.56 10.78l7.97-6.19Z"/>
          <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.9-5.8l-7.74-6c-2.15 1.45-4.9 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48Z"/>
        </svg>
        {isLoading ? "Connecting..." : "Continue with Google"}
      </Button>
      {error && (
        <p aria-live="polite" className="mt-3 text-sm text-destructive" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
