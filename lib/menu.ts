export const MENU_CATEGORY_NAMES = [
  "Breakfast",
  "Main Meals",
  "Snacks",
  "Desserts",
  "Drinks",
  "Specials",
] as const;

export const MENU_DIETARY_FLAGS = ["vegan", "vegetarian", "spicy"] as const;

export type MenuCategoryName = (typeof MENU_CATEGORY_NAMES)[number];
export type MenuDietaryFlag = (typeof MENU_DIETARY_FLAGS)[number];

export type MenuCategory = {
  id: string;
  name: MenuCategoryName;
  description: string | null;
  display_order: number;
  is_active: boolean;
};

export type MenuVariation = {
  id: string;
  menu_item_id: string;
  name: string;
  description: string | null;
  price_adjustment: number;
  is_available: boolean;
};

export type MenuAddon = {
  id: string;
  menu_item_id: string;
  name: string;
  description: string | null;
  price: number;
  is_available: boolean;
};

export type MenuItem = {
  id: string;
  reference: string;
  category_id: string;
  name: string;
  description: string | null;
  subcategory: string | null;
  price: number;
  photo_url: string | null;
  ingredient_information: string | null;
  dietary_flags: string[];
  contains_alcohol: boolean;
  is_available: boolean;
  display_order: number;
};

export function formatNaira(amount: number) {
  return new Intl.NumberFormat("en-NG", {
    style: "currency",
    currency: "NGN",
  }).format(amount);
}

export function formatMenuLabel(value: string) {
  return value
    .split(/[_\s]+/)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}
