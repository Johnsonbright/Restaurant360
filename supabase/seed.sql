begin;

-- Prices below are invented sample prices in Nigerian naira (NGN).

insert into public.categories (name, description, display_order)
values
  ('Breakfast', 'Breakfast and morning meals.', 1),
  ('Main Meals', 'Main dishes and traditional meals.', 2),
  ('Snacks', 'Light bites, pies and wraps.', 3),
  ('Desserts', 'Desserts and local sweets.', 4),
  ('Drinks', 'Soft drinks, traditional drinks and wine.', 5),
  ('Specials', 'Large portions and special occasion dishes.', 6)
on conflict (name) do nothing;

insert into public.suppliers (name, email, notes)
select supplier.name, supplier.email, supplier.notes
from (
  values
    ('Sample Proteins Ltd', 'proteins@example.test', 'Fictional sample supplier for proteins.'),
    ('Sample Fresh Produce Co', 'produce@example.test', 'Fictional sample supplier for fresh produce.'),
    ('Sample Dry Goods and Drinks Co', 'drygoods@example.test', 'Fictional sample supplier for dry goods and drinks.')
) as supplier(name, email, notes)
where not exists (
  select 1 from public.suppliers existing where existing.name = supplier.name
);

with menu_rows (
  reference, category_name, name, description, subcategory, price,
  is_available, dietary_flags, contains_alcohol
) as (
  values
    ('MI-BRK-001', 'Breakfast', 'Koko with Kosai', 'Millet or maize porridge served with bean cakes.', 'Hausa / Northern', 2200, true, array[]::text[], false),
    ('MI-BRK-002', 'Breakfast', 'Masa / Waina with Pepper Sauce', 'Rice cakes served with pepper sauce.', 'Hausa / Northern', 2500, true, array[]::text[], false),
    ('MI-BRK-003', 'Breakfast', 'Fura da Nono (breakfast)', 'Fura served with nono.', 'Hausa / Northern', 2000, true, array[]::text[], false),
    ('MI-BRK-004', 'Breakfast', 'Kunu (breakfast)', 'Traditional kunu with aya, tiger nut, gyada and other variants.', 'Hausa / Northern', 1800, true, array[]::text[], false),
    ('MI-BRK-005', 'Breakfast', 'Gurasa with Stew', 'Gurasa served with stew.', 'Hausa / Northern', 2200, true, array[]::text[], false),
    ('MI-BRK-006', 'Breakfast', 'Gurasa with Eggs', 'Gurasa served with eggs.', 'Hausa / Northern', 2500, true, array[]::text[], false),
    ('MI-BRK-007', 'Breakfast', 'Ogi / Pap with Milk and Sugar', 'Fermented corn porridge served with milk and sugar.', 'Yoruba', 1800, true, array[]::text[], false),
    ('MI-BRK-008', 'Breakfast', 'Ogi with Akara', 'Fermented corn porridge served with akara.', 'Yoruba', 2500, true, array[]::text[], false),
    ('MI-BRK-009', 'Breakfast', 'Ogi with Moi Moi', 'Fermented corn porridge served with moi moi.', 'Yoruba', 2800, true, array[]::text[], false),
    ('MI-BRK-010', 'Breakfast', 'Agege Bread with Tea', 'Agege bread served with tea.', 'Yoruba', 1800, true, array[]::text[], false),
    ('MI-BRK-011', 'Breakfast', 'Agege Bread with Ewa Agoyin', 'Agege bread served with ewa agoyin.', 'Yoruba', 2500, true, array[]::text[], false),
    ('MI-BRK-012', 'Breakfast', 'Yam and Egg Sauce (breakfast)', 'Yam served with egg sauce.', 'Igbo', 3200, true, array[]::text[], false),
    ('MI-BRK-013', 'Breakfast', 'Tea and Bread', 'Tea served with bread.', 'Igbo', 1700, true, array[]::text[], false),
    ('MI-BRK-014', 'Breakfast', 'Beans and Plantain (breakfast)', 'Beans served with plantain.', 'Igbo', 2800, true, array[]::text[], false),
    ('MI-BRK-015', 'Breakfast', 'Beans and Yam (breakfast)', 'Beans served with yam.', 'Igbo', 3000, true, array[]::text[], false),
    ('MI-BRK-016', 'Breakfast', 'Egg Rice (breakfast)', 'Rice prepared with egg.', 'Igbo', 2800, true, array[]::text[], false),
    ('MI-BRK-017', 'Breakfast', 'Plantain Porridge (breakfast)', 'Plantain prepared as porridge.', 'Igbo', 3000, true, array[]::text[], false),
    ('MI-BRK-018', 'Breakfast', 'Yam Porridge (breakfast)', 'Yam prepared as porridge.', 'Igbo', 3200, true, array[]::text[], false),

    ('MI-MAIN-001', 'Main Meals', 'Jollof Rice', 'Jollof rice served as a main meal.', 'General dishes', 5000, true, array[]::text[], false),
    ('MI-MAIN-002', 'Main Meals', 'White Rice and Sauce', 'White rice served with sauce.', 'General dishes', 4500, true, array[]::text[], false),
    ('MI-MAIN-003', 'Main Meals', 'Ofe Oha', 'Oha soup served as a main meal.', 'Igbo dishes', 6000, true, array[]::text[], false),
    ('MI-MAIN-004', 'Main Meals', 'Ofe Onugbu', 'Bitterleaf soup served as a main meal.', 'Igbo dishes', 6000, true, array[]::text[], false),
    ('MI-MAIN-005', 'Main Meals', 'Ofe Nsala', 'White soup prepared with catfish or yam.', 'Igbo dishes', 6500, true, array[]::text[], false),
    ('MI-MAIN-006', 'Main Meals', 'Ofe Akwu with Rice (Igbo serving)', 'Palm-nut soup served with rice.', 'Igbo dishes', 6500, true, array[]::text[], false),
    ('MI-MAIN-007', 'Main Meals', 'Ofe Owerri', 'Ofe Owerri served as a main meal.', 'Igbo dishes', 7000, true, array[]::text[], false),
    ('MI-MAIN-008', 'Main Meals', 'Ofe Egusi', 'Egusi soup served as a main meal.', 'Igbo dishes', 6000, true, array[]::text[], false),
    ('MI-MAIN-009', 'Main Meals', 'Ofe Ogbono', 'Ogbono soup served as a main meal.', 'Igbo dishes', 6000, true, array[]::text[], false),
    ('MI-MAIN-010', 'Main Meals', 'Okra Soup', 'Okra soup served as a main meal.', 'Igbo dishes', 5500, true, array[]::text[], false),
    ('MI-MAIN-011', 'Main Meals', 'Nkwobi (plate)', 'Nkwobi served as a main-meal portion.', 'Igbo dishes', 7000, true, array[]::text[], false),
    ('MI-MAIN-012', 'Main Meals', 'Isi Ewu', 'Isi ewu served as a main meal.', 'Igbo dishes', 8500, true, array[]::text[], false),
    ('MI-MAIN-013', 'Main Meals', 'Abacha (plate)', 'Abacha served as a main-meal portion.', 'Igbo dishes', 5000, true, array[]::text[], false),
    ('MI-MAIN-014', 'Main Meals', 'Ukwa', 'Ukwa served as a main meal.', 'Igbo dishes', 5500, true, array[]::text[], false),
    ('MI-MAIN-015', 'Main Meals', 'Okpa (main serving)', 'Okpa served as a main-meal portion.', 'Igbo dishes', 4000, true, array[]::text[], false),
    ('MI-MAIN-016', 'Main Meals', 'Ji Mmanu', 'Ji mmanu served as a main meal.', 'Igbo dishes', 4500, true, array[]::text[], false),
    ('MI-MAIN-017', 'Main Meals', 'Achicha Ede', 'Achicha ede served as a main meal.', 'Igbo dishes', 5000, true, array[]::text[], false),
    ('MI-MAIN-018', 'Main Meals', 'Yam Pepper Soup', 'Yam prepared in pepper soup.', 'Igbo dishes', 5000, true, array[]::text[], false),
    ('MI-MAIN-019', 'Main Meals', 'Akpu / Fufu with Soup', 'Akpu or fufu served with soup.', 'Igbo dishes', 5000, true, array[]::text[], false),
    ('MI-MAIN-020', 'Main Meals', 'Ugba / Ukpaka', 'Ugba, also called ukpaka, served as a main meal.', 'Igbo dishes', 4500, true, array[]::text[], false),
    ('MI-MAIN-021', 'Main Meals', 'Osukwu (Plantain Porridge)', 'Osukwu prepared as plantain porridge.', 'Igbo dishes', 5000, true, array[]::text[], false),
    ('MI-MAIN-022', 'Main Meals', 'Fio-fio / Echicha', 'Fio-fio, also called echicha, served as a main meal.', 'Igbo dishes', 5000, true, array[]::text[], false),
    ('MI-MAIN-023', 'Main Meals', 'Tuwo Shinkafa with Miyan Kuka', 'Tuwo shinkafa served with miyan kuka.', 'Hausa dishes', 5000, true, array[]::text[], false),
    ('MI-MAIN-024', 'Main Meals', 'Miyan Taushe', 'Miyan taushe served as a main meal.', 'Hausa dishes', 5000, true, array[]::text[], false),
    ('MI-MAIN-025', 'Main Meals', 'Miyan Kubewa', 'Miyan kubewa prepared with okra.', 'Hausa dishes', 5000, true, array[]::text[], false),
    ('MI-MAIN-026', 'Main Meals', 'Suya (plate)', 'Suya served as a main-meal plate.', 'Hausa dishes', 8000, true, array[]::text[], false),
    ('MI-MAIN-027', 'Main Meals', 'Kilishi (plate)', 'Kilishi served as a main-meal plate.', 'Hausa dishes', 6500, true, array[]::text[], false),
    ('MI-MAIN-028', 'Main Meals', 'Dan Wake', 'Dan wake served as a main meal.', 'Hausa dishes', 4000, true, array[]::text[], false),
    ('MI-MAIN-029', 'Main Meals', 'Tuwon Masara / Dawa', 'Tuwon masara or dawa served as a main meal.', 'Hausa dishes', 4500, true, array[]::text[], false),
    ('MI-MAIN-030', 'Main Meals', 'Dambu Nama (plate)', 'Dambu nama served as a main-meal plate.', 'Hausa dishes', 6500, true, array[]::text[], false),
    ('MI-MAIN-031', 'Main Meals', 'Shinkafa da Wake', 'Rice served with beans.', 'Hausa dishes', 4500, true, array[]::text[], false),
    ('MI-MAIN-032', 'Main Meals', 'Taliya', 'Taliya served as a main meal.', 'Hausa dishes', 4500, true, array[]::text[], false),
    ('MI-MAIN-033', 'Main Meals', 'Funkaso (main serving)', 'Funkaso served as a main-meal portion.', 'Hausa dishes', 4000, true, array[]::text[], false),
    ('MI-MAIN-034', 'Main Meals', 'Sinasir', 'Sinasir served as a main meal.', 'Hausa dishes', 4000, true, array[]::text[], false),
    ('MI-MAIN-035', 'Main Meals', 'Amala with Ewedu and Gbegiri (Abula)', 'Amala served with ewedu and gbegiri.', 'Yoruba dishes', 5500, true, array[]::text[], false),
    ('MI-MAIN-036', 'Main Meals', 'Efo Riro', 'Efo riro served as a main meal.', 'Yoruba dishes', 6000, true, array[]::text[], false),
    ('MI-MAIN-037', 'Main Meals', 'Ofe Egusi with Pounded Yam', 'Egusi soup served with pounded yam (iyan).', 'Yoruba dishes', 7000, true, array[]::text[], false),
    ('MI-MAIN-038', 'Main Meals', 'Ofada Rice with Ayamase', 'Ofada rice served with ayamase.', 'Yoruba dishes', 6500, true, array[]::text[], false),
    ('MI-MAIN-039', 'Main Meals', 'Ewa Agoyin', 'Ewa agoyin served as a main meal.', 'Yoruba dishes', 4500, true, array[]::text[], false),
    ('MI-MAIN-040', 'Main Meals', 'Moi Moi (main portion)', 'Moi moi served as a main-meal portion.', 'Yoruba dishes', 3500, true, array[]::text[], false),
    ('MI-MAIN-041', 'Main Meals', 'Asaro (Yam Porridge)', 'Asaro prepared as yam porridge.', 'Yoruba dishes', 5000, true, array[]::text[], false),
    ('MI-MAIN-042', 'Main Meals', 'Ila Alasepo', 'Ila alasepo, an okra dish, served as a main meal.', 'Yoruba dishes', 5500, true, array[]::text[], false),
    ('MI-MAIN-043', 'Main Meals', 'Ikokore', 'Ikokore served as a main meal.', 'Yoruba dishes', 5500, true, array[]::text[], false),
    ('MI-MAIN-044', 'Main Meals', 'Eba', 'Eba served as a main meal.', 'Yoruba dishes', 3000, true, array[]::text[], false),
    ('MI-MAIN-045', 'Main Meals', 'Asun (plate)', 'Asun served as a main-meal plate.', 'Yoruba dishes', 8000, true, array[]::text[], false),
    ('MI-MAIN-046', 'Main Meals', 'Dodo (side)', 'Dodo served as a side portion.', 'Yoruba dishes', 2500, true, array['vegan']::text[], false),
    ('MI-MAIN-047', 'Main Meals', 'Boli (main serving)', 'Boli served as a main-meal portion.', 'Yoruba dishes', 3500, true, array[]::text[], false),
    ('MI-MAIN-048', 'Main Meals', 'Iresi Agbon (Coconut Rice)', 'Rice prepared with coconut.', 'Yoruba dishes', 5500, true, array[]::text[], false),
    ('MI-MAIN-049', 'Main Meals', 'Ofe Akwu with Rice (general serving)', 'Palm-nut soup served with rice.', 'General dishes', 6500, true, array[]::text[], false),
    ('MI-MAIN-050', 'Main Meals', 'Coconut Rice', 'Coconut rice served as a main meal.', 'General dishes', 5500, true, array[]::text[], false),
    ('MI-MAIN-051', 'Main Meals', 'Native Rice', 'Native rice served as a main meal.', 'General dishes', 5500, true, array[]::text[], false),
    ('MI-MAIN-052', 'Main Meals', 'Egg Rice (main plate)', 'Rice prepared with egg and served as a main plate.', 'General dishes', 4500, true, array[]::text[], false),
    ('MI-MAIN-053', 'Main Meals', 'Spaghetti', 'Spaghetti served as a main meal.', 'General dishes', 4500, true, array[]::text[], false),
    ('MI-MAIN-054', 'Main Meals', 'Pepper Soup (goat)', 'Goat meat pepper soup served as a main meal.', 'General dishes', 8000, true, array[]::text[], false),
    ('MI-MAIN-055', 'Main Meals', 'Pepper Soup (chicken)', 'Chicken pepper soup served as a main meal.', 'General dishes', 7000, true, array[]::text[], false),
    ('MI-MAIN-056', 'Main Meals', 'Pepper Soup (catfish)', 'Catfish pepper soup served as a main meal.', 'General dishes', 7500, true, array[]::text[], false),
    ('MI-MAIN-057', 'Main Meals', 'Pepper Soup (snails)', 'Pepper snails soup served as a main meal.', 'General dishes', 9000, true, array[]::text[], false),
    ('MI-MAIN-058', 'Main Meals', 'Turkey Preparation', 'Turkey prepared as a main meal.', 'General dishes', 9000, true, array[]::text[], false),
    ('MI-MAIN-059', 'Main Meals', 'Fish Preparation', 'Fish prepared as a main meal.', 'General dishes', 8000, true, array[]::text[], false),
    ('MI-MAIN-060', 'Main Meals', 'Chicken Preparation', 'Chicken prepared as a main meal.', 'General dishes', 7500, true, array[]::text[], false),
    ('MI-MAIN-061', 'Main Meals', 'Beef Preparation', 'Beef prepared as a main meal.', 'General dishes', 7500, true, array[]::text[], false),
    ('MI-MAIN-062', 'Main Meals', 'Pork Preparation', 'Pork prepared as a main meal.', 'General dishes', 7500, true, array[]::text[], false),
    ('MI-MAIN-063', 'Main Meals', 'Ram Preparation', 'Ram prepared as a main meal.', 'General dishes', 9000, true, array[]::text[], false),
    ('MI-MAIN-064', 'Main Meals', 'Seafood Okra', 'Okra soup prepared with seafood.', 'General dishes', 8500, true, array[]::text[], false),
    ('MI-MAIN-065', 'Main Meals', 'Fisherman Soup', 'Fisherman soup served as a main meal.', 'General dishes', 9000, true, array[]::text[], false),
    ('MI-MAIN-066', 'Main Meals', 'Afang Soup', 'Afang soup served as a main meal.', 'General dishes', 8000, true, array[]::text[], false),
    ('MI-MAIN-067', 'Main Meals', 'Beans and Plantain (main plate)', 'Beans served with plantain as a main plate.', 'General dishes', 4500, true, array[]::text[], false),
    ('MI-MAIN-068', 'Main Meals', 'Beans and Yam (main plate)', 'Beans served with yam as a main plate.', 'General dishes', 4500, true, array[]::text[], false),
    ('MI-MAIN-069', 'Main Meals', 'Yam and Egg Sauce (main plate)', 'Yam served with egg sauce as a main plate.', 'General dishes', 5000, true, array[]::text[], false),
    ('MI-MAIN-070', 'Main Meals', 'Plantain Porridge (main serving)', 'Plantain prepared as a main-meal porridge.', 'General dishes', 5000, true, array[]::text[], false),
    ('MI-MAIN-071', 'Main Meals', 'Yam Porridge (main serving)', 'Yam prepared as a main-meal porridge.', 'General dishes', 5000, true, array[]::text[], false),

    ('MI-SNK-001', 'Snacks', 'Meat Pie', 'Pastry filled as a meat pie.', 'Pies and wraps', 1800, true, array[]::text[], false),
    ('MI-SNK-002', 'Snacks', 'Chicken Pie', 'Pastry filled as a chicken pie.', 'Pies and wraps', 1800, true, array[]::text[], false),
    ('MI-SNK-003', 'Snacks', 'Shawarma', 'Shawarma served as a snack wrap.', 'Pies and wraps', 3500, true, array[]::text[], false),
    ('MI-SNK-004', 'Snacks', 'Pizza', 'Pizza served as a snack.', 'Pies and wraps', 3500, true, array[]::text[], false),
    ('MI-SNK-005', 'Snacks', 'Suya (small portion)', 'Suya served as a small snack portion.', 'Suya and grilled bites', 2500, true, array[]::text[], false),
    ('MI-SNK-006', 'Snacks', 'Kilishi (small portion)', 'Kilishi served as a small snack portion.', 'Suya and grilled bites', 2200, true, array[]::text[], false),
    ('MI-SNK-007', 'Snacks', 'Kuli-kuli', 'Kuli-kuli served as a snack.', 'Suya and grilled bites', 1000, true, array[]::text[], false),
    ('MI-SNK-008', 'Snacks', 'Dambu Nama (small portion)', 'Dambu nama served as a small snack portion.', 'Suya and grilled bites', 2200, true, array[]::text[], false),
    ('MI-SNK-009', 'Snacks', 'Akara (snack)', 'Akara bean cakes served as a snack.', 'Local snacks', 1000, true, array[]::text[], false),
    ('MI-SNK-010', 'Snacks', 'Moi Moi (small portion)', 'Moi moi served as a small snack portion.', 'Local snacks', 1800, true, array[]::text[], false),
    ('MI-SNK-011', 'Snacks', 'Masa (snack)', 'Masa rice cakes served as a snack.', 'Local snacks', 1500, true, array[]::text[], false),
    ('MI-SNK-012', 'Snacks', 'Abacha (small portion)', 'Abacha served as a small snack portion.', 'Local snacks', 2000, true, array[]::text[], false),
    ('MI-SNK-013', 'Snacks', 'Nkwobi (small portion)', 'Nkwobi served as a small portion.', 'Local snacks', 3000, true, array[]::text[], false),
    ('MI-SNK-014', 'Snacks', 'Asun (small portion)', 'Asun served as a small snack portion.', 'Local snacks', 3000, true, array[]::text[], false),
    ('MI-SNK-015', 'Snacks', 'Dodo (small portion)', 'Dodo served as a small snack portion.', 'Local snacks', 1200, true, array['vegan']::text[], false),
    ('MI-SNK-016', 'Snacks', 'Boli (small portion)', 'Boli served as a small snack portion.', 'Local snacks', 1500, true, array[]::text[], false),
    ('MI-SNK-017', 'Snacks', 'Okpa (small portion)', 'Okpa served as a small snack portion.', 'Local snacks', 1500, true, array[]::text[], false),
    ('MI-SNK-018', 'Snacks', 'Gurasa (snack)', 'Gurasa served as a snack.', 'Local snacks', 1200, true, array[]::text[], false),
    ('MI-SNK-019', 'Snacks', 'Funkaso (snack)', 'Funkaso served as a snack.', 'Local snacks', 1500, true, array[]::text[], false),

    ('MI-DST-001', 'Desserts', 'Ice Cream', 'Ice cream served as a dessert.', 'Ice cream', 2000, true, array[]::text[], false),
    ('MI-DST-002', 'Desserts', 'Shuku-shuku', 'Shuku-shuku served as a local sweet.', 'Local sweets', 1800, true, array[]::text[], false),
    ('MI-DST-003', 'Desserts', 'Sweetened Plantain', 'Sweetened plantain served as a local dessert.', 'Local sweets', 1800, true, array[]::text[], false),
    ('MI-DST-004', 'Desserts', 'Sweetened Yam', 'Sweetened yam served as a local dessert.', 'Local sweets', 2000, true, array[]::text[], false),
    ('MI-DST-005', 'Desserts', 'Fruit Salad', 'Fruit salad served as a dessert.', 'Local sweets', 2500, true, array[]::text[], false),

    ('MI-DRK-001', 'Drinks', 'Coca-Cola', 'Coca-Cola served as a commercial soft drink.', 'Commercial soft drinks', 700, true, array[]::text[], false),
    ('MI-DRK-002', 'Drinks', 'Fanta', 'Fanta served as a commercial soft drink.', 'Commercial soft drinks', 700, true, array[]::text[], false),
    ('MI-DRK-003', 'Drinks', 'Sprite', 'Sprite served as a commercial soft drink.', 'Commercial soft drinks', 700, true, array[]::text[], false),
    ('MI-DRK-004', 'Drinks', 'Pepsi', 'Pepsi served as a commercial soft drink.', 'Commercial soft drinks', 700, true, array[]::text[], false),
    ('MI-DRK-005', 'Drinks', '7Up', '7Up served as a commercial soft drink.', 'Commercial soft drinks', 700, true, array[]::text[], false),
    ('MI-DRK-006', 'Drinks', 'Teem', 'Teem served as a commercial soft drink.', 'Commercial soft drinks', 700, true, array[]::text[], false),
    ('MI-DRK-007', 'Drinks', 'Bigi Cola', 'Bigi Cola served as a commercial soft drink.', 'Commercial soft drinks', 700, true, array[]::text[], false),
    ('MI-DRK-008', 'Drinks', 'Bigi Orange', 'Bigi Orange served as a commercial soft drink.', 'Commercial soft drinks', 700, true, array[]::text[], false),
    ('MI-DRK-009', 'Drinks', 'Bigi Apple', 'Bigi Apple served as a commercial soft drink.', 'Commercial soft drinks', 700, true, array[]::text[], false),
    ('MI-DRK-010', 'Drinks', 'Bigi (other flavour)', 'A Bigi range soft drink in another flavour.', 'Commercial soft drinks', 700, true, array[]::text[], false),
    ('MI-DRK-011', 'Drinks', 'Schweppes', 'Schweppes served as a commercial drink.', 'Commercial soft drinks', 900, true, array[]::text[], false),
    ('MI-DRK-012', 'Drinks', 'Viju', 'Viju served as a commercial drink.', 'Commercial soft drinks', 900, true, array[]::text[], false),
    ('MI-DRK-013', 'Drinks', 'Malta Guinness', 'Malta Guinness served as a malt drink.', 'Malt drinks', 900, true, array[]::text[], false),
    ('MI-DRK-014', 'Drinks', 'Amstel Malta', 'Amstel Malta served as a malt drink.', 'Malt drinks', 900, true, array[]::text[], false),
    ('MI-DRK-015', 'Drinks', 'Maltina', 'Maltina served as a malt drink.', 'Malt drinks', 900, true, array[]::text[], false),
    ('MI-DRK-016', 'Drinks', 'Fearless Energy Drink', 'Fearless served as an energy drink.', 'Energy drinks and juices', 1500, true, array[]::text[], false),
    ('MI-DRK-017', 'Drinks', 'Energy Drink (other brand)', 'An energy drink from another available brand.', 'Energy drinks and juices', 1500, true, array[]::text[], false),
    ('MI-DRK-018', 'Drinks', 'Chivita Juice', 'Chivita served as a fruit juice.', 'Energy drinks and juices', 1200, true, array[]::text[], false),
    ('MI-DRK-019', 'Drinks', '5 Alive Juice', '5 Alive served as a fruit juice.', 'Energy drinks and juices', 1200, true, array[]::text[], false),
    ('MI-DRK-020', 'Drinks', 'Zobo', 'Hibiscus drink classically prepared with ginger, pineapple and cloves.', 'Traditional and local', 1200, true, array['vegan']::text[], false),
    ('MI-DRK-021', 'Drinks', 'Tiger Nut Drink (Kunu Aya)', 'Tiger nut drink often prepared with dates or coconut.', 'Traditional and local', 1800, true, array[]::text[], false),
    ('MI-DRK-022', 'Drinks', 'Kunu (drink)', 'Kunu made with millet, sorghum or gyada (groundnut).', 'Traditional and local', 1200, true, array[]::text[], false),
    ('MI-DRK-023', 'Drinks', 'Fura da Nono (drink)', 'Fura served with nono as a drink.', 'Traditional and local', 1800, true, array[]::text[], false),
    ('MI-DRK-024', 'Drinks', 'Palm Wine', 'Palm wine served as a traditional drink.', 'Traditional and local', 1500, false, array[]::text[], true),
    ('MI-DRK-025', 'Drinks', 'Chapman (soft version)', 'Chapman prepared as a soft drink.', 'Traditional and local', 1800, true, array[]::text[], false),
    ('MI-DRK-026', 'Drinks', 'Chapman (cocktail version)', 'Chapman prepared as a cocktail.', 'Traditional and local', 3000, true, array[]::text[], true),
    ('MI-DRK-027', 'Drinks', 'Merlot', 'Merlot served as a red wine bottle.', 'Red wine', 25000, true, array[]::text[], true),
    ('MI-DRK-028', 'Drinks', 'Cabernet Sauvignon', 'Cabernet Sauvignon served as a red wine bottle.', 'Red wine', 30000, true, array[]::text[], true),
    ('MI-DRK-029', 'Drinks', 'Shiraz (Syrah)', 'Shiraz (Syrah) served as a red wine bottle.', 'Red wine', 28000, true, array[]::text[], true),
    ('MI-DRK-030', 'Drinks', 'Pinot Noir', 'Pinot Noir served as a red wine bottle.', 'Red wine', 35000, true, array[]::text[], true),
    ('MI-DRK-031', 'Drinks', 'Malbec', 'Malbec served as a red wine bottle.', 'Red wine', 30000, true, array[]::text[], true),
    ('MI-DRK-032', 'Drinks', 'Chianti', 'Chianti served as a red wine bottle.', 'Red wine', 28000, true, array[]::text[], true),
    ('MI-DRK-033', 'Drinks', 'Rioja', 'Rioja served as a red wine bottle.', 'Red wine', 32000, true, array[]::text[], true),
    ('MI-DRK-034', 'Drinks', 'Zinfandel', 'Zinfandel served as a red wine bottle.', 'Red wine', 30000, false, array[]::text[], true),
    ('MI-DRK-035', 'Drinks', 'Tea', 'Tea served as a drink.', 'Other', 700, true, array[]::text[], false),
    ('MI-DRK-036', 'Drinks', 'Water', 'Water served as a drink.', 'Other', 500, true, array[]::text[], false),
    ('MI-DRK-037', 'Drinks', 'Smoothies', 'Smoothies served as a drink.', 'Other', 2000, true, array[]::text[], false),

    ('MI-SPL-001', 'Specials', 'Pepper Soup (goat, special)', 'Goat meat pepper soup served as a special portion.', 'Pepper soups', 12000, true, array[]::text[], false),
    ('MI-SPL-002', 'Specials', 'Pepper Soup (catfish, special)', 'Catfish pepper soup served as a special portion.', 'Pepper soups', 11000, true, array[]::text[], false),
    ('MI-SPL-003', 'Specials', 'Pepper Soup (chicken, special)', 'Chicken pepper soup served as a special portion.', 'Pepper soups', 10000, true, array[]::text[], false),
    ('MI-SPL-004', 'Specials', 'Pepper Soup (snails, special)', 'Pepper snails soup served as a special portion.', 'Pepper soups', 15000, true, array[]::text[], false),
    ('MI-SPL-005', 'Specials', 'Nkwobi (special portion)', 'Nkwobi served as a party and social special.', 'Party and social specials', 12000, true, array[]::text[], false),
    ('MI-SPL-006', 'Specials', 'Isi Ewu (special portion)', 'Isi ewu served as a party and social special.', 'Party and social specials', 16000, true, array[]::text[], false),
    ('MI-SPL-007', 'Specials', 'Asun (special portion)', 'Asun served as a party and social special.', 'Party and social specials', 15000, true, array[]::text[], false),
    ('MI-SPL-008', 'Specials', 'Full Afang Soup', 'A full Afang soup special.', 'Full soups and palm-nut combinations', 22000, true, array[]::text[], false),
    ('MI-SPL-009', 'Specials', 'Fisherman Soup (special)', 'Fisherman soup served as a full special.', 'Full soups and palm-nut combinations', 25000, true, array[]::text[], false),
    ('MI-SPL-010', 'Specials', 'Seafood Okra (special)', 'Seafood okra served as a full special.', 'Full soups and palm-nut combinations', 22000, true, array[]::text[], false),
    ('MI-SPL-011', 'Specials', 'Ofe Owerri (special)', 'Ofe Owerri served as a full special.', 'Full soups and palm-nut combinations', 22000, true, array[]::text[], false),
    ('MI-SPL-012', 'Specials', 'Rich Palm-nut Combination', 'A rich palm-nut combination served as a special.', 'Full soups and palm-nut combinations', 20000, true, array[]::text[], false),
    ('MI-SPL-013', 'Specials', 'Loaded Jollof Tray', 'Loaded jollof tray served with sides such as salad, plantain and proteins.', 'Loaded trays', 25000, true, array[]::text[], false),
    ('MI-SPL-014', 'Specials', 'Loaded Ofada Tray', 'Loaded Ofada tray served with sides such as salad, plantain and proteins.', 'Loaded trays', 28000, true, array[]::text[], false),
    ('MI-SPL-015', 'Specials', 'Paella', 'Paella served as a continental special.', 'Continental specials', 30000, false, array[]::text[], false),
    ('MI-SPL-016', 'Specials', 'Full Roast Platter', 'A full roast platter served as a continental special.', 'Continental specials', 35000, true, array[]::text[], false),
    ('MI-SPL-017', 'Specials', 'Seafood Platter', 'A seafood platter served as a continental special.', 'Continental specials', 35000, true, array[]::text[], false),
    ('MI-SPL-018', 'Specials', 'Premium Steaks', 'Premium steaks served as a continental special.', 'Continental specials', 35000, true, array[]::text[], false),
    ('MI-SPL-019', 'Specials', 'Multi-course Option', 'A multi-course option served as a continental special.', 'Continental specials', 35000, true, array[]::text[], false),
    ('MI-SPL-020', 'Specials', 'Garden Salad', 'Garden salad served as a special, with optional proteins.', 'Salads', 9000, true, array[]::text[], false),
    ('MI-SPL-021', 'Specials', 'Nigerian-style Salad', 'Nigerian-style salad served as a special, with optional proteins.', 'Salads', 10000, true, array[]::text[], false)
)
insert into public.menu_items (
  reference, category_id, name, description, subcategory, price,
  photo_url, dietary_flags, contains_alcohol, is_available, display_order
)
select
  menu.reference,
  category.id,
  menu.name,
  menu.description,
  menu.subcategory,
  menu.price,
  null,
  menu.dietary_flags,
  menu.contains_alcohol,
  menu.is_available,
  substring(menu.reference from '[0-9]+$')::integer
from menu_rows as menu
join public.categories as category on category.name = menu.category_name
on conflict (reference) do nothing;

with variation_rows (reference, name, description, price_adjustment) as (
  values
    ('MI-MAIN-001', 'Small', 'Small portion.', -500),
    ('MI-MAIN-001', 'Regular', 'Regular portion.', 0),
    ('MI-MAIN-001', 'Large', 'Large portion.', 1500),
    ('MI-MAIN-002', 'Small', 'Small portion.', -500),
    ('MI-MAIN-002', 'Regular', 'Regular portion.', 0),
    ('MI-MAIN-002', 'Large', 'Large portion.', 1500),
    ('MI-MAIN-003', 'Small', 'Small portion.', -500),
    ('MI-MAIN-003', 'Regular', 'Regular portion.', 0),
    ('MI-MAIN-003', 'Large', 'Large portion.', 1500),
    ('MI-MAIN-036', 'Small', 'Small portion.', -500),
    ('MI-MAIN-036', 'Regular', 'Regular portion.', 0),
    ('MI-MAIN-036', 'Large', 'Large portion.', 1500),
    ('MI-MAIN-037', 'Small', 'Small portion.', -500),
    ('MI-MAIN-037', 'Regular', 'Regular portion.', 0),
    ('MI-MAIN-037', 'Large', 'Large portion.', 1500),
    ('MI-MAIN-038', 'Small', 'Small portion.', -500),
    ('MI-MAIN-038', 'Regular', 'Regular portion.', 0),
    ('MI-MAIN-038', 'Large', 'Large portion.', 1500),
    ('MI-MAIN-050', 'Small', 'Small portion.', -500),
    ('MI-MAIN-050', 'Regular', 'Regular portion.', 0),
    ('MI-MAIN-050', 'Large', 'Large portion.', 1500),
    ('MI-MAIN-065', 'Small', 'Small portion.', -1000),
    ('MI-MAIN-065', 'Regular', 'Regular portion.', 0),
    ('MI-MAIN-065', 'Large', 'Large portion.', 2000),
    ('MI-MAIN-054', 'Goat', 'Goat meat pepper soup.', 0),
    ('MI-MAIN-054', 'Chicken', 'Chicken pepper soup.', -1000),
    ('MI-MAIN-054', 'Catfish', 'Catfish pepper soup.', -500),
    ('MI-MAIN-054', 'Snails', 'Pepper snails soup.', 1000),
    ('MI-BRK-004', 'Aya / Tiger Nut', 'Kunu made with aya or tiger nut.', 300),
    ('MI-BRK-004', 'Gyada / Groundnut', 'Kunu made with gyada or groundnut.', 0),
    ('MI-BRK-004', 'Millet / Sorghum', 'Kunu made with millet or sorghum.', 0),
    ('MI-DRK-022', 'Aya / Tiger Nut', 'Kunu made with aya or tiger nut.', 300),
    ('MI-DRK-022', 'Gyada / Groundnut', 'Kunu made with gyada or groundnut.', 0),
    ('MI-DRK-022', 'Millet / Sorghum', 'Kunu made with millet or sorghum.', 0)
)
insert into public.menu_variations (menu_item_id, name, description, price_adjustment)
select item.id, variation.name, variation.description, variation.price_adjustment
from variation_rows as variation
join public.menu_items as item on item.reference = variation.reference
on conflict (menu_item_id, name) do nothing;

with addon_rows (reference, name, description, price) as (
  values
    ('MI-MAIN-001', 'Extra Protein', 'Add an extra protein serving.', 2000),
    ('MI-MAIN-001', 'Plantain', 'Add a plantain side.', 1000),
    ('MI-MAIN-001', 'Extra Pepper Sauce', 'Add extra pepper sauce.', 500),
    ('MI-MAIN-001', 'Extra Egg', 'Add an extra egg.', 700),
    ('MI-MAIN-003', 'Extra Protein', 'Add an extra protein serving.', 2000),
    ('MI-MAIN-003', 'Plantain', 'Add a plantain side.', 1000),
    ('MI-MAIN-003', 'Extra Pepper Sauce', 'Add extra pepper sauce.', 500),
    ('MI-MAIN-003', 'Extra Egg', 'Add an extra egg.', 700),
    ('MI-MAIN-036', 'Extra Protein', 'Add an extra protein serving.', 2000),
    ('MI-MAIN-036', 'Plantain', 'Add a plantain side.', 1000),
    ('MI-MAIN-036', 'Extra Pepper Sauce', 'Add extra pepper sauce.', 500),
    ('MI-MAIN-036', 'Extra Egg', 'Add an extra egg.', 700),
    ('MI-MAIN-037', 'Extra Protein', 'Add an extra protein serving.', 2000),
    ('MI-MAIN-037', 'Plantain', 'Add a plantain side.', 1000),
    ('MI-MAIN-037', 'Extra Pepper Sauce', 'Add extra pepper sauce.', 500),
    ('MI-MAIN-037', 'Extra Egg', 'Add an extra egg.', 700),
    ('MI-MAIN-038', 'Extra Protein', 'Add an extra protein serving.', 2000),
    ('MI-MAIN-038', 'Plantain', 'Add a plantain side.', 1000),
    ('MI-MAIN-038', 'Extra Pepper Sauce', 'Add extra pepper sauce.', 500),
    ('MI-MAIN-038', 'Extra Egg', 'Add an extra egg.', 700),
    ('MI-MAIN-050', 'Extra Protein', 'Add an extra protein serving.', 2000),
    ('MI-MAIN-050', 'Plantain', 'Add a plantain side.', 1000),
    ('MI-MAIN-050', 'Extra Pepper Sauce', 'Add extra pepper sauce.', 500),
    ('MI-MAIN-050', 'Extra Egg', 'Add an extra egg.', 700),
    ('MI-MAIN-065', 'Extra Protein', 'Add an extra protein serving.', 2500),
    ('MI-MAIN-065', 'Plantain', 'Add a plantain side.', 1000),
    ('MI-MAIN-065', 'Extra Pepper Sauce', 'Add extra pepper sauce.', 500),
    ('MI-MAIN-065', 'Extra Egg', 'Add an extra egg.', 700),
    ('MI-MAIN-054', 'Extra Protein', 'Add an extra protein serving.', 2500),
    ('MI-MAIN-054', 'Plantain', 'Add a plantain side.', 1000),
    ('MI-MAIN-054', 'Extra Pepper Sauce', 'Add extra pepper sauce.', 500),
    ('MI-MAIN-054', 'Extra Egg', 'Add an extra egg.', 700)
)
insert into public.menu_addons (menu_item_id, name, description, price)
select item.id, addon.name, addon.description, addon.price
from addon_rows as addon
join public.menu_items as item on item.reference = addon.reference
on conflict (menu_item_id, name) do nothing;

with ingredient_rows (
  reference, name, unit, quantity, minimum_level, expiry_days, supplier_name
) as (
  values
    ('ING-001', 'Goat', 'kg', 35, 5, 5, 'Sample Proteins Ltd'),
    ('ING-002', 'Beef', 'kg', 40, 5, 5, 'Sample Proteins Ltd'),
    ('ING-003', 'Chicken', 'kg', 35, 5, 4, 'Sample Proteins Ltd'),
    ('ING-004', 'Turkey', 'kg', 25, 4, 4, 'Sample Proteins Ltd'),
    ('ING-005', 'Ram', 'kg', 20, 3, 5, 'Sample Proteins Ltd'),
    ('ING-006', 'Pork', 'kg', 18, 3, 4, 'Sample Proteins Ltd'),
    ('ING-007', 'Fresh Catfish', 'kg', 30, 5, 2, 'Sample Proteins Ltd'),
    ('ING-008', 'Stockfish', 'kg', 20, 3, null, 'Sample Proteins Ltd'),
    ('ING-009', 'Dried Fish', 'kg', 15, 2, null, 'Sample Proteins Ltd'),
    ('ING-010', 'Snails', 'kg', 18, 3, 3, 'Sample Proteins Ltd'),
    ('ING-011', 'Offals', 'kg', 15, 2, 3, 'Sample Proteins Ltd'),
    ('ING-012', 'Eggs', 'piece', 180, 24, 21, 'Sample Proteins Ltd'),
    ('ING-013', 'Prawns and Seafood', 'kg', 25, 4, 2, 'Sample Proteins Ltd'),
    ('ING-014', 'Long-grain Rice', 'kg', 100, 15, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-015', 'Ofada Rice', 'kg', 45, 8, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-016', 'Local Rice', 'kg', 45, 8, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-017', 'Yam', 'kg', 90, 15, 30, 'Sample Fresh Produce Co'),
    ('ING-018', 'Ripe Plantain', 'kg', 60, 10, 5, 'Sample Fresh Produce Co'),
    ('ING-019', 'Unripe Plantain', 'kg', 50, 8, 8, 'Sample Fresh Produce Co'),
    ('ING-020', 'Black-eyed Beans', 'kg', 55, 8, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-021', 'Brown Beans', 'kg', 45, 8, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-022', 'Garri', 'kg', 55, 8, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-023', 'Akpu Cassava', 'kg', 35, 6, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-024', 'Lafun', 'kg', 30, 5, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-025', 'Maize Flour', 'kg', 45, 7, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-026', 'Millet Flour', 'kg', 35, 6, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-027', 'Sorghum Flour', 'kg', 35, 6, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-028', 'Wheat Flour', 'kg', 60, 10, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-029', 'Potatoes', 'kg', 45, 8, 14, 'Sample Fresh Produce Co'),
    ('ING-030', 'Egusi (Melon Seeds)', 'kg', 30, 5, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-031', 'Ogbono', 'kg', 20, 4, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-032', 'Cocoyam', 'kg', 30, 5, 14, 'Sample Fresh Produce Co'),
    ('ING-033', 'Ofor / Achi', 'kg', 18, 3, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-034', 'Palm Nuts', 'kg', 35, 6, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-035', 'Okra', 'kg', 35, 6, 5, 'Sample Fresh Produce Co'),
    ('ING-036', 'Baobab Leaves (Kuka)', 'kg', 10, 2, null, 'Sample Dry Goods and Drinks Co'),
    ('ING-037', 'Oha', 'kg', 12, 2, 4, 'Sample Fresh Produce Co'),
    ('ING-038', 'Onugbu (Bitterleaf)', 'kg', 15, 3, 5, 'Sample Fresh Produce Co'),
    ('ING-039', 'Ugu', 'kg', 20, 4, 4, 'Sample Fresh Produce Co'),
    ('ING-040', 'Spinach / Efo', 'kg', 20, 4, 4, 'Sample Fresh Produce Co'),
    ('ING-041', 'Waterleaf', 'kg', 15, 3, 3, 'Sample Fresh Produce Co'),
    ('ING-042', 'Afang Leaves', 'kg', 15, 3, 4, 'Sample Fresh Produce Co'),
    ('ING-043', 'Tomatoes', 'kg', 70, 12, 7, 'Sample Fresh Produce Co'),
    ('ING-044', 'Fresh Peppers', 'kg', 40, 8, 7, 'Sample Fresh Produce Co'),
    ('ING-045', 'Onions', 'kg', 55, 10, 14, 'Sample Fresh Produce Co')
)
insert into public.ingredients (
  reference, name, unit, quantity, minimum_level, expiry_date, supplier_id
)
select
  ingredient.reference,
  ingredient.name,
  ingredient.unit,
  ingredient.quantity,
  ingredient.minimum_level,
  case
    when ingredient.expiry_days is null then null
    else current_date + ingredient.expiry_days
  end,
  supplier.id
from ingredient_rows as ingredient
join public.suppliers as supplier on supplier.name = ingredient.supplier_name
on conflict (reference) do nothing;

with recipe_rows (menu_reference, ingredient_reference, quantity_required) as (
  values
    ('MI-MAIN-001', 'ING-014', 0.250::numeric),
    ('MI-MAIN-001', 'ING-043', 0.100::numeric),
    ('MI-MAIN-001', 'ING-044', 0.030::numeric),
    ('MI-MAIN-001', 'ING-045', 0.040::numeric),
    ('MI-MAIN-001', 'ING-012', 1.000::numeric),
    ('MI-MAIN-037', 'ING-030', 0.100::numeric),
    ('MI-MAIN-037', 'ING-017', 0.250::numeric),
    ('MI-MAIN-037', 'ING-044', 0.020::numeric),
    ('MI-MAIN-037', 'ING-045', 0.030::numeric),
    ('MI-MAIN-003', 'ING-037', 0.080::numeric),
    ('MI-MAIN-003', 'ING-007', 0.180::numeric),
    ('MI-MAIN-003', 'ING-032', 0.080::numeric),
    ('MI-MAIN-003', 'ING-045', 0.030::numeric),
    ('MI-MAIN-036', 'ING-040', 0.120::numeric),
    ('MI-MAIN-036', 'ING-043', 0.100::numeric),
    ('MI-MAIN-036', 'ING-002', 0.150::numeric),
    ('MI-MAIN-036', 'ING-045', 0.030::numeric),
    ('MI-MAIN-054', 'ING-001', 0.220::numeric),
    ('MI-MAIN-054', 'ING-044', 0.025::numeric),
    ('MI-MAIN-054', 'ING-045', 0.025::numeric),
    ('MI-MAIN-026', 'ING-002', 0.250::numeric),
    ('MI-MAIN-026', 'ING-044', 0.020::numeric),
    ('MI-MAIN-026', 'ING-045', 0.020::numeric),
    ('MI-SNK-009', 'ING-020', 0.120::numeric),
    ('MI-SNK-009', 'ING-045', 0.015::numeric),
    ('MI-SNK-009', 'ING-044', 0.010::numeric),
    ('MI-SNK-009', 'ING-028', 0.020::numeric),
    ('MI-SNK-010', 'ING-020', 0.150::numeric),
    ('MI-SNK-010', 'ING-044', 0.015::numeric),
    ('MI-SNK-010', 'ING-045', 0.020::numeric),
    ('MI-MAIN-038', 'ING-015', 0.250::numeric),
    ('MI-MAIN-038', 'ING-002', 0.150::numeric),
    ('MI-MAIN-038', 'ING-043', 0.080::numeric),
    ('MI-MAIN-038', 'ING-044', 0.020::numeric),
    ('MI-BRK-012', 'ING-017', 0.250::numeric),
    ('MI-BRK-012', 'ING-012', 2.000::numeric),
    ('MI-BRK-012', 'ING-043', 0.080::numeric),
    ('MI-BRK-012', 'ING-045', 0.020::numeric),
    ('MI-SNK-001', 'ING-028', 0.100::numeric),
    ('MI-SNK-001', 'ING-002', 0.080::numeric),
    ('MI-SNK-001', 'ING-029', 0.050::numeric),
    ('MI-SNK-003', 'ING-003', 0.150::numeric),
    ('MI-SNK-003', 'ING-028', 0.100::numeric),
    ('MI-SNK-003', 'ING-043', 0.050::numeric),
    ('MI-DRK-020', 'ING-044', 0.005::numeric),
    ('MI-DRK-020', 'ING-043', 0.050::numeric),
    ('MI-MAIN-046', 'ING-018', 0.250::numeric),
    ('MI-MAIN-046', 'ING-028', 0.010::numeric),
    ('MI-BRK-008', 'ING-025', 0.100::numeric),
    ('MI-BRK-008', 'ING-020', 0.100::numeric),
    ('MI-BRK-008', 'ING-044', 0.010::numeric),
    ('MI-BRK-008', 'ING-045', 0.010::numeric)
)
insert into public.recipes (menu_item_id, ingredient_id, quantity_required)
select item.id, ingredient.id, recipe.quantity_required
from recipe_rows as recipe
join public.menu_items as item on item.reference = recipe.menu_reference
join public.ingredients as ingredient on ingredient.reference = recipe.ingredient_reference
on conflict (menu_item_id, ingredient_id) do nothing;

insert into public.tables (table_number, capacity)
values
  ('T01', 2),
  ('T02', 2),
  ('T03', 4),
  ('T04', 4),
  ('T05', 6),
  ('T06', 6),
  ('T07', 8),
  ('T08', 8)
on conflict (table_number) do nothing;

insert into public.customers (name, email, auth_user_id)
select customer.name, customer.email, null
from (
  values
    ('Sample Customer 01', 'customer01@example.test'),
    ('Sample Customer 02', 'customer02@example.test'),
    ('Sample Customer 03', 'customer03@example.test'),
    ('Sample Customer 04', 'customer04@example.test'),
    ('Sample Customer 05', 'customer05@example.test')
) as customer(name, email)
where not exists (
  select 1 from public.customers existing where existing.email = customer.email
);

-- Items without recipe rows intentionally do not deduct stock on confirmation.
-- No orders, payments, or reservations are inserted by this seed.

commit;
