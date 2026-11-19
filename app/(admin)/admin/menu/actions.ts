"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";
import {
  MENU_CATEGORY_NAMES,
  MENU_DIETARY_FLAGS,
} from "@/lib/menu";
import {
  getMenuStorageObjectPath,
  MENU_IMAGE_BUCKET,
  MENU_PHOTO_ASSETS,
} from "@/lib/menu-images";
import type { MenuActionState } from "@/components/menu-action-form";

const numberFromForm = z
  .string()
  .trim()
  .min(1, "Enter a number.")
  .refine((value) => Number.isFinite(Number(value)), "Enter a valid number.")
  .transform(Number);

const categorySchema = z.object({
  categoryId: z.string().uuid().optional(),
  name: z.enum(MENU_CATEGORY_NAMES),
  description: z.string().trim().max(500),
  displayOrder: numberFromForm
    .refine(Number.isInteger, "Display order must be a whole number.")
    .refine((value) => value >= 0 && value <= 10000, "Display order must be between 0 and 10000."),
  isActive: z.boolean(),
});

const menuItemSchema = z.object({
  itemId: z.string().uuid().optional(),
  reference: z.string().trim().min(1).max(64),
  categoryId: z.string().uuid(),
  name: z.string().trim().min(1).max(120),
  description: z.string().trim().max(2000),
  subcategory: z.string().trim().max(120),
  price: numberFromForm.refine(
    (value) => value >= 0 && value <= 10000000,
    "Price must be between 0 and 10000000.",
  ),
  photoUrl: z
    .string()
    .max(2048)
    .refine(isAllowedPhotoUrl, "Choose a photo asset or upload an image."),
  ingredientInformation: z.string().trim().max(2000),
  dietaryFlags: z.array(z.enum(MENU_DIETARY_FLAGS)),
  containsAlcohol: z.boolean(),
  isAvailable: z.boolean(),
  displayOrder: numberFromForm
    .refine(Number.isInteger, "Display order must be a whole number.")
    .refine((value) => value >= 0 && value <= 10000, "Display order must be between 0 and 10000."),
});

const variationSchema = z.object({
  variationId: z.string().uuid().optional(),
  menuItemId: z.string().uuid(),
  name: z.string().trim().min(1).max(120),
  description: z.string().trim().max(500),
  priceAdjustment: numberFromForm.refine(
    (value) => value >= -1000000 && value <= 1000000,
    "Price adjustment must be between -1000000 and 1000000.",
  ),
  isAvailable: z.boolean(),
});

const addonSchema = z.object({
  addonId: z.string().uuid().optional(),
  menuItemId: z.string().uuid(),
  name: z.string().trim().min(1).max(120),
  description: z.string().trim().max(500),
  price: numberFromForm.refine(
    (value) => value >= 0 && value <= 1000000,
    "Price must be between 0 and 1000000.",
  ),
  isAvailable: z.boolean(),
});

function isAllowedPhotoUrl(value: string) {
  if (!value || MENU_PHOTO_ASSETS.some((asset) => asset.src === value)) return true;
  if (getMenuStorageObjectPath(value)) return true;

  try {
    return new URL(value).protocol === "https:";
  } catch {
    return false;
  }
}

function getString(formData: FormData, key: string) {
  const value = formData.get(key);
  return typeof value === "string" ? value : "";
}

function getOptionalString(formData: FormData, key: string) {
  const value = getString(formData, key).trim();
  return value || undefined;
}

function getValidationMessage(error: z.ZodError) {
  return error.issues[0]?.message ?? "Check the information and try again.";
}

async function getMenuManagerClient() {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError) {
    throw new Error(`Could not verify your session: ${userError.message}`);
  }
  if (!user) redirect("/login");

  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .maybeSingle();

  if (profileError) {
    throw new Error(`Could not verify your staff role: ${profileError.message}`);
  }
  if (profile?.role !== "manager" && profile?.role !== "admin") {
    redirect("/unauthorized");
  }

  return supabase;
}

function revalidateMenu() {
  revalidatePath("/menu");
  revalidatePath("/admin/menu");
}

async function removeUnusedUploadedPhoto(
  supabase: Awaited<ReturnType<typeof createClient>>,
  photoUrl: string | null,
  excludedMenuItemId?: string,
) {
  const objectPath = getMenuStorageObjectPath(photoUrl);
  if (!objectPath || !photoUrl) return null;

  let referenceQuery = supabase
    .from("menu_items")
    .select("id")
    .eq("photo_url", photoUrl);
  if (excludedMenuItemId) {
    referenceQuery = referenceQuery.neq("id", excludedMenuItemId);
  }
  const { data: references, error: referenceError } = await referenceQuery.limit(1);
  if (referenceError) return `Could not check for other uses: ${referenceError.message}`;
  if (references && references.length > 0) return null;

  const { error } = await supabase.storage.from(MENU_IMAGE_BUCKET).remove([objectPath]);
  return error ? error.message : null;
}

export async function saveCategoryAction(
  _previousState: MenuActionState,
  formData: FormData,
): Promise<MenuActionState> {
  const supabase = await getMenuManagerClient();
  const parsed = categorySchema.safeParse({
    categoryId: getOptionalString(formData, "categoryId"),
    name: getString(formData, "name"),
    description: getString(formData, "description"),
    displayOrder: getString(formData, "displayOrder"),
    isActive: formData.get("isActive") === "on",
  });

  if (!parsed.success) return { error: getValidationMessage(parsed.error) };

  const categoryData = {
    name: parsed.data.name,
    description: parsed.data.description || null,
    display_order: parsed.data.displayOrder,
    is_active: parsed.data.isActive,
  };

  if (parsed.data.categoryId) {
    const { data, error } = await supabase
      .from("categories")
      .update(categoryData)
      .eq("id", parsed.data.categoryId)
      .select("id")
      .maybeSingle();

    if (error) return { error: `Could not save category: ${error.message}` };
    if (!data) return { error: "Category not found or you cannot edit it." };
  } else {
    const { error } = await supabase.from("categories").insert(categoryData);
    if (error) return { error: `Could not add category: ${error.message}` };
  }

  revalidateMenu();
  return { success: "Category saved." };
}

export async function saveMenuItemAction(
  _previousState: MenuActionState,
  formData: FormData,
): Promise<MenuActionState> {
  const supabase = await getMenuManagerClient();
  const parsed = menuItemSchema.safeParse({
    itemId: getOptionalString(formData, "itemId"),
    reference: getString(formData, "reference"),
    categoryId: getString(formData, "categoryId"),
    name: getString(formData, "name"),
    description: getString(formData, "description"),
    subcategory: getString(formData, "subcategory"),
    price: getString(formData, "price"),
    photoUrl: getString(formData, "photoUrl"),
    ingredientInformation: getString(formData, "ingredientInformation"),
    dietaryFlags: formData
      .getAll("dietaryFlags")
      .filter((value): value is string => typeof value === "string"),
    containsAlcohol: formData.get("containsAlcohol") === "on",
    isAvailable: formData.get("isAvailable") === "on",
    displayOrder: getString(formData, "displayOrder"),
  });

  if (!parsed.success) return { error: getValidationMessage(parsed.error) };

  const itemData = {
    reference: parsed.data.reference,
    category_id: parsed.data.categoryId,
    name: parsed.data.name,
    description: parsed.data.description || null,
    subcategory: parsed.data.subcategory || null,
    price: parsed.data.price,
    photo_url: parsed.data.photoUrl || null,
    ingredient_information: parsed.data.ingredientInformation || null,
    dietary_flags: parsed.data.dietaryFlags,
    contains_alcohol: parsed.data.containsAlcohol,
    is_available: parsed.data.isAvailable,
    display_order: parsed.data.displayOrder,
  };

  if (parsed.data.itemId) {
    const { data: existingItem, error: existingItemError } = await supabase
      .from("menu_items")
      .select("photo_url")
      .eq("id", parsed.data.itemId)
      .maybeSingle();

    if (existingItemError) {
      return { error: `Could not load the current menu item: ${existingItemError.message}` };
    }
    if (!existingItem) return { error: "Menu item not found or you cannot edit it." };

    const { data, error } = await supabase
      .from("menu_items")
      .update(itemData)
      .eq("id", parsed.data.itemId)
      .select("id")
      .maybeSingle();

    if (error) {
      const cleanupError =
        parsed.data.photoUrl !== existingItem.photo_url
          ? await removeUnusedUploadedPhoto(supabase, parsed.data.photoUrl)
          : null;
      return {
        error: cleanupError
          ? `Could not update menu item: ${error.message}. Uploaded photo cleanup also failed: ${cleanupError}`
          : `Could not update menu item: ${error.message}`,
      };
    }
    if (!data) return { error: "Menu item not found or you cannot edit it." };

    if (parsed.data.photoUrl !== existingItem.photo_url) {
      const cleanupError = await removeUnusedUploadedPhoto(
        supabase,
        existingItem.photo_url,
        parsed.data.itemId,
      );
      if (cleanupError) {
        revalidateMenu();
        return {
          success: `Menu item saved, but its previous uploaded photo could not be removed: ${cleanupError}`,
        };
      }
    }
  } else {
    const { error } = await supabase.from("menu_items").insert(itemData);
    if (error) {
      const cleanupError = await removeUnusedUploadedPhoto(supabase, parsed.data.photoUrl);
      return {
        error: cleanupError
          ? `Could not add menu item: ${error.message}. Uploaded photo cleanup also failed: ${cleanupError}`
          : `Could not add menu item: ${error.message}`,
      };
    }
  }

  revalidateMenu();
  return { success: "Menu item saved." };
}

export async function deleteMenuItemAction(
  _previousState: MenuActionState,
  formData: FormData,
): Promise<MenuActionState> {
  const supabase = await getMenuManagerClient();
  const parsed = z.object({ itemId: z.string().uuid() }).safeParse({
    itemId: getString(formData, "itemId"),
  });

  if (!parsed.success) return { error: getValidationMessage(parsed.error) };

  const { data: existingItem, error: existingItemError } = await supabase
    .from("menu_items")
    .select("photo_url")
    .eq("id", parsed.data.itemId)
    .maybeSingle();
  if (existingItemError) {
    return { error: `Could not load the current menu item: ${existingItemError.message}` };
  }
  if (!existingItem) return { error: "Menu item not found or you cannot delete it." };

  const { data, error } = await supabase
    .from("menu_items")
    .delete()
    .eq("id", parsed.data.itemId)
    .select("id")
    .maybeSingle();

  if (error) {
    if (error.code === "23503") {
      return {
        error:
          "This item is referenced by a recipe or order and cannot be deleted. Mark it unavailable instead.",
      };
    }
    return { error: `Could not delete menu item: ${error.message}` };
  }
  if (!data) return { error: "Menu item not found or you cannot delete it." };

  revalidateMenu();
  const cleanupError = await removeUnusedUploadedPhoto(supabase, existingItem.photo_url);
  if (cleanupError) {
    return {
      success: `Menu item deleted, but its uploaded photo could not be removed: ${cleanupError}`,
    };
  }
  return { success: "Menu item deleted." };
}

export async function saveVariationAction(
  _previousState: MenuActionState,
  formData: FormData,
): Promise<MenuActionState> {
  const supabase = await getMenuManagerClient();
  const parsed = variationSchema.safeParse({
    variationId: getOptionalString(formData, "variationId"),
    menuItemId: getString(formData, "menuItemId"),
    name: getString(formData, "name"),
    description: getString(formData, "description"),
    priceAdjustment: getString(formData, "priceAdjustment"),
    isAvailable: formData.get("isAvailable") === "on",
  });

  if (!parsed.success) return { error: getValidationMessage(parsed.error) };

  const variationData = {
    name: parsed.data.name,
    description: parsed.data.description || null,
    price_adjustment: parsed.data.priceAdjustment,
    is_available: parsed.data.isAvailable,
  };

  if (parsed.data.variationId) {
    const { data, error } = await supabase
      .from("menu_variations")
      .update(variationData)
      .eq("id", parsed.data.variationId)
      .eq("menu_item_id", parsed.data.menuItemId)
      .select("id")
      .maybeSingle();

    if (error) return { error: `Could not update variation: ${error.message}` };
    if (!data) return { error: "Variation not found or you cannot edit it." };
  } else {
    const { error } = await supabase.from("menu_variations").insert({
      ...variationData,
      menu_item_id: parsed.data.menuItemId,
    });
    if (error) return { error: `Could not add variation: ${error.message}` };
  }

  revalidateMenu();
  return { success: "Variation saved." };
}

export async function saveAddonAction(
  _previousState: MenuActionState,
  formData: FormData,
): Promise<MenuActionState> {
  const supabase = await getMenuManagerClient();
  const parsed = addonSchema.safeParse({
    addonId: getOptionalString(formData, "addonId"),
    menuItemId: getString(formData, "menuItemId"),
    name: getString(formData, "name"),
    description: getString(formData, "description"),
    price: getString(formData, "price"),
    isAvailable: formData.get("isAvailable") === "on",
  });

  if (!parsed.success) return { error: getValidationMessage(parsed.error) };

  const addonData = {
    name: parsed.data.name,
    description: parsed.data.description || null,
    price: parsed.data.price,
    is_available: parsed.data.isAvailable,
  };

  if (parsed.data.addonId) {
    const { data, error } = await supabase
      .from("menu_addons")
      .update(addonData)
      .eq("id", parsed.data.addonId)
      .eq("menu_item_id", parsed.data.menuItemId)
      .select("id")
      .maybeSingle();

    if (error) return { error: `Could not update add-on: ${error.message}` };
    if (!data) return { error: "Add-on not found or you cannot edit it." };
  } else {
    const { error } = await supabase.from("menu_addons").insert({
      ...addonData,
      menu_item_id: parsed.data.menuItemId,
    });
    if (error) return { error: `Could not add add-on: ${error.message}` };
  }

  revalidateMenu();
  return { success: "Add-on saved." };
}
