import { FadeUp } from "@/components/animations";

export function PageTitle({ children }: Readonly<{ children: string }>) {
  return (
    <main className="mx-auto w-full max-w-7xl flex-1 px-5 py-14 md:py-20">
      <FadeUp>
        <h1 className="font-display text-4xl tracking-tight md:text-5xl">{children}</h1>
      </FadeUp>
    </main>
  );
}
