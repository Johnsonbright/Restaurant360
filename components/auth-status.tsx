"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";

export function AuthStatus() {
  const [email, setEmail] = useState<string | null>(null);
  const [error, setError] = useState("");
  const router = useRouter();

  useEffect(() => {
    let active = true;
    let unsubscribe: (() => void) | undefined;

    async function initializeAuthStatus() {
      try {
        const client = createClient();
        const {
          data: { subscription },
        } = client.auth.onAuthStateChange((_event, session) => {
          setEmail(session?.user.email ?? null);
        });
        unsubscribe = () => subscription.unsubscribe();

        const { data, error: sessionError } = await client.auth.getSession();
        if (!active) return;
        if (sessionError) {
          setError(sessionError.message);
          return;
        }
        setEmail(data.session?.user.email ?? null);
      } catch (caught) {
        if (active) {
          setError(caught instanceof Error ? caught.message : "Unable to check authentication.");
        }
      }
    }

    void initializeAuthStatus();

    return () => {
      active = false;
      unsubscribe?.();
    };
  }, []);

  async function logOut() {
    setError("");

    try {
      const { error: signOutError } = await createClient().auth.signOut();
      if (signOutError) {
        setError(signOutError.message);
        return;
      }
      router.push("/login");
      router.refresh();
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "Unable to log out.");
    }
  }

  return (
    <>
      {email && (
        <details className="relative">
          <summary className="flex h-9 cursor-pointer list-none items-center gap-2 rounded-lg px-3 text-sm font-medium text-foreground hover:bg-muted">
            <span className="max-w-36 truncate">{email}</span>
            <span aria-hidden="true" className="text-primary">⌄</span>
          </summary>
          <div className="absolute right-0 top-full z-50 mt-2 w-52 rounded-xl border border-border bg-popover p-3 text-popover-foreground shadow-xl">
            <p className="truncate px-2 py-1 text-xs text-muted-foreground">{email}</p>
            <Button className="mt-2 w-full" type="button" variant="outline" size="sm" onClick={logOut}>
              Sign out
            </Button>
          </div>
        </details>
      )}
      {error && (
        <span className="text-xs text-destructive" role="alert">
          {error}
        </span>
      )}
    </>
  );
}
