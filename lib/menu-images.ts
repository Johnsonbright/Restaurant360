import type { MenuCategoryName } from "@/lib/menu";

export const MENU_IMAGE_BUCKET = "menu-images";

type MenuImage = Readonly<{
  src: string;
  label: string;
  credit?: string;
  creditUrl?: string;
}>;

export const MENU_PHOTO_ASSETS = [
  {
    src: "/images/menu-jollof.jpg",
    label: "Nigerian jollof rice",
    credit: "Ei'eke · CC BY-SA 4.0",
    creditUrl:
      "https://commons.wikimedia.org/wiki/File:A_Nigeria_Jollof_Rice_with_chicken.jpg",
  },
  {
    src: "/images/menu-breakfast.jpg",
    label: "Akara and pap",
    credit: "Haruna Sylvester · CC BY-SA 4.0",
    creditUrl:
      "https://commons.wikimedia.org/wiki/File:Akara_and_kwunu_breakfast_(beans_cake_and_pap).jpg",
  },
  {
    src: "/images/menu-snacks.jpg",
    label: "Puff-puff",
    credit: "Albertoblaq · CC BY-SA 4.0",
    creditUrl: "https://commons.wikimedia.org/wiki/File:Puff-Puff.jpg",
  },
  {
    src: "/images/menu-soup.jpg",
    label: "Catfish pepper soup",
    credit: "Halima Waziri · CC BY-SA 4.0",
    creditUrl:
      "https://commons.wikimedia.org/wiki/File:Catfish_pepper_soup_with_vegetables.jpg",
  },
  {
    src: "/images/menu-drinks.jpg",
    label: "Zobo drink",
    credit: "Halima Waziri · CC BY-SA 4.0",
    creditUrl: "https://commons.wikimedia.org/wiki/File:Chilled_Zobo_drink.jpg",
  },
  {
    src: "/images/menu-dessert.jpg",
    label: "Chocolate cake",
    credit: "Daria Yakovleva · CC0",
    creditUrl:
      "https://commons.wikimedia.org/wiki/File:Piece_of_chocolate_cake_on_a_white_plate_decorated_with_chocolate_sauce.jpg",
  },
] as const satisfies readonly MenuImage[];

export function getMenuStorageObjectPath(photoUrl: string | null) {
  const projectUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!photoUrl || !projectUrl) return null;

  try {
    const project = new URL(projectUrl);
    const photo = new URL(photoUrl);
    if (photo.origin !== project.origin) return null;

    const basePath = project.pathname.replace(/\/$/, "");
    const objectPrefix = `${basePath}/storage/v1/object/public/${MENU_IMAGE_BUCKET}/`;
    if (!photo.pathname.startsWith(objectPrefix)) return null;

    const objectPath = decodeURIComponent(photo.pathname.slice(objectPrefix.length));
    if (
      !objectPath.startsWith("menu-items/") ||
      objectPath.split("/").some((part) => part === "." || part === "..")
    ) {
      return null;
    }

    return objectPath;
  } catch {
    return null;
  }
}

const photos = {
  Breakfast: {
    src: "/images/menu-breakfast.jpg",
    label: "Akara and pap",
    credit: "Haruna Sylvester · CC BY-SA 4.0",
    creditUrl:
      "https://commons.wikimedia.org/wiki/File:Akara_and_kwunu_breakfast_(beans_cake_and_pap).jpg",
  },
  "Main Meals": {
    src: "/images/menu-jollof.jpg",
    label: "Nigerian jollof rice",
    credit: "Ei'eke · CC BY-SA 4.0",
    creditUrl:
      "https://commons.wikimedia.org/wiki/File:A_Nigeria_Jollof_Rice_with_chicken.jpg",
  },
  Snacks: {
    src: "/images/menu-snacks.jpg",
    label: "Puff-puff",
    credit: "Albertoblaq · CC BY-SA 4.0",
    creditUrl: "https://commons.wikimedia.org/wiki/File:Puff-Puff.jpg",
  },
  Desserts: {
    src: "/images/menu-dessert.jpg",
    label: "Chocolate cake",
    credit: "Daria Yakovleva · CC0",
    creditUrl:
      "https://commons.wikimedia.org/wiki/File:Piece_of_chocolate_cake_on_a_white_plate_decorated_with_chocolate_sauce.jpg",
  },
  Drinks: {
    src: "/images/menu-drinks.jpg",
    label: "Zobo drink",
    credit: "Halima Waziri · CC BY-SA 4.0",
    creditUrl: "https://commons.wikimedia.org/wiki/File:Chilled_Zobo_drink.jpg",
  },
  Specials: {
    src: "/images/menu-jollof.jpg",
    label: "Nigerian jollof rice",
    credit: "Ei'eke · CC BY-SA 4.0",
    creditUrl:
      "https://commons.wikimedia.org/wiki/File:A_Nigeria_Jollof_Rice_with_chicken.jpg",
  },
} satisfies Record<string, MenuImage>;

const pepperSoupPhoto: MenuImage = {
  src: "/images/menu-soup.jpg",
  label: "Catfish pepper soup",
  credit: "Halima Waziri · CC BY-SA 4.0",
  creditUrl:
    "https://commons.wikimedia.org/wiki/File:Catfish_pepper_soup_with_vegetables.jpg",
};

function isHttpsPhotoUrl(photoUrl: string | null): photoUrl is string {
  if (!photoUrl) return false;
  try {
    return new URL(photoUrl).protocol === "https:";
  } catch {
    return false;
  }
}

export function getMenuImage(
  photoUrl: string | null,
  itemName: string,
  categoryName: MenuCategoryName,
): MenuImage {
  const selectedPhoto = MENU_PHOTO_ASSETS.find((asset) => asset.src === photoUrl);
  if (selectedPhoto) {
    return selectedPhoto;
  }
  if (getMenuStorageObjectPath(photoUrl)) {
    return { src: photoUrl ?? "", label: "Uploaded menu photo" };
  }
  if (isHttpsPhotoUrl(photoUrl)) {
    return { src: photoUrl, label: "Current menu photo" };
  }

  const normalizedName = itemName.toLowerCase();
  if (/\b(soup|egusi|oha|efo riro|ofe)\b/.test(normalizedName)) {
    return pepperSoupPhoto;
  }
  if (/\b(akara|ogi)\b/.test(normalizedName)) {
    return photos.Breakfast;
  }
  if (/\b(jollof|ofada rice|fried rice)\b/.test(normalizedName)) {
    return photos["Main Meals"];
  }

  return photos[categoryName];
}
