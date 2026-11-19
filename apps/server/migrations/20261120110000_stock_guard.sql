-- Poslednja zaštita u bazi. Pravila proverava server kroz domen, nad
-- zaključanim redovima; ova ograničenja hvataju upis koji bi to zaobišao.

-- migrate:up
ALTER TABLE products
  ADD CONSTRAINT products_stock_not_negative CHECK (stock_units >= 0),
  ADD CONSTRAINT products_price_positive CHECK (price_dinars > 0);

-- migrate:down
ALTER TABLE products
  DROP CONSTRAINT products_price_positive,
  DROP CONSTRAINT products_stock_not_negative;
