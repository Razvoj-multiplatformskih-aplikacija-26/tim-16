# contract — ugovor između klijenata i servera

Jedan Dart paket opisuje sve što ide preko mreže: zahteve, odgovore i greške.
Koriste ga server, mobilna aplikacija i backoffice. Paket **ne uvozi** domenski
paket, Flutter ni `dart:io`, pa radi svuda (i u pregledaču).

Prevod između ovih tipova i domena je na jednom mestu, u paketu
[`mapping`](../mapping).

## Kako na mreži izgledaju

| Šta | Oblik | Zašto |
|---|---|---|
| Novac | `{"amount": 150, "currency": "RSD"}` | ceo broj, bez zaokruživanja; valuta uvek navedena |
| Vreme | `"2026-11-02T12:00:00.000Z"` | ISO 8601 u UTC; vreme bez zone se odbija |
| Stanje porudžbine | `{"code": "accepted", "at": "…"}`, `{"code": "cancelled", "cancelledBy": "buyer"}` | kôd je tekst, pa stara aplikacija pročita i stanje koje ne poznaje |
| Kategorija, jedinica, način preuzimanja | `"fruit"`, `"kilogram"`, `"pickup"` | stabilni kodovi, ne imena Dart enum-a |
| Greška | `{"status": 409, "code": "…", "params": {…}, "title": "…"}` | klijent poruku pravi od `code` i `params`; `title` je samo za logove |
| Deo liste | `?limit=20&cursor=…` → `{"items": […], "nextCursor": "…"}` | kursor ne preskače i ne ponavlja zapise kada se lista menja |

## Šta vidi koja uloga

| Zapis | Posetilac / kupac | Proizvođač (vlasnik) |
|---|---|---|
| Proizvođač (`/producers`) | `id`, `fullName` | isto |
| Proizvod (`/products`) | samo objavljeni, bez `published` | svoje proizvode i neobjavljene, sa `published` (`/my/products`) |
| Porudžbina (`/orders`) | samo svoje | samo one iz svoje ponude |

Tuđa porudžbina se ne razlikuje od nepostojeće (`order_not_found`).

## Pravila za izmene ugovora

- Novo polje u odgovoru je dozvoljeno: stari klijent ga ne čita.
- Novi kôd stanja, kategorije ili greške je dozvoljen: stari klijent ga
  prepoznaje kao nepoznat i ne pada (vidi `mapping` i `HttpShopRepository`).
- Brisanje ili preimenovanje polja i promena tipa **nisu** dozvoljeni bez
  nove verzije API-ja.
