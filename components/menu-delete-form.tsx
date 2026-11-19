"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import type { MenuAction } from "@/components/menu-action-form";

export function MenuDeleteForm({
  action,
  itemId,
  itemName,
}: Readonly<{
  action: MenuAction;
  itemId: string;
  itemName: string;
}>) {
  const [state, formAction, pending] = useActionState(action, {});

  return (
    <form
      action={formAction}
      className="flex flex-wrap items-center gap-3"
      onSubmit={(event) => {
        if (!window.confirm(`Permanently delete "${itemName}"?`)) {
          event.preventDefault();
        }
      }}
    >
      <input name="itemId" type="hidden" value={itemId} />
      <Button disabled={pending} type="submit" variant="destructive">
        {pending ? "Deleting…" : "Delete item"}
      </Button>
      {state.error && (
        <p className="text-sm text-destructive" role="alert">{state.error}</p>
      )}
      {state.success && (
        <p className="text-sm text-primary" role="status">{state.success}</p>
      )}
    </form>
  );
}
