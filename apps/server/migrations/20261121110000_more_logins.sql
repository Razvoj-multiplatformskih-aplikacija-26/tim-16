-- Nalog za proizvođača pr-9 (suve smokve, p10), da skripta poslednji_komad
-- može da vrati zalihu na 1 kao vlasnik proizvoda.

-- migrate:up
UPDATE users SET login = 'proizvodjac9' WHERE id = 'pr-9';

-- migrate:down
UPDATE users SET login = NULL WHERE id = 'pr-9';