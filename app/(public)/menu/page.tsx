import Link from "next/link";
import { redirect } from "next/navigation";
import { connection } from "next/server";
import { Suspense } from "react";
import { MenuSearch } from "@/components/menu-search";
import { getPublicMenuData, MENU_PAGE_SIZE } from "@/lib/menu-data";
import { getMenuImage } from "@/lib/menu-images";
import { formatMenuLabel, formatNaira, type MenuCategory, type MenuItem } from "@/lib/menu";

export const metadata = {
  title: "Menu | Restaurant360",
  description: "Browse Restaurant360 meals, snacks, desserts, and drinks.",
};

function MenuCard({
  item,
  category,
  variations,
  addons,
}: Readonly<{
  item: MenuItem;
  category: MenuCategory | undefined;
  variations: Array<{
    id: string;
    name: string;
    description: string | null;
    price_adjustment: number;
  }>;
  addons: Array<{
    id: string;
    name: string;
    description: string | null;
    price: number;
  }>;
}>) {
  const categoryName = category?.name ?? "Main Meals";
  const image = getMenuImage(item.photo_url, item.name, categoryName);
  const backgroundImage = `linear-gradient(180deg, transparent 56%, rgb(11 20 36 / 75%) 100%), url("${image.src.replace(/["\\\n\r]/g, "%22")}")`;

  return (
    <article className="overflow-hidden rounded-2xl border border-border bg-card shadow-sm">
      <div
        aria-label={item.name}
        className="relative flex aspect-[16/10] items-end bg-muted bg-cover bg-center p-4"
        role="img"
        style={{ backgroundImage }}
      >
        <div className="flex w-full items-end justify-between gap-3">
          <div className="flex flex-wrap gap-2">
            {category && (
              <span className="rounded-full bg-background/90 px-3 py-1 text-xs font-medium text-foreground">
                {category.name}
              </span>
            )}
            {item.subcategory && (
              <span className="rounded-full bg-background/90 px-3 py-1 text-xs font-medium text-foreground">
                {item.subcategory}
              </span>
            )}
          </div>
          <span
            className={`shrink-0 rounded-full px-3 py-1 text-xs font-semibold ${
              item.is_available
                ? "bg-emerald-500/15 text-emerald-700 dark:text-emerald-300"
                : "bg-destructive/15 text-destructive"
            }`}
          >
            {item.is_available ? "Available" : "Unavailable"}
          </span>
        </div>
      </div>
      <div className="space-y-4 p-5">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h2 className="font-display text-2xl">{item.name}</h2>
            <p className="mt-1 text-xs text-muted-foreground">{item.reference}</p>
          </div>
          <p className="shrink-0 font-semibold text-primary">{formatNaira(item.price)}</p>
        </div>

        {item.description && (
          <p className="text-sm leading-6 text-muted-foreground">{item.description}</p>
        )}

        {(item.dietary_flags.length > 0 || item.contains_alcohol) && (
          <div className="flex flex-wrap gap-2" aria-label="Dietary information">
            {item.dietary_flags.map((flag) => (
              <span
                className="rounded-full border border-border px-2.5 py-1 text-xs text-muted-foreground"
                key={flag}
              >
                {formatMenuLabel(flag)}
              </span>
            ))}
            {item.contains_alcohol && (
              <span className="rounded-full border border-border px-2.5 py-1 text-xs text-muted-foreground">
                Contains alcohol
              </span>
            )}
          </div>
        )}

        {(variations.length > 0 || addons.length > 0) && (
          <div className="grid gap-3 border-t border-border pt-4 sm:grid-cols-2">
            {variations.length > 0 && (
              <div>
                <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                  Variations
                </h3>
                <ul className="mt-2 space-y-1.5 text-sm">
                  {variations.map((variation) => (
                    <li className="flex justify-between gap-2" key={variation.id}>
                      <span>
                        {variation.name}
                        {variation.description && (
                          <span className="block text-xs text-muted-foreground">
                            {variation.description}
                          </span>
                        )}
                      </span>
                      <span className="whitespace-nowrap text-muted-foreground">
                        {variation.price_adjustment > 0 ? "+" : ""}
                        {formatNaira(variation.price_adjustment)}
                      </span>
                    </li>
                  ))}
                </ul>
              </div>
            )}
            {addons.length > 0 && (
              <div>
                <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                  Add-ons
                </h3>
                <ul className="mt-2 space-y-1.5 text-sm">
                  {addons.map((addon) => (
                    <li className="flex justify-between gap-2" key={addon.id}>
                      <span>
                        {addon.name}
                        {addon.description && (
                          <span className="block text-xs text-muted-foreground">
                            {addon.description}
                          </span>
                        )}
                      </span>
                      <span className="whitespace-nowrap text-muted-foreground">
                        +{formatNaira(addon.price)}
                      </span>
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        )}

        {!item.photo_url && image.credit && image.creditUrl && (
          <a
            className="block text-xs text-muted-foreground underline-offset-4 hover:underline"
            href={image.creditUrl}
            rel="noreferrer"
            target="_blank"
          >
            Photo: {image.credit}
          </a>
        )}
        {!item.is_available && (
          <p className="border-t border-border pt-3 text-sm text-muted-foreground">
            This item is visible for reference but is not currently available to order.
          </p>
        )}
      </div>
    </article>
  );
}

function buildMenuHref({
  categoryId,
  search,
  page,
}: Readonly<{ categoryId: string; search: string; page: number }>) {
  const params = new URLSearchParams();
  if (categoryId) params.set("category", categoryId);
  if (search) params.set("q", search);
  if (page > 1) params.set("page", String(page));
  const query = params.toString();
  return query ? `/menu?${query}` : "/menu";
}

type MenuPageProps = Readonly<{
  searchParams: Promise<{
    category?: string | string[];
    q?: string | string[];
    page?: string | string[];
  }>;
}>;

async function MenuContent({
  searchParams,
}: MenuPageProps) {
  await connection();
  const params = await searchParams;
  const search = (typeof params.q === "string" ? params.q : "").trim().slice(0, 80);
  const categoryId = typeof params.category === "string" ? params.category : undefined;
  const requestedPage = Number.parseInt(
    typeof params.page === "string" ? params.page : "1",
    10,
  );
  const page =
    Number.isInteger(requestedPage) && requestedPage > 0 && requestedPage <= 10000
      ? requestedPage
      : 1;

  let menu: Awaited<ReturnType<typeof getPublicMenuData>>;
  try {
    menu = await getPublicMenuData({
      categoryId,
      search,
      page,
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "The menu could not be loaded.";

    return (
      <main className="mx-auto w-full max-w-7xl flex-1 px-5 py-14 md:py-20">
        <p className="mb-3 text-xs font-semibold uppercase tracking-[0.2em] text-primary">
          Restaurant360
        </p>
        <h1 className="font-display text-4xl md:text-5xl">Our Menu</h1>
        <div className="mt-8 rounded-xl border border-destructive/40 bg-destructive/5 p-5 text-sm" role="alert">
          {message}
        </div>
      </main>
    );
  }

  if (page > menu.totalPages) {
    redirect(
      buildMenuHref({
        categoryId: menu.selectedCategoryId,
        search,
        page: menu.totalPages,
      }),
    );
  }

  const categoryById = new Map(menu.categories.map((category) => [category.id, category]));
  const variationsByItemId = new Map<string, typeof menu.variations>();
  const addonsByItemId = new Map<string, typeof menu.addons>();
  for (const variation of menu.variations) {
    const grouped = variationsByItemId.get(variation.menu_item_id) ?? [];
    grouped.push(variation);
    variationsByItemId.set(variation.menu_item_id, grouped);
  }
  for (const addon of menu.addons) {
    const grouped = addonsByItemId.get(addon.menu_item_id) ?? [];
    grouped.push(addon);
    addonsByItemId.set(addon.menu_item_id, grouped);
  }

  const categoryName = menu.categories.find(
    (category) => category.id === menu.selectedCategoryId,
  )?.name;
  const firstResult =
    menu.totalItems === 0 ? 0 : (page - 1) * MENU_PAGE_SIZE + 1;
  const lastResult = Math.min(page * MENU_PAGE_SIZE, menu.totalItems);

  return (
    <main className="mx-auto w-full max-w-7xl flex-1 px-5 py-12 md:py-16">
      <section className="rounded-3xl border border-border bg-card px-6 py-8 md:px-10 md:py-12">
        <p className="mb-3 text-xs font-semibold uppercase tracking-[0.2em] text-primary">
          Fresh from our kitchen
        </p>
        <div className="flex flex-col justify-between gap-6 md:flex-row md:items-end">
          <div className="max-w-2xl">
            <h1 className="font-display text-4xl md:text-6xl">Our Menu</h1>
            <p className="mt-4 text-muted-foreground">
              Explore familiar Nigerian favourites, drinks, and seasonal specials.
              Prices are shown in Nigerian naira.
            </p>
          </div>
          <MenuSearch categoryId={menu.selectedCategoryId} initialValue={search} />
        </div>
      </section>

      <nav aria-label="Menu categories" className="mt-8 flex flex-wrap gap-2">
        <Link
          aria-current={!menu.selectedCategoryId ? "page" : undefined}
          className={`rounded-full border px-4 py-2 text-sm font-medium ${
            !menu.selectedCategoryId
              ? "border-primary bg-primary text-primary-foreground"
              : "border-border bg-card hover:border-primary"
          }`}
          href={buildMenuHref({ categoryId: "", search, page: 1 })}
        >
          All
        </Link>
        {menu.categories.map((category) => {
          const active = category.id === menu.selectedCategoryId;
          return (
            <Link
              aria-current={active ? "page" : undefined}
              className={`rounded-full border px-4 py-2 text-sm font-medium ${
                active
                  ? "border-primary bg-primary text-primary-foreground"
                  : "border-border bg-card hover:border-primary"
              }`}
              href={buildMenuHref({ categoryId: category.id, search, page: 1 })}
              key={category.id}
            >
              {category.name}
            </Link>
          );
        })}
      </nav>

      <div className="mt-8 flex flex-wrap items-center justify-between gap-3">
        <h2 className="font-display text-2xl md:text-3xl">
          {categoryName ?? "Everything on the menu"}
          {search && <span className="text-muted-foreground"> · “{search}”</span>}
        </h2>
        <p className="text-sm text-muted-foreground">
          {menu.totalItems === 0 ? "No items found" : `Showing ${firstResult}–${lastResult} of ${menu.totalItems}`}
        </p>
      </div>

      {menu.items.length > 0 ? (
        <div className="mt-5 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {menu.items.map((item) => (
            <MenuCard
              addons={addonsByItemId.get(item.id) ?? []}
              category={categoryById.get(item.category_id)}
              item={item}
              key={item.id}
              variations={variationsByItemId.get(item.id) ?? []}
            />
          ))}
        </div>
      ) : (
        <div className="mt-5 rounded-2xl border border-dashed border-border bg-card p-10 text-center">
          <h3 className="font-display text-2xl">No menu items match</h3>
          <p className="mt-2 text-sm text-muted-foreground">
            Try a different search or browse another category.
          </p>
        </div>
      )}

      {menu.totalPages > 1 && (
        <nav aria-label="Menu pages" className="mt-10 flex items-center justify-center gap-4">
          {page > 1 ? (
            <Link
              className="rounded-lg border border-border px-4 py-2 text-sm font-medium hover:border-primary"
              href={buildMenuHref({
                categoryId: menu.selectedCategoryId,
                search,
                page: page - 1,
              })}
            >
              Previous
            </Link>
          ) : (
            <span className="rounded-lg border border-border px-4 py-2 text-sm text-muted-foreground">
              Previous
            </span>
          )}
          <span className="text-sm text-muted-foreground">
            Page {page} of {menu.totalPages}
          </span>
          {page < menu.totalPages ? (
            <Link
              className="rounded-lg border border-border px-4 py-2 text-sm font-medium hover:border-primary"
              href={buildMenuHref({
                categoryId: menu.selectedCategoryId,
                search,
                page: page + 1,
              })}
            >
              Next
            </Link>
          ) : (
            <span className="rounded-lg border border-border px-4 py-2 text-sm text-muted-foreground">
              Next
            </span>
          )}
        </nav>
      )}
    </main>
  );
}

function MenuLoading() {
  return (
    <main className="mx-auto w-full max-w-7xl flex-1 px-5 py-12 md:py-16" aria-busy="true">
      <div className="h-56 animate-pulse rounded-3xl bg-muted" />
      <div className="mt-8 h-10 w-2/3 animate-pulse rounded-full bg-muted" />
      <div className="mt-8 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {Array.from({ length: 6 }, (_, index) => (
          <div className="h-96 animate-pulse rounded-2xl bg-muted" key={index} />
        ))}
      </div>
    </main>
  );
}

export default function MenuPage(props: MenuPageProps) {
  return (
    <Suspense fallback={<MenuLoading />}>
      <MenuContent searchParams={props.searchParams} />
    </Suspense>
  );
}
