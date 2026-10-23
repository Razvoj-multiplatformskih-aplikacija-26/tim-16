# Svežko — Platforma za domaće proizvode

Svežko je multiplatformska aplikacija za prodaju lokalnih poljoprivrednih i domaćih proizvoda koja povezuje lokalne proizvođače sa kupcima. Proizvođači objavljuju proizvode, određuju cene i dostupne količine, obrađuju porudžbine i organizuju isporuku, dok kupci pretražuju ponudu, poručuju proizvode i prate status svojih porudžbina.

Cilj aplikacije je da olakša prodaju domaćih proizvoda, omogući kupcima jednostavan pristup lokalnoj ponudi i unapredi saradnju između kupaca i proizvođača.


## Tim

| Ime i prezime | Broj indeksa | GitHub nalog |
|---|---|---|
| Sava Arsenijević | 79/24/SI | [@egkngm](https://github.com/egkngm) |
| Mateja Matić | 103/24/SI | [@mmatic161](https://github.com/mmatic161) |

## Zahtevi za temu

### 1. Uloge

Sistem koriste kupci i proizvođači, sa različitim ovlašćenjima.

- **Kupac** pregleda javnu ponudu, pretražuje proizvode, dodaje ih u korpu, kreira porudžbine i prati njihov status.
- **Proizvođač** objavljuje i uređuje svoje proizvode, određuje cene i dostupne količine, obrađuje porudžbine i upravlja pripremom i isporukom.

Kupac može da upravlja svojim porudžbinama, ali ne može da menja proizvode i cene drugih proizvođača. Proizvođač može da upravlja samo svojim proizvodima i porudžbinama koje pripadaju njegovoj ponudi.

### 2. Stanja

Porudžbina prolazi kroz više stanja tokom svog životnog ciklusa:

- **Na čekanju (`Pending`)** — kupac je kreirao porudžbinu, a proizvođač još nije odlučio da li može da je prihvati.
- **Prihvaćena (`Accepted`)** — proizvođač je prihvatio porudžbinu.
- **U pripremi (`Preparing`)** — proizvodi se pripremaju za isporuku ili preuzimanje.
- **Poslata (`Shipped`)** — porudžbina je predata dostavljaču ili je otpremljena.
- **Isporučena (`Delivered`)** — isporuka je završena.
- **Otkazana (`Cancelled`)** — porudžbina je otkazana u skladu sa pravilima sistema.

Promene stanja odvijaju se prema unapred definisanim pravilima. Na primer, isporučena porudžbina ne može ponovo da pređe u stanje „Na čekanju“.

### 3. Pravila

Sistem primenjuje poslovna pravila koja određuju koje operacije su dozvoljene:

- Cena proizvoda mora biti u dozvoljenom opsegu.
- Dostupna količina proizvoda ne može biti negativna.
- Kupac ne može da poruči veću količinu proizvoda od one koja je dostupna.
- Proizvođač može da menja samo svoje proizvode i da obrađuje porudžbine koje pripadaju njegovoj ponudi.
- Porudžbina može da pređe u novo stanje samo ako je taj prelaz dozvoljen.
- Otkazivanje porudžbine dozvoljeno je samo u stanjima u kojima poslovna pravila to dopuštaju.
- Prilikom obrade porudžbine potrebno je proveriti da li su cena i raspoloživa količina proizvoda i dalje važeće.

Kada više kupaca istovremeno pokuša da poruči iste proizvode, server mora da proveri raspoložive količine i obezbedi da ne dođe do prodaje veće količine od stvarno dostupne.

Na primer, ako je ostao samo jedan komad proizvoda, a dva kupca istovremeno pokušaju da ga kupe, sistem ne sme da potvrdi obe porudžbine ako bi time prekoračio raspoloživu zalihu.

**Obrazloženje:** Poslovna pravila ograničavaju dozvoljene operacije i obezbeđuju doslednost podataka. Pošto više korisnika može istovremeno da menja stanje zaliha, server mora da izvrši konačnu proveru pre potvrde porudžbine.

### 4. Rad bez mreže

Mobilna aplikacija omogućava kupcu da određene podatke koristi i menja bez internet konekcije.

Kupac može da pregleda lokalno sačuvane podatke o proizvodima, sačuva proizvode u omiljene i privremeno izmeni sadržaj korpe. Lokalne izmene ostaju dostupne nakon zatvaranja i ponovnog pokretanja aplikacije.

Kada se internet konekcija ponovo uspostavi, aplikacija može da sinhronizuje lokalne podatke sa serverom.

Pre potvrde porudžbine server ponovo proverava aktuelne cene i raspoložive količine proizvoda.

**Obrazloženje:** Lokalno čuvanje podataka omogućava korišćenje određenih funkcionalnosti bez mreže. Konačna potvrda kupovine ipak zahteva proveru servera kako bi se izbegle porudžbine zasnovane na zastarelim informacijama.

### 5. Posao za osoblje

Proizvođači imaju interfejs prilagođen radu na većem ekranu, kao što su računar ili tablet.

Interfejs omogućava:

- Pregled, dodavanje i uređivanje proizvoda.
- Upravljanje cenama i zalihama.
- Pretragu, filtriranje i sortiranje proizvoda.
- Pregled porudžbina prema statusu i datumu.
- Brzo pronalaženje porudžbina koje čekaju obradu.
- Ažuriranje statusa porudžbina.
- Organizovanje pripreme, preuzimanja i isporuke.
- Pregled istorije završenih i otkazanih porudžbina.

Na primer, proizvođač koji svakodnevno obrađuje veliki broj porudžbina može da koristi tabelarni prikaz i filtere kako bi brzo pronašao porudžbine koje zahtevaju obradu.

**Obrazloženje:** Upravljanje velikim brojem proizvoda, zaliha i porudžbina predstavlja operativni posao koji je praktičnije obavljati na većem ekranu, uz naprednu pretragu i pregled podataka.

### 6. Javni sadržaj

Deo aplikacije dostupan je bez prijave i omogućava posetiocima da pregledaju proizvode i proizvođače.

Javni sadržaj obuhvata:

- Nazive, opise i fotografije proizvoda.
- Cene i javno prikazanu raspoloživost proizvoda.
- Kategorije proizvoda, kao što su voće, povrće, mlečni proizvodi, med i zimnica.
- Informacije o lokalnim proizvođačima.
- Mesto proizvodnje i način preuzimanja ili isporuke, kada su ti podaci dostupni.
- Pojedinačne stranice proizvoda i proizvođača sa jedinstvenim URL adresama.

Posetioci mogu da pretražuju ponudu i pregledaju proizvode bez kreiranja naloga. Za kreiranje porudžbine i pristup ličnim podacima potrebno je prijaviti se.

Javne stranice biće organizovane tako da pretraživači mogu da pronađu i indeksiraju proizvode i proizvođače, čime se povećava vidljivost lokalne ponude na internetu.

**Obrazloženje:** Javni sadržaj omogućava potencijalnim kupcima da otkriju proizvode i proizvođače pre registracije, dok indeksiranje stranica može da doprinese vidljivosti lokalnih proizvoda na internetu.

## Delovi sistema

| Deo | Korisnici | Tehnologija | Platforme |
|---|---|---|---|
| Mobilna aplikacija | Kupci | Flutter | Android |
| Backoffice aplikacija | Proizvođači | Flutter | Windows, veb |
| Javni veb | Svi posetioci | Jaspr | Pregledač |
| Server | Ostali delovi sistema | Relic, PostgreSQL | Linux |
| Domenski paket | Svi delovi sistema | Dart | Sve |

Svi delovi sistema koriste zajednički domenski paket, koji sadrži modele i poslovna pravila. Server čuva podatke i ponovo proverava poslovna pravila prilikom obrade zahteva.

## Stanje projekta

Projekat predstavlja platformu za prodaju lokalnih poljoprivrednih i domaćih proizvoda. Detaljan opis domena, implementacija funkcionalnosti i prateća dokumentacija razvijaju se tokom semestra.
