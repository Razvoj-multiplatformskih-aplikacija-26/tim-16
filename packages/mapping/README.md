# mapping — prevod između ugovora i domena

Jedino mesto gde se tipovi iz [`contract`](../contract) prevode u domenske
modele iz [`domain`](../domain) i nazad. Koriste ga server i oba klijenta, pa
ne može da se desi da server pošalje jedno, a aplikacija pročita drugo.

| Smer | Server | Klijent |
|---|---|---|
| Domen → ugovor | `productToDto`, `orderToDto`, `producerToDto`, `problemOf` | `placeOrderRequestOf`, `changeStatusRequestOf`, `createProductRequestOf` |
| Ugovor → domen | `orderRequestLinesOf`, `targetStatusOf`, `categoryFromCode`, `dinarsOf` | `productFromDto`, `orderFromDto`, `producerFromDto`, `domainErrorOf` |

## Put jedne greške

```
server:  placeOrder(...)  →  QuantityExceedsStock(requested: 3, available: 1)
         problemOf(error) →  {"status":409,"code":"quantity_exceeds_stock","params":{"requested":3,"available":1}}
klijent: domainErrorOf(problem) → QuantityExceedsStock(requested: 3, available: 1)
         error.message          → „Nedovoljna količina na stanju. Dostupno je 1.“
```

Poruka (`DomainErrorMessage` u paketu `blocs`) je ista kao kada aplikacija sama
proveri pravilo, jer polazi od iste domenske greške.

## Stara verzija aplikacije

- `domainErrorOf` vraća `null` za kôd koji ne poznaje ili za podatke u
  drugom obliku; aplikacija tada pokazuje opštu poruku.
- `orderFromDto` / `productFromDto` bacaju `WireFormatException` za stanje
  ili kategoriju koju ne poznaju; aplikacija taj zapis preskoči.
- Kodovi na mreži (`fruit`, `pickup`, `accepted`…) su zapisani ovde, ne
  izvedeni iz imena Dart enum-a, pa preimenovanje u domenu ne menja ugovor.
