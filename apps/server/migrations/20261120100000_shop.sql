-- migrate:up
CREATE TABLE users (
  id text PRIMARY KEY,
  full_name text NOT NULL,
  role text NOT NULL CHECK (role IN ('buyer', 'producer'))
);

CREATE TABLE products (
  id text PRIMARY KEY,
  producer_id text NOT NULL REFERENCES users (id),
  name text NOT NULL,
  description text NOT NULL DEFAULT '',
  category text NOT NULL CHECK (category IN ('fruit', 'vegetables', 'dairy', 'honey', 'preserves')),
  unit text NOT NULL CHECK (unit IN ('kilogram', 'piece', 'liter', 'jar')),
  price_dinars int NOT NULL,
  stock_units int NOT NULL,
  published boolean NOT NULL DEFAULT true,
  image_url text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX products_by_producer ON products (producer_id);

CREATE TABLE orders (
  id text PRIMARY KEY,
  buyer_id text NOT NULL REFERENCES users (id),
  producer_id text NOT NULL REFERENCES users (id),
  status text NOT NULL CHECK (status IN ('pending', 'accepted', 'preparing', 'shipped', 'delivered', 'cancelled')),
  -- Vreme prihvatanja (accepted) ili slanja (shipped); za ostala stanja NULL.
  status_at timestamptz,
  cancel_reason text CHECK (cancel_reason IN ('by_buyer', 'by_producer')),
  method text NOT NULL CHECK (method IN ('pickup', 'delivery')),
  address text,
  created_at timestamptz NOT NULL,
  CONSTRAINT orders_cancel_reason CHECK ((status = 'cancelled') = (cancel_reason IS NOT NULL)),
  CONSTRAINT orders_delivery_address CHECK (method = 'pickup' OR address IS NOT NULL)
);

CREATE INDEX orders_by_buyer ON orders (buyer_id);
CREATE INDEX orders_by_producer ON orders (producer_id);

-- Stavka je snimak proizvoda u trenutku porudžbine (naziv i cena), pa nema
-- stranog ključa na products: kasnija izmena ili brisanje proizvoda ne menja porudžbinu.
CREATE TABLE order_lines (
  order_id text NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  position int NOT NULL,
  product_id text NOT NULL,
  product_name text NOT NULL,
  unit_price_dinars int NOT NULL,
  quantity int NOT NULL CHECK (quantity > 0),
  PRIMARY KEY (order_id, product_id),
  UNIQUE (order_id, position)
);

-- migrate:down
DROP TABLE order_lines;
DROP TABLE orders;
DROP TABLE products;
DROP TABLE users;
