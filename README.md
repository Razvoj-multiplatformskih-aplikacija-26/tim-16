# tim-16
Sava Arsenijevic 79/24/SI - git:egkngm
Mateja Matic 103/24/SI - git:mmatic161
Svežko (platforma za domaće proizvode) - Aplikacija za prodaju lokalnih poljoprivrednih i domaćih proizvoda u kojoj proizvođači objavljuju proizvode, određuju cene i dostupne količine, korisnici pretražuju i poručuju proizvode, dok proizvođači upravljaju porudžbinama, zalihama i isporukama.
vežko je aplikacija za prodaju lokalnih poljoprivrednih i domaćih proizvoda koja povezuje lokalne proizvođače sa kupcima. Proizvođači mogu da objavljuju proizvode, određuju cene i dostupne količine, dok korisnici mogu da pretražuju ponudu, poručuju proizvode i prate status svojih porudžbina. Proizvođači upravljaju porudžbinama, zalihama i isporukama.

Cilj aplikacije je da olakša prodaju domaćih proizvoda, omogući kupcima jednostavan pristup lokalnoj ponudi i unapredi komunikaciju između kupaca i proizvođača.

Obrazloženje ispunjenosti šest zahteva
1. Uloge

Sistem sadrži najmanje dve korisničke uloge sa različitim ovlašćenjima:

Kupac – pregleda javnu ponudu, pretražuje proizvode, dodaje ih u korpu, kreira porudžbine i prati njihov status.
Proizvođač – objavljuje i uređuje proizvode, određuje cene i dostupne količine, pregleda primljene porudžbine, menja njihov status i upravlja isporukama.

Svaki korisnik može da obavlja samo operacije koje odgovaraju njegovoj ulozi. Na primer, kupac ne može da menja cenu proizvoda drugog proizvođača, dok proizvođač ne može da menja porudžbine koje mu ne pripadaju.

Obrazloženje: Uloge imaju različite odgovornosti i ovlašćenja, čime je ispunjen zahtev za najmanje dve uloge u sistemu.

2. Stanja

Glavni pojam sistema je porudžbina, koja tokom svog životnog ciklusa prolazi kroz više stanja:

Na čekanju – kupac je kreirao porudžbinu, a proizvođač još nije odlučio da li može da je prihvati.
Prihvaćena – proizvođač je potvrdio da može da pripremi poručene proizvode.
U pripremi – proizvođač priprema proizvode za preuzimanje ili isporuku.
Poslata – porudžbina je predata dostavljaču ili je spremna za dogovoreno preuzimanje.
Isporučena – kupac je preuzeo proizvode ili je isporuka potvrđena.
Otkazana – porudžbina je otkazana u skladu sa pravilima sistema.

Promene stanja odvijaju se prema definisanim pravilima. Na primer, isporučena porudžbina ne može ponovo da pređe u stanje „Na čekanju“.

Obrazloženje: Porudžbina ima više od četiri jasno definisana stanja i prolazi kroz kontrolisan životni ciklus.

3. Pravila

Sistem primenjuje poslovna pravila koja određuju koje operacije su dozvoljene.

Kupac ne može da poruči veću količinu proizvoda od one koja je dostupna na zalihama.
Cena i količina proizvoda moraju biti validne, a dostupna količina ne može biti negativna.
Proizvođač može da menja podatke samo o svojim proizvodima i porudžbinama.
Porudžbina se ne može otkazati nakon što pređe u stanje u kojem otkazivanje više nije dozvoljeno.
Kada dva kupca istovremeno pokušaju da poruče poslednje dostupne komade istog proizvoda, server mora da proveri stanje zaliha i odobri samo porudžbine za koje postoji dovoljna količina.
Prilikom potvrđivanja porudžbine server proverava da li su cena, količina i dostupnost proizvoda i dalje važeće.

Primer konkurentne izmene: Ako je ostao samo jedan komad proizvoda, a dva kupca istovremeno pokušaju da ga kupe, oba zahteva ne smeju biti uspešno potvrđena. Server mora da obezbedi da ne dođe do prodaje nepostojeće zalihe.

Obrazloženje: Pravila ograničavaju dozvoljene operacije, a odluka o raspoloživosti proizvoda zavisi od podataka koje menjaju različiti korisnici. Zato server mora da izvrši konačnu proveru, čak i kada aplikacija već prikazuje raspoloživu količinu.

4. Rad bez mreže

Mobilna aplikacija omogućava kupcu da bez internet konekcije sačuva proizvode u omiljene ili privremeno izmeni sadržaj lokalne korpe. Te izmene čuvaju se na uređaju i ostaju dostupne nakon zatvaranja i ponovnog pokretanja aplikacije.

Kada se internet konekcija ponovo uspostavi, aplikacija može da sinhronizuje lokalne izmene sa serverom. Pre slanja porudžbine server ponovo proverava aktuelne cene i raspoložive količine.

Obrazloženje: Korisnik može da izvrši i sačuva izmenu podataka u mobilnoj aplikaciji bez mreže. Kupovina se ne potvrđuje dok server ne proveri dostupnost proizvoda, čime se sprečavaju problemi sa zastarelim podacima.

5. Posao za osoblje

Proizvođač ima poseban interfejs prilagođen radu na većem ekranu, kao što su računar ili tablet.

Interfejs omogućava:

Pregled svih proizvoda i upravljanje njihovim podacima.
Pretragu, filtriranje i sortiranje većeg broja proizvoda.
Pregled porudžbina prema statusu, datumu i kupcu.
Grupni pregled porudžbina koje čekaju obradu.
Ažuriranje zaliha i praćenje dostupnih količina.
Organizovanje pripreme i isporuke porudžbina.
Pregled istorije završenih i otkazanih porudžbina.

Na primer, proizvođač koji dnevno obrađuje veliki broj porudžbina može da koristi tabelarni prikaz kako bi brzo pronašao sve porudžbine na čekanju i promenio njihov status.

Obrazloženje: Proizvođač obavlja operativne zadatke nad velikim brojem zapisa, pa su napredna pretraga, filtriranje, tabelarni prikaz i upravljanje većim skupovima podataka opravdani na većem ekranu.

6. Javni sadržaj

Deo aplikacije dostupan je bez prijave i sadrži javne informacije o proizvodima i proizvođačima.

Javni sadržaj obuhvata:

Naziv, opis i fotografije proizvoda.
Cene i javno prikazanu raspoloživost proizvoda.
Kategorije proizvoda, kao što su voće, povrće, mlečni proizvodi, med i zimnica.
Nazive i opise lokalnih proizvođača.
Informacije o mestu proizvodnje i načinu preuzimanja ili isporuke, kada su dostupne.
Stranice pojedinačnih proizvoda i proizvođača sa jedinstvenim URL adresama.

Posetioci mogu da pretražuju javnu ponudu i pregledaju proizvode bez kreiranja naloga. Za kreiranje porudžbine i pristup ličnim podacima potrebno je prijaviti se.

Javne stranice biće organizovane tako da pretraživači mogu da pronađu i indeksiraju proizvode i proizvođače, čime se povećava vidljivost lokalne ponude na internetu.

Obrazloženje: Javni sadržaj ima smisla i za korisnike koji nisu prijavljeni, a stranice proizvoda i proizvođača predstavljaju relevantan sadržaj koji može da se indeksira u internet pretraživačima.
