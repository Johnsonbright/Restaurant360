"use client";

import { useActionState, type ComponentProps, type ReactNode } from "react";
import { Button } from "@/components/ui/button";

export type MenuActionState = {
  error?: string;
  success?: string;
};

export type MenuAction = (
  state: MenuActionState,
  formData: FormData,
) => Promise<MenuActionState>;

const fieldClassName =
  "w-full rounded-lg border border-input bg-background px-3 py-2 text-sm text-foreground outline-none focus-visible:ring-2 focus-visible:ring-ring";

export function MenuField({
  label,
  htmlFor,
  children,
}: Readonly<{
  label: string;
  htmlFor: string;
  children: ReactNode;
}>) {
  return (
    <label className="grid gap-1.5 text-sm font-medium" htmlFor={htmlFor}>
      <span>{label}</span>
      {children}
    </label>
  );
}

export function MenuInput(props: ComponentProps<"input">) {
  return <input {...props} className={`${fieldClassName} ${props.className ?? ""}`} />;
}

export function MenuSelect(props: ComponentProps<"select">) {
  return <select {...props} className={`${fieldClassName} ${props.className ?? ""}`} />;
}

export function MenuTextarea(props: ComponentProps<"textarea">) {
  return (
    <textarea
      {...props}
      className={`${fieldClassName} min-h-20 resize-y ${props.className ?? ""}`}
    />
  );
}

export function MenuActionForm({
  action,
  submitLabel,
  className,
  children,
}: Readonly<{
  action: MenuAction;
  submitLabel: string;
  className?: string;
  children: ReactNode;
}>) {
  const [state, formAction, pending] = useActionState(action, {});

  return (
    <form action={formAction} className={className}>
      {children}
      <div className="flex flex-wrap items-center gap-3">
        <Button disabled={pending} type="submit">
          {pending ? "Saving…" : submitLabel}
        </Button>
        {state.error && (
          <p className="text-sm text-destructive" role="alert">
            {state.error}
          </p>
        )}
        {state.success && (
          <p className="text-sm text-primary" role="status">
            {state.success}
          </p>
        )}
      </div>
    </form>
  );
}

export const menuCheckboxClassName =
  "size-4 rounded border-input accent-primary focus-visible:ring-2 focus-visible:ring-ring";
