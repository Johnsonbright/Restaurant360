import { createClient } from "@/lib/supabase/server";
import type { MenuAddon, MenuCategory, MenuItem, MenuVariation } from "@/lib/menu";

export const MENU_PAGE_SIZE = 18;

export async function getPublicMenuData({
  categoryId,
  search,
  page,
}: Readonly<{
  categoryId?: string;
  search?: string;
  page: number;
}>) {
  const supabase = await createClient();
  const categoriesRequest = supabase
    .from("categories")
    .select("id, name, description, display_order, is_active")
    .eq("is_active", true)
    .order("display_order")
    .order("name");

  const firstItem = (page - 1) * MENU_PAGE_SIZE;
  let itemQuery = supabase
    .from("menu_items")
    .select(
      "id, reference, category_id, name, description, subcategory, price, photo_url, ingredient_information, dietary_flags, contains_alcohol, is_available, display_order",
      { count: "exact" },
    )
    .order("display_order")
    .order("name")
    .range(firstItem, firstItem + MENU_PAGE_SIZE - 1);

  if (categoryId) {
    itemQuery = itemQuery.eq("category_id", categoryId);
  }
  if (search) {
    itemQuery = itemQuery.ilike("name", `%${search}%`);
  }

  const [categoryResult, itemResult] = await Promise.all([categoriesRequest, itemQuery]);
  if (categoryResult.error) {
    throw new Error(`Could not load menu categories: ${categoryResult.error.message}`);
  }
  if (itemResult.error) {
    throw new Error(`Could not load menu items: ${itemResult.error.message}`);
  }

  const categories = (categoryResult.data ?? []) as MenuCategory[];
  const selectedCategory = categories.find((category) => category.id === categoryId);
  const itemRows = itemResult.data;
  const count = itemResult.count;
  const items = (itemRows ?? []) as MenuItem[];
  const itemIds = items.map((item) => item.id);
  let variations: MenuVariation[] = [];
  let addons: MenuAddon[] = [];

  if (itemIds.length > 0) {
    const [variationResult, addonResult] = await Promise.all([
      supabase
        .from("menu_variations")
        .select("id, menu_item_id, name, description, price_adjustment, is_available")
        .in("menu_item_id", itemIds)
        .eq("is_available", true)
        .order("name"),
      supabase
        .from("menu_addons")
        .select("id, menu_item_id, name, description, price, is_available")
        .in("menu_item_id", itemIds)
        .eq("is_available", true)
        .order("name"),
    ]);

    if (variationResult.error) {
      throw new Error(`Could not load menu variations: ${variationResult.error.message}`);
    }
    if (addonResult.error) {
      throw new Error(`Could not load menu add-ons: ${addonResult.error.message}`);
    }

    variations = (variationResult.data ?? []) as MenuVariation[];
    addons = (addonResult.data ?? []) as MenuAddon[];
  }

  return {
    categories,
    items,
    variations,
    addons,
    selectedCategoryId: selectedCategory?.id ?? "",
    totalItems: count ?? 0,
    totalPages: Math.max(1, Math.ceil((count ?? 0) / MENU_PAGE_SIZE)),
  };
}
