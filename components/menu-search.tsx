"use client";

import { useCallback, useEffect, useRef, useState, useTransition } from "react";
import { useRouter } from "next/navigation";

export function MenuSearch({
  initialValue,
  categoryId,
}: Readonly<{ initialValue: string; categoryId: string }>) {
  const router = useRouter();
  const [value, setValue] = useState(initialValue);
  const [isPending, startTransition] = useTransition();
  const valueRef = useRef(initialValue);
  const lastCommittedValue = useRef(initialValue);

  const commitSearch = useCallback((search: string) => {
    const normalized = search.trim();
    if (normalized === lastCommittedValue.current) return;

    lastCommittedValue.current = normalized;
    const params = new URLSearchParams();
    if (categoryId) params.set("category", categoryId);
    if (normalized) params.set("q", normalized);
    const query = params.toString();

    startTransition(() => {
      router.replace(query ? `/menu?${query}` : "/menu", { scroll: false });
    });
  }, [categoryId, router]);

  useEffect(() => {
    if (
      initialValue !== lastCommittedValue.current &&
      valueRef.current === lastCommittedValue.current
    ) {
      valueRef.current = initialValue;
      lastCommittedValue.current = initialValue;
      setValue(initialValue);
    }
  }, [initialValue]);

  useEffect(() => {
    const normalized = value.trim();
    if (normalized === lastCommittedValue.current) return;

    if (!normalized) {
      commitSearch("");
      return;
    }

    const timeoutId = window.setTimeout(() => {
      commitSearch(normalized);
    }, 150);

    return () => window.clearTimeout(timeoutId);
  }, [value, categoryId, commitSearch]);

  return (
    <form
      action="/menu"
      className="flex w-full gap-2 md:max-w-md"
      onSubmit={(event) => {
        event.preventDefault();
        commitSearch(valueRef.current);
      }}
    >
      <label className="sr-only" htmlFor="menu-search">Search menu</label>
      <input
        autoComplete="off"
        className="min-w-0 flex-1 rounded-lg border border-input bg-background px-4 py-2 text-sm outline-none focus-visible:ring-2 focus-visible:ring-ring"
        id="menu-search"
        onChange={(event) => {
          valueRef.current = event.currentTarget.value;
          setValue(event.currentTarget.value);
        }}
        placeholder="Search dishes and drinks"
        type="search"
        value={value}
      />
      <button
        className="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground"
        type="submit"
      >
        Search
      </button>
      <span className="sr-only" role="status">
        {isPending ? "Updating menu results" : ""}
      </span>
    </form>
  );
}
