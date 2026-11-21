-- migrate:up
ALTER TABLE users ADD COLUMN login text UNIQUE;
ALTER TABLE users ADD COLUMN password_hash text;

UPDATE users SET login = v.login
FROM (VALUES
  ('u-buyer-1', 'kupac1'),
  ('u-buyer-2', 'kupac2'),
  ('pr-1', 'proizvodjac1'),
  ('pr-2', 'proizvodjac2')
) AS v (id, login)
WHERE users.id = v.id;

-- migrate:down
ALTER TABLE users DROP COLUMN password_hash;
ALTER TABLE users DROP COLUMN login;