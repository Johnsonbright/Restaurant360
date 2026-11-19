import Link from "next/link";

export default function UnauthorizedPage() {
  return (
    <main className="mx-auto w-full max-w-3xl flex-1 px-5 py-12">
      <h1 className="text-3xl font-semibold tracking-tight">Unauthorized</h1>
      <p className="mt-3 text-muted-foreground">
        Your account does not have permission to view this page.
      </p>
      <Link className="mt-5 inline-block text-primary underline" href="/">
        Return home
      </Link>
    </main>
  );
}
