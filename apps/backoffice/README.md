# Svezko Backoffice

Samostalna Flutter aplikacija za proizvođače. Aplikacija koristi zajedničke
`domain` modele i pravila, kao i `blocs` interfejse za stanje i pristup podacima.

## Struktura

- `lib/main.dart` — composition root: instanciranje repozitorijuma i Bloc-a.
- `lib/app.dart` — tema i router aplikacije.
- `lib/router.dart` — rute backoffice ekrana.
- `lib/features/dashboard/` — pregled poslovanja.
- `lib/features/products/` — upravljanje ponudom.
- `lib/features/orders/` — obrada porudžbina.
- `lib/shared/` — zajednički layout i UI komponente.
- `lib/data/` — konkretni adapteri `ShopRepository`-ja; sada demo, kasnije API.

Pokretanje iz korena repozitorijuma: `flutter run -d windows -t apps/backoffice/lib/main.dart`.
