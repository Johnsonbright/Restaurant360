import Link from "next/link";
import { redirect } from "next/navigation";
import { connection } from "next/server";
import { Suspense } from "react";
import { MenuDeleteForm } from "@/components/menu-delete-form";
import { MenuPhotoInput } from "@/components/menu-photo-input";
import {
  MenuActionForm,
  MenuField,
  MenuInput,
  MenuSelect,
  MenuTextarea,
  menuCheckboxClassName,
} from "@/components/menu-action-form";
import {
  deleteMenuItemAction,
  saveAddonAction,
  saveCategoryAction,
  saveMenuItemAction,
  saveVariationAction,
} from "@/app/(admin)/admin/menu/actions";
import { createClient } from "@/lib/supabase/server";
import {
  MENU_CATEGORY_NAMES,
  MENU_DIETARY_FLAGS,
  formatMenuLabel,
  formatNaira,
  type MenuAddon,
  type MenuCategory,
  type MenuItem,
  type MenuVariation,
} from "@/lib/menu";
import { getMenuImage } from "@/lib/menu-images";

const PAGE_SIZE = 20;

export const instant = false;

type MenuHistoryRow = {
  id: string;
  menu_item_reference: string;
  snapshot: unknown;
  created_at: string;
};

function ErrorPanel({ message }: Readonly<{ message: string }>) {
  return (
    <div
      className="rounded-xl border border-destructive/40 bg-destructive/5 p-4 text-sm"
      role="alert"
    >
      {message}
    </div>
  );
}

function CheckboxField({
  id,
  name,
  label,
  defaultChecked,
}: Readonly<{
  id: string;
  name: string;
  label: string;
  defaultChecked: boolean;
}>) {
  return (
    <label className="flex items-center gap-2 text-sm">
      <input
        className={menuCheckboxClassName}
        defaultChecked={defaultChecked}
        id={id}
        name={name}
        type="checkbox"
      />
      {label}
    </label>
  );
}

function CategoryFields({
  category,
}: Readonly<{ category?: MenuCategory }>) {
  const suffix = category?.id ?? "new";
  return (
    <>
      {category && <input name="categoryId" type="hidden" value={category.id} />}
      <MenuField htmlFor={`category-name-${suffix}`} label="Category">
        <MenuSelect
          defaultValue={category?.name ?? MENU_CATEGORY_NAMES[0]}
          id={`category-name-${suffix}`}
          name="name"
        >
          {MENU_CATEGORY_NAMES.map((name) => (
            <option key={name} value={name}>{name}</option>
          ))}
        </MenuSelect>
      </MenuField>
      <MenuField htmlFor={`category-description-${suffix}`} label="Description">
        <MenuTextarea
          defaultValue={category?.description ?? ""}
          id={`category-description-${suffix}`}
          name="description"
        />
      </MenuField>
      <MenuField htmlFor={`category-order-${suffix}`} label="Display order">
        <MenuInput
          defaultValue={category?.display_order ?? 0}
          id={`category-order-${suffix}`}
          min={0}
          name="displayOrder"
          required
          type="number"
        />
      </MenuField>
      <CheckboxField
        defaultChecked={category?.is_active ?? true}
        id={`category-active-${suffix}`}
        label="Active"
        name="isActive"
      />
    </>
  );
}

function MenuItemFields({
  item,
  categories,
}: Readonly<{
  item?: MenuItem;
  categories: MenuCategory[];
}>) {
  const suffix = item?.id ?? "new";
  const categoryName =
    categories.find((category) => category.id === item?.category_id)?.name ?? "Main Meals";
  return (
    <div className="space-y-6">
      {item && <input name="itemId" type="hidden" value={item.id} />}
      <section className="space-y-4">
        <h3 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
          Item details
        </h3>
        <div className="grid gap-4 sm:grid-cols-2">
          <MenuField htmlFor={`item-reference-${suffix}`} label="Reference">
            <MenuInput
              defaultValue={item?.reference ?? ""}
              id={`item-reference-${suffix}`}
              maxLength={64}
              name="reference"
              placeholder="MI-MAIN-001"
              required
            />
          </MenuField>
          <MenuField htmlFor={`item-name-${suffix}`} label="Name">
            <MenuInput
              defaultValue={item?.name ?? ""}
              id={`item-name-${suffix}`}
              maxLength={120}
              name="name"
              required
            />
          </MenuField>
          <MenuField htmlFor={`item-category-${suffix}`} label="Category">
            <MenuSelect
              defaultValue={item?.category_id ?? categories[0]?.id ?? ""}
              id={`item-category-${suffix}`}
              name="categoryId"
              required
            >
              {categories.map((category) => (
                <option key={category.id} value={category.id}>{category.name}</option>
              ))}
            </MenuSelect>
          </MenuField>
          <MenuField htmlFor={`item-subcategory-${suffix}`} label="Subcategory">
            <MenuInput
              defaultValue={item?.subcategory ?? ""}
              id={`item-subcategory-${suffix}`}
              maxLength={120}
              name="subcategory"
              placeholder="Hausa, Yoruba, Igbo…"
            />
          </MenuField>
        </div>
      </section>

      <section className="space-y-4 border-t border-border pt-5">
        <h3 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
          Pricing and display
        </h3>
        <div className="grid max-w-2xl gap-4 sm:grid-cols-2">
          <MenuField htmlFor={`item-price-${suffix}`} label="Price (NGN)">
            <MenuInput
              defaultValue={item?.price ?? ""}
              id={`item-price-${suffix}`}
              min={0}
              name="price"
              required
              step="0.01"
              type="number"
            />
          </MenuField>
          <MenuField htmlFor={`item-order-${suffix}`} label="Display order">
            <MenuInput
              defaultValue={item?.display_order ?? 0}
              id={`item-order-${suffix}`}
              min={0}
              name="displayOrder"
              required
              type="number"
            />
          </MenuField>
        </div>
      </section>

      <section className="space-y-4 border-t border-border pt-5">
        <h3 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
          Menu photo
        </h3>
        <MenuPhotoInput
          categoryName={categoryName}
          initialPhotoUrl={item?.photo_url ?? ""}
          itemName={item?.name ?? "Menu item"}
          suffix={suffix}
        />
      </section>

      <section className="space-y-4 border-t border-border pt-5">
        <h3 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
          Additional information
        </h3>
        <MenuField htmlFor={`item-ingredients-${suffix}`} label="Ingredient information">
          <MenuInput
            defaultValue={item?.ingredient_information ?? ""}
            id={`item-ingredients-${suffix}`}
            name="ingredientInformation"
          />
        </MenuField>
        <MenuField htmlFor={`item-description-${suffix}`} label="Description">
          <MenuTextarea
            defaultValue={item?.description ?? ""}
            id={`item-description-${suffix}`}
            maxLength={2000}
            name="description"
          />
        </MenuField>
      </section>

      <section className="space-y-3 border-t border-border pt-5">
        <h3 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
          Dietary and availability
        </h3>
        <div className="flex flex-wrap gap-4">
          {MENU_DIETARY_FLAGS.map((flag) => (
          <CheckboxField
            defaultChecked={item?.dietary_flags.includes(flag) ?? false}
            id={`item-${flag}-${suffix}`}
            key={flag}
            label={formatMenuLabel(flag)}
            name="dietaryFlags"
          />
          ))}
          <CheckboxField
            defaultChecked={item?.contains_alcohol ?? false}
            id={`item-alcohol-${suffix}`}
            label="Contains alcohol"
            name="containsAlcohol"
          />
          <CheckboxField
            defaultChecked={item?.is_available ?? true}
            id={`item-available-${suffix}`}
            label="Available"
            name="isAvailable"
          />
        </div>
      </section>
    </div>
  );
}

function VariationForm({
  item,
  variation,
}: Readonly<{ item: MenuItem; variation?: MenuVariation }>) {
  const suffix = variation?.id ?? `${item.id}-new`;
  return (
    <MenuActionForm
      action={saveVariationAction}
      className="grid gap-3 rounded-lg border border-border p-3"
      submitLabel={variation ? "Save variation" : "Add variation"}
    >
      {variation && <input name="variationId" type="hidden" value={variation.id} />}
      <input name="menuItemId" type="hidden" value={item.id} />
      <MenuField htmlFor={`variation-name-${suffix}`} label="Name">
        <MenuInput
          defaultValue={variation?.name ?? ""}
          id={`variation-name-${suffix}`}
          name="name"
          required
        />
      </MenuField>
      <MenuField htmlFor={`variation-description-${suffix}`} label="Description">
        <MenuInput
          defaultValue={variation?.description ?? ""}
          id={`variation-description-${suffix}`}
          name="description"
        />
      </MenuField>
      <MenuField htmlFor={`variation-price-${suffix}`} label="Price adjustment (NGN)">
        <MenuInput
          defaultValue={variation?.price_adjustment ?? 0}
          id={`variation-price-${suffix}`}
          name="priceAdjustment"
          required
          step="0.01"
          type="number"
        />
      </MenuField>
      <CheckboxField
        defaultChecked={variation?.is_available ?? true}
        id={`variation-available-${suffix}`}
        label="Available"
        name="isAvailable"
      />
    </MenuActionForm>
  );
}

function AddonForm({
  item,
  addon,
}: Readonly<{ item: MenuItem; addon?: MenuAddon }>) {
  const suffix = addon?.id ?? `${item.id}-new`;
  return (
    <MenuActionForm
      action={saveAddonAction}
      className="grid gap-3 rounded-lg border border-border p-3"
      submitLabel={addon ? "Save add-on" : "Add add-on"}
    >
      {addon && <input name="addonId" type="hidden" value={addon.id} />}
      <input name="menuItemId" type="hidden" value={item.id} />
      <MenuField htmlFor={`addon-name-${suffix}`} label="Name">
        <MenuInput
          defaultValue={addon?.name ?? ""}
          id={`addon-name-${suffix}`}
          name="name"
          required
        />
      </MenuField>
      <MenuField htmlFor={`addon-description-${suffix}`} label="Description">
        <MenuInput
          defaultValue={addon?.description ?? ""}
          id={`addon-description-${suffix}`}
          name="description"
        />
      </MenuField>
      <MenuField htmlFor={`addon-price-${suffix}`} label="Price (NGN)">
        <MenuInput
          defaultValue={addon?.price ?? 0}
          id={`addon-price-${suffix}`}
          min={0}
          name="price"
          required
          step="0.01"
          type="number"
        />
      </MenuField>
      <CheckboxField
        defaultChecked={addon?.is_available ?? true}
        id={`addon-available-${suffix}`}
        label="Available"
        name="isAvailable"
      />
    </MenuActionForm>
  );
}

function HistorySummary({ row }: Readonly<{ row: MenuHistoryRow }>) {
  const snapshot =
    row.snapshot !== null && typeof row.snapshot === "object"
      ? row.snapshot as Record<string, unknown>
      : {};
  const name = typeof snapshot.name === "string" ? snapshot.name : row.menu_item_reference;
  const price = typeof snapshot.price === "number" ? formatNaira(snapshot.price) : "Price not recorded";
  const available =
    typeof snapshot.is_available === "boolean"
      ? snapshot.is_available ? "Available" : "Unavailable"
      : "Availability not recorded";

  return (
    <li className="flex flex-wrap justify-between gap-2 border-b border-border py-3 last:border-0">
      <span className="font-medium">{name} <span className="text-muted-foreground">({row.menu_item_reference})</span></span>
      <span className="text-sm text-muted-foreground">
        {price} · {available} · {new Date(row.created_at).toLocaleString("en-NG")}
      </span>
    </li>
  );
}

function buildAdminMenuHref({
  categoryId,
  search,
  page,
}: Readonly<{ categoryId: string; search: string; page: number }>) {
  const params = new URLSearchParams();
  if (categoryId) params.set("category", categoryId);
  if (search) params.set("q", search);
  if (page > 1) params.set("page", String(page));
  const query = params.toString();
  return query ? `/admin/menu?${query}` : "/admin/menu";
}

type AdminMenuPageProps = Readonly<{
  searchParams: Promise<{
    category?: string | string[];
    q?: string | string[];
    page?: string | string[];
  }>;
}>;

async function AdminMenuContent({
  searchParams,
}: AdminMenuPageProps) {
  await connection();
  const params = await searchParams;
  const search = (typeof params.q === "string" ? params.q : "").trim().slice(0, 80);
  const categoryId = typeof params.category === "string" ? params.category : undefined;
  const parsedPage = Number.parseInt(
    typeof params.page === "string" ? params.page : "1",
    10,
  );
  const page =
    Number.isInteger(parsedPage) && parsedPage > 0 && parsedPage <= 10000
      ? parsedPage
      : 1;
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError) {
    return (
      <main className="mx-auto w-full max-w-7xl flex-1 space-y-6 px-5 py-10 md:px-8">
        <h1 className="font-display text-4xl">Menu management</h1>
        <ErrorPanel message={`Could not verify your session: ${userError.message}`} />
      </main>
    );
  }

  if (!user) redirect("/login");

  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .maybeSingle();
  if (profileError) {
    return (
      <main className="mx-auto w-full max-w-7xl flex-1 space-y-6 px-5 py-10 md:px-8">
        <h1 className="font-display text-4xl">Menu management</h1>
        <ErrorPanel message={`Could not verify your staff role: ${profileError.message}`} />
      </main>
    );
  }

  if (profile?.role !== "manager" && profile?.role !== "admin") redirect("/unauthorized");

  const { data: categoryRows, error: categoryError } = await supabase
    .from("categories")
    .select("id, name, description, display_order, is_active")
    .order("display_order")
    .order("name");
  if (categoryError) {
    return (
      <main className="mx-auto w-full max-w-7xl flex-1 space-y-6 px-5 py-10 md:px-8">
        <h1 className="font-display text-4xl">Menu management</h1>
        <ErrorPanel message={`Could not load categories: ${categoryError.message}`} />
      </main>
    );
  }

  const categories = (categoryRows ?? []) as MenuCategory[];
  const selectedCategory = categories.find((category) => category.id === categoryId);
  const offset = (page - 1) * PAGE_SIZE;
  let itemsQuery = supabase
    .from("menu_items")
    .select(
      "id, reference, category_id, name, description, subcategory, price, photo_url, ingredient_information, dietary_flags, contains_alcohol, is_available, display_order",
      { count: "exact" },
    )
    .order("display_order")
    .order("name")
    .range(offset, offset + PAGE_SIZE - 1);
  if (selectedCategory) itemsQuery = itemsQuery.eq("category_id", selectedCategory.id);
  if (search) itemsQuery = itemsQuery.ilike("name", `%${search}%`);

  const [itemResult, historyResult] = await Promise.all([
    itemsQuery,
    supabase
      .from("menu_item_history")
      .select("id, menu_item_reference, snapshot, created_at")
      .order("created_at", { ascending: false })
      .limit(20),
  ]);
  if (itemResult.error) {
    return (
      <main className="mx-auto w-full max-w-7xl flex-1 space-y-6 px-5 py-10 md:px-8">
        <h1 className="font-display text-4xl">Menu management</h1>
        <ErrorPanel message={`Could not load menu items: ${itemResult.error.message}`} />
      </main>
    );
  }
  if (historyResult.error) {
    return (
      <main className="mx-auto w-full max-w-7xl flex-1 space-y-6 px-5 py-10 md:px-8">
        <h1 className="font-display text-4xl">Menu management</h1>
        <ErrorPanel message={`Could not load menu history: ${historyResult.error.message}`} />
      </main>
    );
  }

  const items = (itemResult.data ?? []) as MenuItem[];
  const totalItems = itemResult.count ?? 0;
  const totalPages = Math.max(1, Math.ceil(totalItems / PAGE_SIZE));
  if (page > totalPages) {
    redirect(
      buildAdminMenuHref({
        categoryId: selectedCategory?.id ?? "",
        search,
        page: totalPages,
      }),
    );
  }
  const itemIds = items.map((item) => item.id);
  let variations: MenuVariation[] = [];
  let addons: MenuAddon[] = [];
  if (itemIds.length > 0) {
    const [variationResult, addonResult] = await Promise.all([
      supabase
        .from("menu_variations")
        .select("id, menu_item_id, name, description, price_adjustment, is_available")
        .in("menu_item_id", itemIds)
        .order("name"),
      supabase
        .from("menu_addons")
        .select("id, menu_item_id, name, description, price, is_available")
        .in("menu_item_id", itemIds)
        .order("name"),
    ]);
    if (variationResult.error) {
      return (
        <main className="mx-auto w-full max-w-7xl flex-1 space-y-6 px-5 py-10 md:px-8">
          <h1 className="font-display text-4xl">Menu management</h1>
          <ErrorPanel message={`Could not load variations: ${variationResult.error.message}`} />
        </main>
      );
    }
    if (addonResult.error) {
      return (
        <main className="mx-auto w-full max-w-7xl flex-1 space-y-6 px-5 py-10 md:px-8">
          <h1 className="font-display text-4xl">Menu management</h1>
          <ErrorPanel message={`Could not load add-ons: ${addonResult.error.message}`} />
        </main>
      );
    }
    variations = (variationResult.data ?? []) as MenuVariation[];
    addons = (addonResult.data ?? []) as MenuAddon[];
  }

  const variationGroups = new Map<string, MenuVariation[]>();
  const addonGroups = new Map<string, MenuAddon[]>();
  for (const variation of variations) {
    const group = variationGroups.get(variation.menu_item_id) ?? [];
    group.push(variation);
    variationGroups.set(variation.menu_item_id, group);
  }
  for (const addon of addons) {
    const group = addonGroups.get(addon.menu_item_id) ?? [];
    group.push(addon);
    addonGroups.set(addon.menu_item_id, group);
  }

  return (
    <main className="mx-auto w-full max-w-7xl flex-1 space-y-8 px-5 py-8 md:px-8 md:py-10">
      <header className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="mb-2 text-xs font-semibold uppercase tracking-[0.2em] text-primary">
            Catalog workspace
          </p>
          <h1 className="font-display text-4xl md:text-5xl">Menu management</h1>
          <p className="mt-2 text-sm text-muted-foreground">
            Update categories, dishes, availability, variations, and add-ons.
          </p>
        </div>
        <Link className="text-sm font-medium text-primary underline-offset-4 hover:underline" href="/menu">
          View public menu
        </Link>
      </header>

      <section className="grid gap-5 xl:grid-cols-[minmax(0,1.4fr)_minmax(20rem,1fr)]">
        <div className="rounded-2xl border border-border bg-card p-5 md:p-6">
          <h2 className="font-display text-2xl">Add menu item</h2>
          {categories.length === 0 ? (
            <p className="mt-3 text-sm text-muted-foreground">Add a category before creating menu items.</p>
          ) : (
            <MenuActionForm
              action={saveMenuItemAction}
              className="mt-5 grid gap-4"
              submitLabel="Add menu item"
            >
              <MenuItemFields categories={categories} />
            </MenuActionForm>
          )}
        </div>

        <div className="rounded-2xl border border-border bg-card p-5 md:p-6">
          <h2 className="font-display text-2xl">Add category</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            Category names are the six configured menu sections.
          </p>
          <MenuActionForm
            action={saveCategoryAction}
            className="mt-5 grid gap-4"
            submitLabel="Add category"
          >
            <CategoryFields />
          </MenuActionForm>
        </div>
      </section>

      <section className="rounded-2xl border border-border bg-card p-5 md:p-6">
        <h2 className="font-display text-2xl">Categories</h2>
        {categories.length > 0 ? (
          <div className="mt-4 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {categories.map((category) => (
              <MenuActionForm
                action={saveCategoryAction}
                className="grid content-start gap-3 rounded-xl border border-border p-4"
                key={category.id}
                submitLabel="Save category"
              >
                <CategoryFields category={category} />
              </MenuActionForm>
            ))}
          </div>
        ) : (
          <p className="mt-3 text-sm text-muted-foreground">No categories have been created yet.</p>
        )}
      </section>

      <section className="space-y-4">
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div>
            <h2 className="font-display text-3xl">Menu items</h2>
            <p className="mt-1 text-sm text-muted-foreground">
              {totalItems} total · {selectedCategory?.name ?? "All categories"}
            </p>
          </div>
          <form action="/admin/menu" className="flex w-full gap-2 md:max-w-xl">
            {selectedCategory && (
              <input name="category" type="hidden" value={selectedCategory.id} />
            )}
            <label className="sr-only" htmlFor="admin-menu-search">Search menu items</label>
            <MenuInput
              defaultValue={search}
              id="admin-menu-search"
              name="q"
              placeholder="Search menu item names"
              type="search"
            />
            <button className="rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground" type="submit">
              Search
            </button>
          </form>
        </div>

        <nav aria-label="Filter menu items by category" className="flex flex-wrap gap-2">
          <Link
            className={`rounded-full border px-3 py-1.5 text-sm ${
              !selectedCategory ? "border-primary bg-primary text-primary-foreground" : "border-border bg-card"
            }`}
            href={buildAdminMenuHref({ categoryId: "", search, page: 1 })}
          >
            All
          </Link>
          {categories.map((category) => (
            <Link
              className={`rounded-full border px-3 py-1.5 text-sm ${
                selectedCategory?.id === category.id
                  ? "border-primary bg-primary text-primary-foreground"
                  : "border-border bg-card"
              }`}
              href={buildAdminMenuHref({ categoryId: category.id, search, page: 1 })}
              key={category.id}
            >
              {category.name}
            </Link>
          ))}
        </nav>

        {items.length > 0 ? (
          <div className="space-y-4">
            {items.map((item) => {
              const category = categories.find((entry) => entry.id === item.category_id);
              const image = getMenuImage(item.photo_url, item.name, category?.name ?? "Main Meals");
              return (
                <article className="rounded-2xl border border-border bg-card p-5 md:p-6" key={item.id}>
                  <div className="flex flex-wrap items-start gap-4">
                    <div
                      aria-label={`${item.name} photo`}
                      className="h-20 w-28 shrink-0 rounded-lg border border-border bg-muted bg-cover bg-center"
                      role="img"
                      style={{
                        backgroundImage: `url("${image.src.replace(/["\\\n\r]/g, "%22")}")`,
                      }}
                    />
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-start justify-between gap-3">
                        <div>
                          <h3 className="font-display text-2xl">{item.name}</h3>
                          <p className="mt-1 text-sm text-muted-foreground">
                            {item.reference} · {category?.name ?? "Uncategorized"}
                            {item.subcategory ? ` · ${item.subcategory}` : ""}
                          </p>
                        </div>
                        <div className="flex items-center gap-3">
                          <span className="font-semibold">{formatNaira(item.price)}</span>
                          <span className={`rounded-full px-3 py-1 text-xs font-semibold ${
                            item.is_available
                              ? "bg-emerald-500/15 text-emerald-700 dark:text-emerald-300"
                              : "bg-destructive/15 text-destructive"
                          }`}>
                            {item.is_available ? "Available" : "Unavailable"}
                          </span>
                        </div>
                      </div>
                      <p className="mt-2 text-xs text-muted-foreground">
                        {item.photo_url ? image.label : `Automatic photo: ${image.label}`}
                      </p>
                    </div>
                  </div>

                  <details className="mt-5 rounded-xl border border-border">
                    <summary className="cursor-pointer px-4 py-3 text-sm font-semibold">
                      Edit menu item
                    </summary>
                    <div className="border-t border-border p-4">
                      <MenuActionForm
                        action={saveMenuItemAction}
                        className="grid gap-4"
                        submitLabel="Save menu item"
                      >
                        <MenuItemFields categories={categories} item={item} />
                      </MenuActionForm>
                    </div>
                  </details>

                  <div className="mt-4 border-t border-border pt-4">
                    <p className="mb-2 text-sm text-muted-foreground">
                      Permanent deletion is blocked when an item is used in a recipe or past order.
                    </p>
                    <MenuDeleteForm
                      action={deleteMenuItemAction}
                      itemId={item.id}
                      itemName={item.name}
                    />
                  </div>

                  <div className="mt-4 grid gap-4 xl:grid-cols-2">
                    <details className="rounded-xl border border-border">
                      <summary className="cursor-pointer px-4 py-3 text-sm font-semibold">
                        Variations ({variationGroups.get(item.id)?.length ?? 0})
                      </summary>
                      <div className="grid gap-3 border-t border-border p-4">
                        {variationGroups.get(item.id)?.map((variation) => (
                          <VariationForm item={item} key={variation.id} variation={variation} />
                        ))}
                        <VariationForm item={item} />
                      </div>
                    </details>
                    <details className="rounded-xl border border-border">
                      <summary className="cursor-pointer px-4 py-3 text-sm font-semibold">
                        Add-ons ({addonGroups.get(item.id)?.length ?? 0})
                      </summary>
                      <div className="grid gap-3 border-t border-border p-4">
                        {addonGroups.get(item.id)?.map((addon) => (
                          <AddonForm addon={addon} item={item} key={addon.id} />
                        ))}
                        <AddonForm item={item} />
                      </div>
                    </details>
                  </div>
                </article>
              );
            })}
          </div>
        ) : (
          <div className="rounded-2xl border border-dashed border-border bg-card p-8 text-center">
            <p className="font-medium">No menu items found</p>
            <p className="mt-1 text-sm text-muted-foreground">
              Adjust the search or add a new menu item above.
            </p>
          </div>
        )}

        {totalPages > 1 && (
          <nav aria-label="Menu management pages" className="flex items-center justify-center gap-4">
            {page > 1 ? (
              <Link
                className="rounded-lg border border-border px-4 py-2 text-sm hover:border-primary"
                href={buildAdminMenuHref({
                  categoryId: selectedCategory?.id ?? "",
                  search,
                  page: page - 1,
                })}
              >
                Previous
              </Link>
            ) : <span className="rounded-lg border border-border px-4 py-2 text-sm text-muted-foreground">Previous</span>}
            <span className="text-sm text-muted-foreground">Page {page} of {totalPages}</span>
            {page < totalPages ? (
              <Link
                className="rounded-lg border border-border px-4 py-2 text-sm hover:border-primary"
                href={buildAdminMenuHref({
                  categoryId: selectedCategory?.id ?? "",
                  search,
                  page: page + 1,
                })}
              >
                Next
              </Link>
            ) : <span className="rounded-lg border border-border px-4 py-2 text-sm text-muted-foreground">Next</span>}
          </nav>
        )}
      </section>

      <section className="rounded-2xl border border-border bg-card p-5 md:p-6">
        <h2 className="font-display text-2xl">Recent menu changes</h2>
        <p className="mt-1 text-sm text-muted-foreground">
          Latest 20 menu item snapshots recorded automatically after changes.
        </p>
        {historyResult.data && historyResult.data.length > 0 ? (
          <ul className="mt-3">
            {(historyResult.data as MenuHistoryRow[]).map((row) => (
              <HistorySummary key={row.id} row={row} />
            ))}
          </ul>
        ) : (
          <p className="mt-3 text-sm text-muted-foreground">No menu changes have been recorded yet.</p>
        )}
      </section>
    </main>
  );
}

function AdminMenuLoading() {
  return (
    <main className="mx-auto w-full max-w-7xl flex-1 space-y-6 px-5 py-10 md:px-8" aria-busy="true">
      <div className="h-14 w-1/2 animate-pulse rounded-lg bg-muted" />
      <div className="h-44 animate-pulse rounded-2xl bg-muted" />
      <div className="h-96 animate-pulse rounded-2xl bg-muted" />
    </main>
  );
}

export default function AdminMenuPage(props: AdminMenuPageProps) {
  return (
    <Suspense fallback={<AdminMenuLoading />}>
      <AdminMenuContent searchParams={props.searchParams} />
    </Suspense>
  );
}
