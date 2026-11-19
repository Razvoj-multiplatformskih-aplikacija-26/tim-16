-- Početni podaci, isti kao lažni podaci iz KT1: nalozi obe uloge,
-- deset proizvoda i deset porudžbina, bar jedna u svakom stanju.

-- migrate:up
INSERT INTO users (id, full_name, role) VALUES
  ('u-buyer-1', 'Marko Petrović', 'buyer'),
  ('u-buyer-2', 'Jelena Jovanović', 'buyer'),
  ('pr-1', 'Bojan Matić', 'producer'),
  ('pr-2', 'Gazdinstvo Petrović', 'producer'),
  ('pr-3', 'Farma koza', 'producer'),
  ('pr-4', 'Farma koka', 'producer'),
  ('pr-5', 'Mlekara M', 'producer'),
  ('pr-6', 'Gazdinstvo Ilić', 'producer'),
  ('pr-7', 'Voćar doo', 'producer'),
  ('pr-8', 'Baka Nada', 'producer'),
  ('pr-9', 'Primorje', 'producer');

INSERT INTO products (id, producer_id, name, description, category, unit, price_dinars, stock_units, image_url, created_at) VALUES
  ('p1', 'pr-1', 'Domaće maline', 'Sveže maline iz Arilja.', 'fruit', 'kilogram', 150, 10, 'https://commons.wikimedia.org/wiki/Special:FilePath/Raspberries_(Rubus_idaeus).jpg?width=500', '2026-10-01 08:00+01'),
  ('p2', 'pr-2', 'Med', 'Prirodni livadski med.', 'honey', 'jar', 800, 5, 'https://commons.wikimedia.org/wiki/Special:FilePath/Runny_hunny.jpg?width=500', '2026-10-01 08:01+01'),
  ('p3', 'pr-3', 'Sir kozji', 'Stari kozji sir.', 'dairy', 'kilogram', 1200, 2, 'https://commons.wikimedia.org/wiki/Special:FilePath/Goat_Cheese.jpg?width=500', '2026-10-01 08:02+01'),
  ('p4', 'pr-4', 'Domaća jaja', 'Slobodan uzgoj.', 'dairy', 'piece', 20, 30, 'https://commons.wikimedia.org/wiki/Special:FilePath/Eggs_in_a_cardboard_box.jpg?width=500', '2026-10-01 08:03+01'),
  ('p5', 'pr-5', 'Kravlji sir', 'Mladi domaći kravlji sir.', 'dairy', 'kilogram', 800, 5, 'https://commons.wikimedia.org/wiki/Special:FilePath/Feta_Cheese.jpg?width=500', '2026-10-01 08:04+01'),
  ('p6', 'pr-6', 'Krompir', 'Beli krompir, odličan za pečenje.', 'vegetables', 'kilogram', 100, 50, 'https://commons.wikimedia.org/wiki/Special:FilePath/Potato_and_halves.jpg?width=500', '2026-10-01 08:05+01'),
  ('p7', 'pr-7', 'Sok od jabuke', '100% prirodni sok bez šećera.', 'preserves', 'liter', 300, 15, 'https://commons.wikimedia.org/wiki/Special:FilePath/Apple_juice.jpg?width=500', '2026-10-01 08:06+01'),
  ('p8', 'pr-1', 'Orah očišćen', 'Sveže očišćeni orasi.', 'fruit', 'kilogram', 1500, 4, 'https://commons.wikimedia.org/wiki/Special:FilePath/Walnut.jpg?width=500', '2026-10-01 08:07+01'),
  ('p9', 'pr-8', 'Džem od šljiva', 'Domaći džem spreman po tradicionalnom receptu.', 'preserves', 'jar', 450, 8, 'https://commons.wikimedia.org/wiki/Special:FilePath/Damson_jam.jpg?width=500', '2026-10-01 08:08+01'),
  -- Poslednji komad: za demonstraciju dva kupca koja istovremeno poručuju isti proizvod.
  ('p10', 'pr-9', 'Suve smokve', 'Slatke suve smokve iz uvoza, pakovane lokalno.', 'fruit', 'kilogram', 600, 1, 'https://commons.wikimedia.org/wiki/Special:FilePath/Dried_Figs.jpg?width=500', '2026-10-01 08:09+01');

INSERT INTO orders (id, buyer_id, producer_id, status, status_at, cancel_reason, method, address, created_at) VALUES
  ('o-1001', 'u-buyer-1', 'pr-1', 'pending', NULL, NULL, 'pickup', NULL, '2026-11-02 18:30+01'),
  ('o-1002', 'u-buyer-1', 'pr-2', 'accepted', '2026-11-02 13:00+01', NULL, 'delivery', 'Knez Mihailova 12, Beograd', '2026-11-02 12:00+01'),
  ('o-1003', 'u-buyer-1', 'pr-4', 'preparing', NULL, NULL, 'pickup', NULL, '2026-11-01 09:15+01'),
  ('o-1004', 'u-buyer-1', 'pr-3', 'shipped', '2026-11-01 08:00+01', NULL, 'delivery', 'Bulevar kralja Aleksandra 45, Beograd', '2026-10-31 17:45+01'),
  ('o-1005', 'u-buyer-1', 'pr-1', 'delivered', NULL, NULL, 'delivery', 'Takovska 7, Beograd', '2026-10-27 10:00+01'),
  ('o-1006', 'u-buyer-1', 'pr-6', 'delivered', NULL, NULL, 'pickup', NULL, '2026-10-24 15:20+01'),
  ('o-1007', 'u-buyer-2', 'pr-7', 'delivered', NULL, NULL, 'delivery', 'Resavska 30, Beograd', '2026-10-20 11:05+01'),
  ('o-1008', 'u-buyer-1', 'pr-5', 'cancelled', NULL, 'by_buyer', 'pickup', NULL, '2026-10-29 19:00+01'),
  ('o-1009', 'u-buyer-2', 'pr-8', 'cancelled', NULL, 'by_buyer', 'pickup', NULL, '2026-10-22 08:40+01'),
  ('o-1010', 'u-buyer-2', 'pr-9', 'cancelled', NULL, 'by_producer', 'pickup', NULL, '2026-10-18 14:10+01');

INSERT INTO order_lines (order_id, position, product_id, product_name, unit_price_dinars, quantity) VALUES
  ('o-1001', 0, 'p1', 'Domaće maline', 150, 2),
  ('o-1002', 0, 'p2', 'Med', 800, 1),
  ('o-1003', 0, 'p4', 'Domaća jaja', 20, 12),
  ('o-1004', 0, 'p3', 'Sir kozji', 1200, 1),
  ('o-1005', 0, 'p1', 'Domaće maline', 150, 3),
  ('o-1005', 1, 'p8', 'Orah očišćen', 1500, 1),
  ('o-1006', 0, 'p6', 'Krompir', 100, 10),
  ('o-1007', 0, 'p7', 'Sok od jabuke', 300, 4),
  ('o-1008', 0, 'p5', 'Kravlji sir', 800, 1),
  ('o-1009', 0, 'p9', 'Džem od šljiva', 450, 1),
  ('o-1010', 0, 'p10', 'Suve smokve', 600, 2);

-- migrate:down
DELETE FROM order_lines;
DELETE FROM orders;
DELETE FROM products;
DELETE FROM users;
