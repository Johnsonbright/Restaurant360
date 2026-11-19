"use server";

import { redirect } from "next/navigation";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

export type AuthState = {
  error?: string;
  message?: string;
};

const credentialsSchema = z.object({
  email: z.string().trim().email("Enter a valid email address."),
  password: z.string().min(8, "Password must be at least 8 characters."),
});

const registrationSchema = credentialsSchema.extend({
  fullName: z.string().trim().min(1, "Enter your full name."),
});

function getString(formData: FormData, key: string) {
  const value = formData.get(key);
  return typeof value === "string" ? value : "";
}

function validationError(error: z.ZodError) {
  return error.issues[0]?.message ?? "Check the information you entered.";
}

export async function loginAction(
  _previousState: AuthState,
  formData: FormData,
): Promise<AuthState> {
  const parsed = credentialsSchema.safeParse({
    email: getString(formData, "email"),
    password: getString(formData, "password"),
  });

  if (!parsed.success) {
    return { error: validationError(parsed.error) };
  }

  let signInError: string | null;
  try {
    const supabase = await createClient();
    const { error } = await supabase.auth.signInWithPassword(parsed.data);
    signInError = error?.message ?? null;
  } catch (caught) {
    return {
      error:
        caught instanceof Error
          ? caught.message
          : "Login is unavailable. Please try again.",
    };
  }

  if (signInError) {
    return { error: signInError };
  }

  redirect("/");
}

export async function registerAction(
  _previousState: AuthState,
  formData: FormData,
): Promise<AuthState> {
  const parsed = registrationSchema.safeParse({
    email: getString(formData, "email"),
    password: getString(formData, "password"),
    fullName: getString(formData, "fullName"),
  });

  if (!parsed.success) {
    return { error: validationError(parsed.error) };
  }

  let signUpResult;
  try {
    const supabase = await createClient();
    signUpResult = await supabase.auth.signUp({
      email: parsed.data.email,
      password: parsed.data.password,
      options: { data: { full_name: parsed.data.fullName } },
    });
  } catch (caught) {
    return {
      error:
        caught instanceof Error
          ? caught.message
          : "Registration is unavailable. Please try again.",
    };
  }

  if (signUpResult.error) {
    return { error: signUpResult.error.message };
  }

  if (signUpResult.data.session) {
    redirect("/");
  }

  return {
    message: "Account created. Check your email to confirm your account, then log in.",
  };
}
