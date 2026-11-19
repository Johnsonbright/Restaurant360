export function SiteFooter() {
  return (
    <footer className="mt-auto border-t border-border bg-card">
      <div className="mx-auto grid max-w-7xl gap-10 px-5 py-12 sm:grid-cols-2 lg:grid-cols-4">
        <div>
          <p className="font-display text-2xl text-foreground">Restaurant360</p>
          <p className="mt-3 max-w-xs text-sm text-muted-foreground">
            A warm welcome, thoughtfully prepared. Sample copy for the restaurant
            brand.
          </p>
        </div>
        <div>
          <h2 className="text-sm font-semibold tracking-wide text-foreground">
            Opening hours
          </h2>
          <p className="mt-3 text-sm text-muted-foreground">Monday–Thursday · 11am–10pm</p>
          <p className="text-sm text-muted-foreground">Friday–Sunday · 11am–11pm</p>
        </div>
        <div>
          <h2 className="text-sm font-semibold tracking-wide text-foreground">Find us</h2>
          <p className="mt-3 text-sm text-muted-foreground">Address to be confirmed</p>
          <p className="text-sm text-muted-foreground">City, Country</p>
        </div>
        <div>
          <h2 className="text-sm font-semibold tracking-wide text-foreground">Contact</h2>
          <p className="mt-3 text-sm text-muted-foreground">hello@example.test</p>
          <p className="text-sm text-muted-foreground">+000 000 0000</p>
        </div>
      </div>
      <div className="border-t border-border">
        <p className="mx-auto max-w-7xl px-5 py-4 text-xs text-muted-foreground">
          Sample contact details · Replace before launch
        </p>
      </div>
    </footer>
  );
}
