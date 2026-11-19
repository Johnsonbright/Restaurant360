import { existsSync } from "node:fs";
import { join } from "node:path";
import Image from "next/image";
import Link from "next/link";
import { FadeUp, Stagger, StaggerItem } from "@/components/animations";
import { HomeHero } from "@/components/home-hero";
import { HoverCard } from "@/components/hover-card";

const featuredMeals = [
  {
    name: "Slow-braised short rib",
    description: "Silky mash, garden herbs, and a rich pan jus.",
    image: "/images/plate-braise.svg",
    alt: "Illustrative placeholder for a slow-braised dish",
    note: "The house favourite",
  },
  {
    name: "Roasted market vegetables",
    description: "Seasonal vegetables, bright citrus, toasted seeds.",
    image: "/images/plate-vegetables.svg",
    alt: "Illustrative placeholder for roasted vegetables",
    note: "Garden inspired",
  },
  {
    name: "Herb-roasted chicken",
    description: "Crisp skin, soft polenta, and a little lemon.",
    image: "/images/plate-chicken.svg",
    alt: "Illustrative placeholder for herb-roasted chicken",
    note: "Slow Sunday energy",
  },
  {
    name: "Dark chocolate tart",
    description: "Deep cocoa, gently whipped cream, sea salt.",
    image: "/images/plate-tart.svg",
    alt: "Illustrative placeholder for a chocolate tart",
    note: "Save room",
  },
];

const categories = [
  "Breakfast",
  "Main Meals",
  "Snacks",
  "Desserts",
  "Drinks",
  "Specials",
];

const reviews = [
  {
    quote: "A lovely, unhurried evening. The room felt welcoming from the moment we arrived.",
    byline: "Sample guest",
  },
  {
    quote: "Thoughtful food, warm service, and exactly the kind of place you want to linger.",
    byline: "Placeholder review",
  },
  {
    quote: "The small details made dinner feel special. We will be back for another visit.",
    byline: "Sample guest",
  },
];

export default function HomePage() {
  const hasHeroPhoto = existsSync(
    join(process.cwd(), "public", "images", "hero.jpg"),
  );

  return (
    <main>
      <div className="mx-auto max-w-7xl px-4 pt-5 sm:px-6 lg:px-8">
        <HomeHero hasHeroPhoto={hasHeroPhoto} />
      </div>

      <section
        aria-labelledby="featured-title"
        className="mx-auto max-w-7xl px-5 py-20 md:py-28"
      >
        <FadeUp className="mb-9 flex flex-wrap items-end justify-between gap-5">
          <div>
            <p className="mb-3 text-xs font-semibold uppercase tracking-[0.2em] text-primary">
              From our table
            </p>
            <h2 className="font-display text-4xl md:text-5xl" id="featured-title">
              A few favourites
            </h2>
          </div>
          <Link
            className="text-sm font-semibold text-primary underline-offset-4 hover:underline"
            href="/menu"
          >
            Explore the menu
          </Link>
        </FadeUp>
        <Stagger className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {featuredMeals.map((meal) => (
            <StaggerItem key={meal.name}>
              <HoverCard className="h-full overflow-hidden">
                <Image
                  alt={meal.alt}
                  className="aspect-[4/3] w-full object-cover"
                  height={420}
                  src={meal.image}
                  width={640}
                />
                <div className="p-5">
                  <p className="text-xs font-medium uppercase tracking-wide text-primary">
                    {meal.note}
                  </p>
                  <h3 className="mt-2 font-display text-2xl">{meal.name}</h3>
                  <p className="mt-2 text-sm leading-6 text-muted-foreground">
                    {meal.description}
                  </p>
                </div>
              </HoverCard>
            </StaggerItem>
          ))}
        </Stagger>
        <p className="mt-4 text-xs text-muted-foreground">
          Sample dishes and artwork for the foundation preview.
        </p>
      </section>

      <section
        aria-labelledby="categories-title"
        className="border-y border-border bg-card"
      >
        <div className="mx-auto max-w-7xl px-5 py-20 md:py-24">
          <FadeUp className="mb-8">
            <p className="mb-3 text-xs font-semibold uppercase tracking-[0.2em] text-primary">
              Find your moment
            </p>
            <h2 className="font-display text-4xl md:text-5xl" id="categories-title">
              Something for every hour
            </h2>
          </FadeUp>
          <Stagger className="grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-6">
            {categories.map((category, index) => (
              <StaggerItem key={category}>
                <HoverCard className="h-full">
                  <Link
                    className="flex min-h-28 flex-col justify-between p-4 text-foreground"
                    href="/menu"
                  >
                    <span className="text-xs text-muted-foreground">
                      0{index + 1}
                    </span>
                    <span className="font-display text-xl">{category}</span>
                  </Link>
                </HoverCard>
              </StaggerItem>
            ))}
          </Stagger>
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-5 py-20 md:py-24">
        <FadeUp>
          <div className="flex flex-col items-start justify-between gap-8 rounded-xl bg-primary p-8 text-primary-foreground md:flex-row md:items-center md:p-12">
            <div className="max-w-2xl">
              <p className="mb-3 text-xs font-semibold uppercase tracking-[0.2em] opacity-80">
                A little extra
              </p>
              <h2 className="font-display text-4xl md:text-5xl">
                Make room for a good evening.
              </h2>
              <p className="mt-4 max-w-xl text-sm leading-6 opacity-90">
                Join us around the table for good food and a slower pace. We look
                forward to welcoming you.
              </p>
            </div>
            <Link
              className="inline-flex h-12 shrink-0 items-center justify-center rounded-lg border border-current px-6 text-sm font-semibold transition-colors hover:bg-primary-foreground/10"
              href="/reserve"
            >
              Reserve a Table
            </Link>
          </div>
        </FadeUp>
      </section>

      <section
        aria-labelledby="gallery-title"
        className="border-y border-border bg-card"
      >
        <div className="mx-auto max-w-7xl px-5 py-20 md:py-24">
          <FadeUp className="mb-8">
            <p className="mb-3 text-xs font-semibold uppercase tracking-[0.2em] text-primary">
              The atmosphere
            </p>
            <h2 className="font-display text-4xl md:text-5xl" id="gallery-title">
              An evening in good company
            </h2>
          </FadeUp>
          <Stagger className="grid grid-cols-2 gap-3 md:grid-cols-4">
            {featuredMeals.map((meal) => (
              <StaggerItem key={`gallery-${meal.image}`}>
                <HoverCard className="overflow-hidden">
                  <Image
                    alt={`Sample gallery artwork: ${meal.name}`}
                    className="aspect-square w-full object-cover"
                    height={420}
                    src={meal.image}
                    width={640}
                  />
                </HoverCard>
              </StaggerItem>
            ))}
          </Stagger>
          <p className="mt-4 text-xs text-muted-foreground">
            Gallery artwork is temporary and will be replaced with restaurant photography.
          </p>
        </div>
      </section>

      <section
        aria-labelledby="reviews-title"
        className="mx-auto max-w-7xl px-5 py-20 md:py-24"
      >
        <FadeUp className="mb-8">
          <p className="mb-3 text-xs font-semibold uppercase tracking-[0.2em] text-primary">
            Kind words
          </p>
          <h2 className="font-display text-4xl md:text-5xl" id="reviews-title">
            Notes from the table
          </h2>
        </FadeUp>
        <Stagger className="grid gap-5 md:grid-cols-3">
          {reviews.map((review) => (
            <StaggerItem key={review.quote}>
              <HoverCard className="h-full p-6">
                <p aria-label="Five out of five sample rating" className="text-primary">
                  ★★★★★
                </p>
                <blockquote className="mt-4 font-display text-xl leading-7">
                  “{review.quote}”
                </blockquote>
                <p className="mt-5 text-xs font-medium uppercase tracking-wide text-muted-foreground">
                  {review.byline} · Sample review
                </p>
              </HoverCard>
            </StaggerItem>
          ))}
        </Stagger>
      </section>

      <section className="border-t border-border bg-card">
        <div className="mx-auto grid max-w-7xl gap-12 px-5 py-20 md:grid-cols-2 md:py-24">
          <FadeUp>
            <p className="mb-3 text-xs font-semibold uppercase tracking-[0.2em] text-primary">
              Come by
            </p>
            <h2 className="font-display text-4xl md:text-5xl">Settle in awhile.</h2>
            <p className="mt-5 max-w-md text-muted-foreground">
              Location details are sample placeholders. The restaurant address
              will be added when confirmed.
            </p>
            <p className="mt-6 font-medium">Address to be confirmed</p>
            <p className="text-muted-foreground">City, Country</p>
            <Link
              className="mt-5 inline-block text-sm font-semibold text-primary underline-offset-4 hover:underline"
              href="/contact"
            >
              Get in touch
            </Link>
          </FadeUp>
          <FadeUp delay={0.12}>
            <div className="rounded-xl border border-border bg-background p-6 md:p-8">
              <h3 className="font-display text-3xl">Opening hours</h3>
              <dl className="mt-5 space-y-3 text-sm">
                <div className="flex justify-between gap-4 border-b border-border pb-3">
                  <dt className="text-muted-foreground">Monday–Thursday</dt>
                  <dd className="font-medium">11am–10pm</dd>
                </div>
                <div className="flex justify-between gap-4 border-b border-border pb-3">
                  <dt className="text-muted-foreground">Friday–Sunday</dt>
                  <dd className="font-medium">11am–11pm</dd>
                </div>
              </dl>
              <div className="mt-6 border-t border-border pt-5">
                <p className="text-sm font-medium">Contact placeholders</p>
                <p className="mt-2 text-sm text-muted-foreground">hello@example.test</p>
                <p className="text-sm text-muted-foreground">+000 000 0000</p>
              </div>
            </div>
          </FadeUp>
        </div>
      </section>
    </main>
  );
}
