"""Reproducible authored practice bank. Run from the repository root."""
import json
import math
import pathlib
import uuid
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/content/fortnight.json'
SOURCES = {
    'math': 'https://www.minedu.sk/data/att/c58/22649.c42d94.pdf',
    'slovak': 'https://www.minedu.sk/data/att/f5c/22654.ca4c58.pdf',
    'geo': 'https://www.minedu.sk/data/att/98c/22665.52e294.pdf',
}

# Original questions; the official standards supply topic/grade alignment, not question wording.
# question | correct option | distractor | distractor | explanation
SLOVAK = {
8: [
('Pravopis a opakovanie', [
'Ktorý zápis je správny?|s dobrými kamarátmi|s dobrími kamarátmi|z dobrými kamarátmi|Predložka s a koncovka -ými patria do tohto spojenia.',
'Doplň: Na lúke sa pásli ___.|kobyly|kobili|kobily|Kobyla je vybrané slovo po b; v množnom čísle píšeme kobyly.',
'Vyber správnu vetu.|Deti boli veselé.|Deti boly veselé.|Deti boli veselý.|Minulý čas množného čísla má tvar boli; deti boli veselé.',
'Ktoré slovo je napísané správne?|výnimka|vynímka|vínimka|Spisovná podoba je výnimka.']),
('Podstatné mená', [
'Urči pád slova lesom vo vete Kráčam lesom.|inštrumentál|datív|lokál|Otázka kým? čím? určuje inštrumentál.',
'Ktoré slovo je pomnožné podstatné meno?|nožnice|kniha|stôl|Nožnice majú len množné číslo.',
'Podľa ktorého vzoru sa skloňuje slovo mesto?|mesto|srdce|dievča|Mesto je samo vzorom podstatných mien stredného rodu.',
'Aký rod má slovo mládež?|ženský|mužský|stredný|Tá mládež je podstatné meno ženského rodu.']),
('Prídavné mená a zámená', [
'Aký je tretí stupeň prídavného mena dobrý?|najlepší|najdobrejší|lepší|Stupňovanie je dobrý – lepší – najlepší.',
'Ktoré zámeno je privlastňovacie?|náš|my|kto|Náš vyjadruje privlastňovanie.',
'Ktoré spojenie obsahuje vzťahové prídavné meno?|drevený stôl|milý človek|najvyšší vrch|Drevený označuje materiál, teda vzťahovú vlastnosť.',
'Doplň: Prišli ___ spolužiaci.|moji|mojí|môj|Nominatív množného čísla je moji spolužiaci.']),
('Slovesá', [
'Urči slovesný vid: napísať.|dokonavý|nedokonavý|neurčuje sa|Napísať vyjadruje ohraničený, dokončený dej.',
'Ktoré sloveso je v rozkazovacom spôsobe?|čítaj|čítal|čítame|Čítaj vyjadruje rozkaz alebo výzvu.',
'Urči osobu a číslo slovesa kreslíme.|1. osoba množného čísla|2. osoba jednotného čísla|3. osoba množného čísla|My kreslíme: prvá osoba množného čísla.',
'Ktorý tvar je podmieňovací spôsob?|čítal by som|budem čítať|čítam|Častica by je súčasťou podmieňovacieho spôsobu.']),
('Neohybné slovné druhy', [
'Ktoré slovo je príslovka?|rýchlo|rýchly|rýchlosť|Rýchlo odpovedá na otázku ako?',
'Ktoré slovo je predložka?|pod|ale|ach|Pod vyjadruje vzťah medzi slovami.',
'Ktorá spojka vyjadruje odporovanie?|ale|a|aj|Ale pripája odporovací význam.',
'Ktoré slovo je citoslovce?|jaj|včera|pretože|Jaj vyjadruje cit alebo pocit.']),
('Podmet a prísudok', [
'Nájdi podmet: Vietor ohýbal stromy.|vietor|ohýbal|stromy|Kto alebo čo ohýbal stromy? Vietor.',
'Nájdi prísudok: Vtáky odleteli na juh.|odleteli|vtáky|juh|Prísudok pomenúva činnosť podmetu.',
'V ktorej vete je nevyjadrený podmet?|Prišli sme včas.|Žiaci prišli včas.|Autobus mešká.|Podmet my vyplýva z tvaru slovesa, nie je vyslovený.',
'Ktorá dvojica tvorí prisudzovací sklad?|deti spievajú|veselé deti|spievajú pekne|Prisudzovací sklad tvorí podmet a prísudok.']),
('Rozvíjacie vetné členy', [
'Urči člen peknú vo vete Čítam peknú knihu.|prívlastok|podmet|prísudok|Peknú rozvíja podstatné meno knihu.',
'Nájdi predmet: Jana číta knihu.|knihu|Jana|číta|Čo číta Jana? Knihu.',
'Urči člen ráno vo vete Ráno odchádzame.|príslovkové určenie času|predmet|podmet|Ráno odpovedá na otázku kedy?',
'Urči člen do školy vo vete Idem do školy.|príslovkové určenie miesta|prívlastok|prísudok|Kam idem? Do školy.']),
('Jednoduchá veta', [
'Ktorá veta je jednočlenná slovesná?|Prší.|Dážď padá.|Deti bežia.|Prší nečleníme na podmet a prísudok.',
'Ktorá veta je dvojčlenná úplná?|Slnko svieti.|Sneží.|Ticho!|Má vyjadrený podmet slnko aj prísudok svieti.',
'Ktorá veta je rozvitá?|Malý pes hlasno šteká.|Pes šteká.|Prší.|Obsahuje aj rozvíjacie vetné členy.',
'Čím sa končí zisťovacia otázka?|otáznikom|bodkou|dvojbodkou|Otázku ukončujeme otáznikom.']),
('Slovná zásoba', [
'Ktorá dvojica sú synonymá?|pekný – krásny|deň – noc|dom – domček|Synonymá majú rovnaký alebo podobný význam.',
'Ktorá dvojica sú antonymá?|vysoký – nízky|smelý – odvážny|auto – automobil|Antonymá sú slová s opačným významom.',
'Ktoré slovo vzniklo odvodzovaním?|lesník|les|pralesný chodník|Lesník vznikol zo slova les príponou.',
'Ktoré slovo je zložené?|vodopád|vodný|voda|Vodopád vznikol spojením dvoch slovných základov.']),
('Lyrika', [
'Čo je lyrika?|vyjadrenie pocitov a nálad|návod na pokus|zoznam udalostí|Lyrika zvýrazňuje vnútorný svet a prežívanie.',
'Čo je personifikácia v spojení vietor spieva?|prisúdenie ľudskej vlastnosti neživému javu|číselný údaj|doslovný opis hlasu človeka|Spievanie sa obrazne prisudzuje vetru.',
'Ktoré spojenie je prirovnanie?|biely ako sneh|biely sneh|sneží|Prirovnanie spája dva javy pomocou slova ako.',
'Čo je verš?|jeden riadok básne|celá kniha|odsek návodu|Verš je základná rytmická jednotka básne, zvyčajne jeden riadok.']),
('Epika a rozprávač', [
'Čo je typické pre epiku?|rozprávanie príbehu|iba zoznam pojmov|výlučne javiskové poznámky|Epické dielo má spravidla dej a postavy.',
'Ktorá veta je ja-rozprávanie?|Vstúpil som do lesa.|Peter vstúpil do lesa.|Vstúpili do lesa.|Rozprávač používa prvú osobu.',
'Čo je hlavná postava?|postava v centre príbehu|autor knihy v každom diele|každý čitateľ|Hlavná postava nesie podstatnú časť deja.',
'Čo je téma diela?|to, o čom dielo hovorí|počet strán|meno vydavateľa|Téma pomenúva predmet literárneho spracovania.']),
('Sloh a komunikácia', [
'Ktorý text opisuje vlastnosti človeka?|charakteristika|oznam|pozvánka|Charakteristika zachytáva vonkajšie aj vnútorné vlastnosti.',
'Čo má obsahovať pozvánka na podujatie?|miesto a čas podujatia|iba podpis|iba cenu vstupenky|Adresát musí vedieť, kam a kedy má prísť.',
'Čo je argument?|dôvod podporujúci tvrdenie|urážka súpera|ľubovoľný výkrik|Argument vecne podporuje stanovisko.',
'Ktorá reakcia je asertívna?|Nesúhlasím, vysvetlím prečo.|Musíš vždy súhlasiť!|Si hlúpy!|Asertívna komunikácia rešpektuje seba aj druhého.']),
('Čítanie s porozumením', [
'Knižnica otvára o 9.00. Ema prišla o 8.45. Koľko minút čaká?|15|30|45|Od 8.45 do 9.00 uplynie pätnásť minút.',
'Oznam: V stredu je bazén zatvorený. Kedy sa tam v stredu dá plávať?|v žiadnom čase|iba ráno|iba večer|Zatvorený bazén v uvedený deň neprevádzkujú.',
'Vlak ide o 14.20 a cesta trvá 30 minút. Kedy príde?|14.50|14.30|15.20|K času odchodu pripočítame tridsať minút.',
'Text: Hoci pršalo, výlet sa uskutočnil. Čo platí?|Výlet bol aj napriek dažďu.|Výlet zrušili.|Nepršalo.|Spojenie hoci vyjadruje okolnosť, ktorá deju nezabránila.']),
('Záverečný jazykový mix', [
'Ktorý zápis priamej reči je správny?|„Prídem,“ povedal Tomáš.|Prídem povedal Tomáš.|„Prídem povedal Tomáš.“|Úvodzovky oddeľujú priamu reč od uvádzacej vety.',
'Ktoré slovo je spisovné?|zemiaky|krumple|bandurky|Zemiaky je neutrálne spisovné pomenovanie.',
'Čo je metafora v spojení more svetiel?|prenesenie významu na základe podobnosti|označenie slanej vody|pravopisná chyba|Množstvo svetiel sa obrazne prirovnáva k moru bez slova ako.',
'Ktorý zdroj overí pravopis slova?|Pravidlá slovenského pravopisu|cestovný poriadok|atlas sveta|Pravopis overujeme v kodifikačnej príručke.'])],
9: [
('Opakovanie syntaxe', [
'Koľko prísudkov má veta Čítam a sestra kreslí?|2|1|3|Prísudky sú čítam a kreslí.',
'Ktoré spojenie tvorí prisudzovací sklad?|dážď padá|silný dážď|padá večer|Sklad tvorí podmet a prísudok.',
'Ktorá veta je jednočlenná neslovesná?|Ticho!|Les šumí.|Deti prišli.|Jednočlenná neslovesná veta nemá slovesný základ.',
'Urči podmet: Na stole ležali knihy.|knihy|stole|ležali|Čo ležalo na stole? Knihy.']),
('Priraďovacie súvetie', [
'Urči súvetie: Slnko svietilo a vtáky spievali.|zlučovacie|odporovacie|vylučovacie|Spojka a spája rovnocenné deje.',
'Urči súvetie: Učil sa, ale neuspel.|odporovacie|zlučovacie|vylučovacie|Druhá veta odporuje očakávaniu z prvej.',
'Urči súvetie: Buď prídeš, alebo zavoláš.|vylučovacie|odporovacie|zlučovacie|Buď – alebo vyjadruje výber možností.',
'Urči súvetie: Je usilovný, ba aj pomáha.|stupňovacie|vylučovacie|odporovacie|Ba aj zosilňuje význam prvej vety.']),
('Podraďovacie súvetie', [
'Nájdi vedľajšiu vetu: Viem, že prídeš.|že prídeš|Viem|prídeš viem|Vedľajšia veta závisí od hlavnej vety Viem.',
'Akú okolnosť vyjadruje veta Keď zaprší, ostaneme doma?|čas|miesto|spôsob|Vedľajšia veta odpovedá na otázku kedy?',
'Vyber správnu interpunkciu.|Povedal, že príde.|Povedal že, príde.|Povedal že príde.|Pred vedľajšou vetou uvedenou že píšeme čiarku.',
'Veta Kniha, ktorú čítam, je zaujímavá obsahuje vedľajšiu vetu rozvíjajúcu čo?|podstatné meno kniha|slovo je|slovo zaujímavá|Ktorú čítam bližšie určuje knihu.']),
('Jazykové štýly', [
'Aký štýl je typický pre úradnú žiadosť?|administratívny|umelecký|hovorový|Úradná komunikácia používa administratívny štýl.',
'Aký štýl je typický pre správu v novinách?|publicistický|hovorový|umelecký|Novinové správy patria do publicistiky.',
'Aký štýl používa básnický text?|umelecký|administratívny|náučný|Umelecký štýl využíva obraznosť a estetickú funkciu.',
'Aký štýl je typický pre bežný rozhovor priateľov?|hovorový|administratívny|náučný|Bežná neformálna komunikácia je hovorová.']),
('Slohové postupy', [
'Ktorý postup vysvetľuje príčiny a súvislosti?|výkladový|rozprávací|opisný|Výklad objasňuje vzťahy medzi javmi.',
'Ktorý postup zachytáva dej v čase?|rozprávací|opisný|informačný|Rozprávanie zobrazuje sled udalostí.',
'Ktorý postup zachytáva znaky predmetu?|opisný|rozprávací|výkladový|Opis predstavuje vlastnosti a časti predmetu.',
'Čo je typické pre úvahu?|osobné premýšľanie o probléme|iba dátumy|iba pokyny|Úvaha rozvíja myšlienky, otázky a hodnotenia.']),
('Národný jazyk', [
'Čo je spisovný jazyk?|celonárodná kodifikovaná podoba jazyka|jazyk jednej rodiny|iba nárečie mesta|Spisovný jazyk slúži aj oficiálnej komunikácii.',
'Čo je nárečie?|územne vymedzená podoba jazyka|pravopisná príručka|cudzí jazyk|Nárečie je viazané na určitý región.',
'Ktorá príručka vysvetľuje význam slov?|výkladový slovník|atlas|telefónny zoznam|Výkladový slovník uvádza významy slov.',
'Ktoré vyjadrenie je vhodné v úradnom liste?|Žiadam o vydanie potvrdenia.|Čau, daj papier.|Hej, pošli dačo.|Úradný list vyžaduje vecné a spisovné vyjadrenie.']),
('Dráma', [
'Čo je dráma?|literárny druh určený aj na javiskové stvárnenie|iba vedecký text|zoznam postáv bez deja|Dráma sa rozvíja najmä konaním a rečou postáv.',
'Čo je replika?|prehovor postavy v dialógu|názov divadla|meno autora|Replika je jedna výpoveď postavy.',
'Čo je scénická poznámka?|pokyn autora k inscenovaniu|prehovor publika|novinový titulok|Udáva napríklad pohyb, prostredie alebo spôsob reči.',
'Ktorý žáner využíva komické situácie?|komédia|tragédia|odborný výklad|Komédia vyvoláva komický účinok.']),
('Lyrika a obraznosť', [
'Čo je reflexívna lyrika?|básnické zamyslenie|zápis športového zápasu|návod na výpočet|Reflexívna lyrika obsahuje úvahy o živote a hodnotách.',
'Ktorá otázka môže byť básnická?|Kto by nechcel žiť v mieri?|Koľko stojí lístok?|Kedy ide autobus?|Básnická otázka nežiada priamu odpoveď.',
'Čo je spoločenská lyrika?|lyrika o spoločenských témach|iba opis rastlín|úradný oznam|Zaoberá sa spoločnosťou, národom či slobodou.',
'Čo je aforizmus?|stručný výrok s myšlienkou|rozsiahly román|javisková prestávka|Aforizmus stručne a často vtipne vyjadruje postreh.']),
('Kompozícia diela', [
'Čo je zápletka?|vznik konfliktu v deji|zoznam vydavateľov|záver slovníka|Zápletka uvádza problém, ktorý poháňa dej.',
'Čo je vyvrcholenie?|vrchol napätia|prvá strana knihy|meno rozprávača|Konflikt dosahuje najväčšiu intenzitu.',
'Čo je rozuzlenie?|vyriešenie konfliktu|obálka knihy|nová hlavná postava vždy|Rozuzlenie ukazuje výsledok deja a konfliktu.',
'Ktorý prvok patrí do vonkajšej kompozície prózy?|kapitola|metafora|konflikt|Kapitoly sú viditeľné členenie textu.']),
('Pravopis v súvislostiach', [
'Doplň: Sme ___ na výsledok.|hrdí|hrdý|hrdy|V nominatíve množného čísla mužského životného rodu píšeme hrdí.',
'Vyber správnu vetu.|Žiaci si splnili povinnosti.|Žiaci si splnily povinnosti.|Žiaci sy splnili povinnosti.|Správne sú si a slovesná koncovka -li.',
'Ktoré spojenie je správne?|päť eur|päť eúr|päť euro|Po číslovke päť používame genitív množného čísla eur.',
'Ktorý zápis sviatku je správny?|Vianoce|vianoce|VIanoce|Názov sviatku Vianoce píšeme s veľkým začiatočným písmenom.']),
('Argumentácia a zdroje', [
'Čo podporuje dôveryhodnosť tvrdenia?|overiteľný zdroj a dôkaz|veľa výkričníkov|anonymná urážka|Dôkaz má byť overiteľný a súvisiaci s tvrdením.',
'Čo je protiargument?|dôvod spochybňujúci tvrdenie|osobný útok|názov časopisu|Protiargument sa vecne stavia proti argumentu.',
'Čo je citácia?|označené prevzatie cudzieho výroku|vlastný neoznačený odhad|náhodná poznámka|Citácia odlišuje prevzatý výrok a uvádza jeho pôvod.',
'Čo treba overiť pri online správe?|autora, dátum a zdroje|iba farbu nadpisu|iba počet zdieľaní|Tieto údaje pomáhajú posúdiť pôvod a aktuálnosť správy.']),
('Porozumenie textu', [
'Vstupné je 4 €, žiaci platia polovicu. Koľko platí žiak?|2 €|4 €|8 €|Polovica zo štyroch eur sú dve eurá.',
'Text: Výstava potrvá do piatka vrátane. Platí vstup v piatok?|áno|nie|iba minulý týždeň|Slovo vrátane zahŕňa aj piatok.',
'Text: Každý účastník potrebuje súhlas rodiča. Kto ho potrebuje?|všetci účastníci|iba organizátor|nikto|Každý znamená bez výnimky každý účastník.',
'Oznam: Počas opravy je vchod z dvora. Kde vstúpiš?|z dvora|hlavným uzavretým vchodom|cez okno|Oznam určuje náhradný vstup.']),
('Sloh v praxi', [
'Čo má obsahovať životopis?|vzdelanie a relevantné skúsenosti|iba vtipy|iba nákupný zoznam|Životopis vecne predstavuje uchádzača.',
'Čo je cieľom výkladu?|objasniť jav a súvislosti|iba pobaviť rýmom|zatajiť postup|Výklad vysvetľuje a usporadúva poznatky.',
'Čo patrí do záveru úvahy?|zhrnutie vlastného zamyslenia|náhodný cudzí text|iba poštová adresa|Záver nadväzuje na rozvíjané myšlienky.',
'Ktoré oslovenie je vhodné v oficiálnom e-maile?|Vážená pani riaditeľka,|Čauko!|Hej ty!|Oficiálna komunikácia používa zdvorilé oslovenie.']),
('Záverečná výzva', [
'Urči druh súvetia: Ostal doma, pretože bol chorý.|podraďovacie|priraďovacie zlučovacie|jednoduchá veta|Vedľajšia veta vysvetľuje príčinu deja hlavnej vety.',
'Čo je vnútorný monológ?|nevyslovené myšlienky postavy|rozhovor dvoch ľudí|zoznam hercov|Monológ môže sprístupniť vnútorné prežívanie postavy.',
'Ktorý útvar patrí do publicistiky?|reportáž|žiadosť o potvrdenie|súkromná SMS|Reportáž sprostredkúva udalosť cez pozorovanie a fakty.',
'Čo odlišuje fakt od názoru?|fakt možno overiť|fakt musí obsahovať superlatív|názor je vždy klamstvo|Fakt je overiteľné tvrdenie, názor vyjadruje hodnotenie.'])]
}

GEO_CHOICES = {
8: [
('Poloha Slovenska', ['S koľkými štátmi susedí Slovensko?|5|4|6|Susedmi sú Česko, Poľsko, Ukrajina, Maďarsko a Rakúsko.', 'V ktorej časti Európy leží Slovensko?|strednej|severnej|južnej|Slovensko patrí do strednej Európy.']),
('Povrch Slovenska', ['Najvyšším vrchom Slovenska je:|Gerlachovský štít|Kriváň|Ďumbier|Gerlachovský štít je najvyšším bodom Tatier aj Slovenska.', 'Ktorá nížina leží na juhozápade Slovenska?|Podunajská nížina|Východoslovenská nížina|Košická kotlina|Podunajská nížina sa rozkladá pri Dunaji.']),
('Vodstvo', ['Ktorá rieka preteká Bratislavou?|Dunaj|Hornád|Poprad|Bratislava leží na Dunaji.', 'Najdlhšou riekou na území Slovenska je:|Váh|Dunaj|Hron|Váh má najdlhší tok vedený územím Slovenska.']),
('Podnebie', ['V akom podnebnom pásme leží Slovensko?|miernom|tropickom|polárnom|Striedajú sa tu štyri ročné obdobia mierneho pásma.', 'Ako sa spravidla mení teplota so stúpajúcou výškou?|klesá|stúpa|nemení sa|Vo vyšších polohách býva priemerne chladnejšie.']),
('Pohoria', ['Ktorý celok patrí ku Karpatom?|Tatry|Alpy|Pyreneje|Tatry sú súčasťou Karpát.', 'Najvyšším vrchom Nízkych Tatier je:|Ďumbier|Gerlachovský štít|Lomnický štít|Ďumbier je najvyšším vrchom Nízkych Tatier.']),
('Kraje', ['Koľko samosprávnych krajov má Slovensko?|8|6|10|Slovensko má osem samosprávnych krajov.', 'Ktoré mesto je sídlom Prešovského kraja?|Prešov|Poprad|Bardejov|Sídlom kraja je Prešov.']),
('Sídla', ['Ktoré mesto je hlavným mestom SR?|Bratislava|Košice|Žilina|Hlavným mestom Slovenska je Bratislava.', 'Ktoré mesto leží na východe Slovenska?|Košice|Trnava|Trenčín|Košice sú veľkým mestom východného Slovenska.']),
('Hospodárstvo', ['Prečo sú nížiny vhodné na poľnohospodárstvo?|rovinatejší povrch a teplejšie podnebie|trvalé ľadovce|polárna noc|Rovinaté úrodné plochy uľahčujú obrábanie pôdy.', 'Čo patrí do sektora služieb?|cestovný ruch|ťažba uhlia|pestovanie pšenice|Cestovný ruch poskytuje služby návštevníkom.']),
('Príroda a ochrana', ['Čo je hlavným cieľom národného parku?|ochrana prírody|zvyšovanie hlučnosti|výstavba tovární|Národný park chráni cenné ekosystémy a krajinu.', 'Ktorá činnosť pomáha chrániť rieky?|čistenie odpadových vôd|vylievanie oleja do vody|odhodenie plastov do toku|Čistenie znižuje znečistenie vodných tokov.']),
('Cestovný ruch', ['Čo označuje značka UNESCO pri pamiatke?|svetové dedičstvo|automaticky bezplatný vstup|najnovšiu budovu|Zoznam UNESCO zahŕňa výnimočné kultúrne a prírodné dedičstvo.', 'Ktoré mesto je známe banskou históriou a pamiatkami UNESCO?|Banská Štiavnica|Senec|Sereď|Historické banské mesto Banská Štiavnica je v zozname UNESCO.']),
('Regióny', ['Ktorý región je spojený s Vysokými Tatrami?|Spiš|Záhorie|Žitný ostrov|Spiš zasahuje do oblasti Tatier.', 'Ktorá rieka dala meno regiónu Považie?|Váh|Hron|Ipeľ|Považie je oblasť pozdĺž Váhu.']),
('Mapa a orientácia', ['Na bežnej mape so severom hore je východ:|vpravo|vľavo|dole|Pri severnej orientácii je východ na pravej strane.', 'Čo vyjadruje mierka mapy?|pomer vzdialenosti na mape a v skutočnosti|vek mapy|počet miest|Mierka umožňuje prepočet mapových vzdialeností.']),
('Obyvateľstvo', ['Čo znamená hustota zaľudnenia?|počet obyvateľov na jednotku plochy|počet domov v ulici|vek najstaršieho človeka|Bežne sa udáva v obyvateľoch na km².', 'Čo je urbanizácia?|rast významu miest a mestského spôsobu života|premena mora na púšť|meranie výšky pohorí|Urbanizácia súvisí so sústreďovaním obyvateľov a činností do miest.']),
('Slovensko v súvislostiach', ['Do ktorého mora odteká Dunaj?|Čierneho|Baltského|Severného|Dunaj ústi deltou do Čierneho mora.', 'Ktorá krajina susedí so Slovenskom na východe?|Ukrajina|Rakúsko|Česko|Východnú hranicu zdieľame s Ukrajinou.'])],
9: [
('Austrália – poloha', ['Na ktorej pologuli leží celá Austrália?|južnej|severnej|iba západnej|Austrália leží južne od rovníka.', 'Hlavné mesto Austrálie je:|Canberra|Sydney|Melbourne|Canberra je federálnym hlavným mestom.']),
('Austrália – príroda', ['Čo je typické pre vnútrozemie Austrálie?|suché oblasti|tropický dažďový prales všade|trvalá ľadová pokrývka|Veľká časť vnútrozemia má nedostatok zrážok.', 'Ktorý živočích je typický austrálsky vačkovec?|kengura|ľadový medveď|lama|Kengury patria medzi vačkovce.']),
('Austrália – sídla', ['Kde žije veľká časť Austrálčanov?|pri pobreží|v strede púští|na antarktickom ľade|Pobrežie má priaznivejšie podmienky a veľké mestá.', 'Pri ktorom pobreží leží Veľká koralová bariéra?|severovýchodnom|juhozápadnom|severozápadnom|Bariéra sa tiahne pri pobreží Queenslandu.']),
('Oceánia', ['Ktorý oceán obklopuje väčšinu ostrovov Oceánie?|Tichý|Atlantický|Severný ľadový|Oceánia zahŕňa ostrovné oblasti Tichého oceánu.', 'Čo je atol?|prstencový koralový ostrov|kontinentálny ľadovec|riečny vodopád|Atol obklopuje lagúnu.']),
('Nový Zéland', ['Ktoré mesto je hlavným mestom Nového Zélandu?|Wellington|Auckland|Sydney|Wellington je hlavným mestom Nového Zélandu.', 'Nový Zéland tvoria najmä:|Severný a Južný ostrov|Grónsko a Island|Kuba a Haiti|Dva najväčšie ostrovy sú Severný a Južný ostrov.']),
('Polárne oblasti', ['Antarktída je:|kontinent|štát v Európe|tropický ostrov|Antarktída je kontinent obklopujúci južný pól.', 'Arktída sa nachádza okolo:|severného pólu|južného pólu|rovníka|Arktída je severná polárna oblasť.']),
('Severná Amerika', ['Ktorý oceán obmýva západné pobrežie USA?|Tichý|Indický|Severný ľadový všade|Západné pobrežie USA leží pri Tichom oceáne.', 'Hlavné mesto Kanady je:|Ottawa|Toronto|Vancouver|Ottawa je hlavným mestom Kanady.']),
('USA a Kanada', ['Ktoré pohorie leží na západe Severnej Ameriky?|Kordillery|Andy|Alpy|Kordillery tvoria horskú sústavu západu Severnej Ameriky.', 'Čo sú Veľké kanadské jazerá?|sústava sladkovodných jazier|púšte|tropické ostrovy|Ležia pri hranici Kanady a USA.']),
('Stredná Amerika', ['Čo spája Panamský prieplav?|Atlantický a Tichý oceán|Indický a Severný ľadový oceán|Dunaj a Rýn|Prieplav skracuje lodnú trasu medzi dvoma oceánmi.', 'Kuba patrí k:|Veľkým Antilám|Malajskému súostroviu|Kanárskym ostrovom|Kuba je ostrov Veľkých Antíl v Karibiku.']),
('Južná Amerika', ['Ktoré pohorie sa tiahne západom Južnej Ameriky?|Andy|Apalačské vrchy|Tatry|Andy tvoria dlhú horskú reťaz pri Tichom oceáne.', 'Ktorá rieka odvodňuje rozsiahly dažďový prales?|Amazonka|Dunaj|Murray|Povodie Amazonky pokrýva veľkú časť amazonského pralesa.']),
('Brazília a Argentína', ['Aký jazyk je úradným jazykom Brazílie?|portugalčina|španielčina|francúzština|Brazília má portugalské koloniálne dejiny.', 'Čo sú pampy?|trávnaté roviny Južnej Ameriky|polárne ľadovce|koralové útesy|Pampy sa rozkladajú najmä v Argentíne a Uruguaji.']),
('Amerika – obyvateľstvo', ['Čím sa vyznačuje obyvateľstvo Ameriky?|veľkou kultúrnou rozmanitosťou|jediným jazykom všade|neprítomnosťou miest|Rozmanitosť súvisí s pôvodným osídlením aj prisťahovalectvom.', 'Čo je veľkomesto?|mesto s veľkým počtom obyvateľov|každá samota|každá farma|Veľkomestá sú významnými centrami obyvateľstva a činností.']),
('Amerika – prírodné riziká', ['Prečo vznikajú zemetrasenia pri západnom pobreží Ameriky?|pohyb litosférických dosiek|striedanie dní v týždni|iba doprava|Na rozhraniach dosiek sa uvoľňuje nahromadené napätie.', 'Čo ohrozuje biodiverzitu Amazónie?|odlesňovanie|ochrana pralesa|obnova lesa|Odlesňovanie ničí prostredie mnohých druhov.']),
('Svet v súvislostiach', ['Čo spôsobuje striedanie polárneho dňa a noci?|sklon zemskej osi pri obehu Zeme|priehrady|zemetrasenia|Sklon osi mení osvetlenie polárnych oblastí počas roka.', 'Ktoré opatrenie chráni polárne oblasti?|obmedzenie znečisťovania a emisií|vypúšťanie ropy|odhodenie odpadu na ľad|Zníženie znečistenia a otepľovania pomáha chrániť polárne ekosystémy.'])]
}

def math_questions(grade, day):
    n = day + 2
    if grade == 8:
        topics = ['Celé čísla', 'Racionálne čísla', 'Výrazy s premennou', 'Jednoduché slovné úlohy',
                  'Obsah trojuholníka', 'Rovnobežník', 'Lichobežník', 'Kruh a kružnica',
                  'Hranol', 'Pravdepodobnosť', 'Údaje a priemer', 'Súradnice', 'Číselné výrazy', 'Opakovanie']
        pages = [23,23,24,24,26,26,26,28,27,29,29,24,24,23]
    else:
        topics = ['Mocniny', 'Druhá odmocnina', 'Lineárne rovnice', 'Nerovnice',
                  'Pytagorova veta', 'Podobnosť', 'Valec', 'Kužeľ', 'Ihlan', 'Guľa',
                  'Štatistika', 'Grafy a závislosti', 'Slovné úlohy', 'Opakovanie']
        pages = [31,31,30,30,33,35,34,34,34,34,36,38,30,33]
    rows = []
    for i in range(4):
        a = n + i
        b = i + 2
        if grade == 8:
            if day == 1: q, v, e, u = f'Vypočítaj: −{a} + {b}.', -a+b, f'K číslu −{a} pripočítame {b}.', ''
            elif day == 2: q,v,e,u = f'Vypočítaj: −{a/2:g} × {b}.', -a/2*b, 'Súčin záporného a kladného čísla je záporný.', ''
            elif day == 3: q,v,e,u = f'Ak x = {a}, akú hodnotu má výraz 3x − {b}?',3*a-b,f'Dosadíme: 3 × {a} − {b}.',''
            elif day == 4: q,v,e,u = f'Myslím si číslo. Keď k nemu pripočítam {b}, dostanem {a+b}. Aké je to číslo?',a,f'Od {a+b} odčítame {b}.',''
            elif day == 5: q,v,e,u = f'Trojuholník má základňu {a} cm a príslušnú výšku {b} cm. Vypočítaj obsah.',a*b/2,'Obsah trojuholníka je základňa krát výška delené dvoma.','cm²'
            elif day == 6: q,v,e,u = f'Rovnobežník má základňu {a} cm a výšku {b} cm. Aký má obsah?',a*b,'Obsah rovnobežníka je súčin základne a príslušnej výšky.','cm²'
            elif day == 7: q,v,e,u = f'Lichobežník má základne {a} cm a {a+2} cm, výšku {b} cm. Aký má obsah?',(a+1)*b,'Obsah: súčet základní krát výška, delené dvoma.','cm²'
            elif day == 8: q,v,e,u = f'Kruh má polomer {b} cm. Aký je obvod? Použi π = 3,14.',round(2*3.14*b,2),'Obvod kruhu vypočítame vzorcom o = 2πr.','cm'
            elif day == 9: q,v,e,u = f'Kolmý hranol má obsah podstavy {a} cm² a výšku {b} cm. Aký má objem?',a*b,'Objem hranola je obsah podstavy krát výška.','cm³'
            elif day == 10: q,v,e,u = f'Vo vrecku sú {b} červené a {b} modré guľôčky. Aká je pravdepodobnosť vytiahnutia červenej v percentách?',50,'Červené tvoria polovicu všetkých guľôčok.','%'
            elif day == 11: q,v,e,u = f'Vypočítaj aritmetický priemer čísel {a-2}, {a}, {a+2}.',a,'Súčet troch čísel vydelíme tromi.',''
            elif day == 12: q,v,e,u = f'Bod A má súradnice [{a}; {b}]. Aká je jeho x-ová súradnica?',a,'Prvá súradnica je x-ová, druhá y-ová.',''
            elif day == 13: q,v,e,u = f'Vypočítaj: {a} − 2 × {b}.',a-2*b,'Násobenie má prednosť pred odčítaním.',''
            else: q,v,e,u = f'Teplota bola −{b} °C a stúpla o {a} °C. Aká je teraz?',a-b,'K zápornej teplote pripočítame oteplenie.','°C'
        else:
            if day == 1: q,v,e,u = f'Vypočítaj druhú mocninu čísla {a}.',a*a,'Druhá mocnina je súčin čísla so sebou samým.',''
            elif day == 2: q,v,e,u = f'Aká je druhá odmocnina z {a*a}?',a,f'{a} × {a} = {a*a}; druhá odmocnina je nezáporná.',''
            elif day == 3: q,v,e,u = f'Vyrieš rovnicu: 3x + {b} = {3*a+b}.',a,f'Odčítame {b} a výsledok vydelíme tromi.',''
            elif day == 4: q,v,e,u = f'Aké je najmenšie celé číslo x spĺňajúce x > {a}?',a+1,'Najmenšie celé číslo väčšie než zadané je o jeden väčšie.',''
            elif day == 5: q,v,e,u = f'Pravouhlý trojuholník má odvesny {3*b} cm a {4*b} cm. Aká je prepona?',5*b,'Prepona c = √(a² + b²); ide o násobok trojice 3–4–5.','cm'
            elif day == 6: q,v,e,u = f'Strana trojuholníka má {a} cm. Podobný trojuholník má pomer zväčšenia {b}. Aká je zodpovedajúca strana?',a*b,'Zodpovedajúcu dĺžku násobíme pomerom podobnosti.','cm'
            elif day == 7: q,v,e,u = f'Valec má polomer {b} cm a výšku {a} cm. Objem vypočítaj s π = 3,14.',round(3.14*b*b*a,2),'Objem valca je V = πr²v.','cm³'
            elif day == 8: q,v,e,u = f'Kužeľ má obsah podstavy {3*a} cm² a výšku {b} cm. Aký má objem?',a*b,'Objem kužeľa je tretina súčinu obsahu podstavy a výšky.','cm³'
            elif day == 9: q,v,e,u = f'Ihlan má obsah podstavy {3*a} cm² a výšku {b} cm. Aký má objem?',a*b,'Objem ihlana je V = S podstavy × výška / 3.','cm³'
            elif day == 10: q,v,e,u = f'Guľa má polomer {b} cm. Vypočítaj povrch s π = 3,14.',round(4*3.14*b*b,2),'Povrch gule je S = 4πr².','cm²'
            elif day == 11: q,v,e,u = f'Vypočítaj aritmetický priemer údajov {a-4}, {a-2}, {a}, {a+2}, {a+4}.',a,'Súčet piatich údajov vydelíme piatimi.',''
            elif day == 12: q,v,e,u = f'Pre závislosť y = {b}x vypočítaj y pri x = {a}.',a*b,'Do predpisu dosadíme zadanú hodnotu x.',''
            elif day == 13: q,v,e,u = f'Tri rovnaké vstupenky a poplatok {b} € stoja {3*a+b} €. Koľko stojí jedna vstupenka?',a,'Od celkovej sumy odčítame poplatok a delíme tromi.','€'
            else: q,v,e,u = f'Rebrík tvorí preponu trojuholníka s odvesnami {5*b} m a {12*b} m. Aký je dlhý?',13*b,'Z Pytagorovej vety: √((5k)² + (12k)²) = 13k.','m'
        rows.append(dict(kind='number', prompt=q, answer=v, solution=f'{v:g} {u}'.strip(), explanation=e, unit=u))
    return topics[day-1], f's. {pages[day-1]} – {topics[day-1]}', rows

def choices(text, rotation):
    q, correct, d1, d2, why = text.split('|')
    options = [correct, d1, d2]
    rotation %= 3
    options = options[rotation:] + options[:rotation]
    return dict(kind='choice', prompt=q, answer=options.index(correct), options=options, solution=correct, explanation=why)

def build():
    archive=ROOT/'assets/maps/cities15000.zip'
    if archive.exists():
        with zipfile.ZipFile(archive) as z:
            cities = {row[0]: row for line in z.read('cities15000.txt').decode('utf8').splitlines() if (row:=line.split('\t'))}
    else:
        cities=json.loads((ROOT/'assets/content/places.json').read_text(encoding='utf8'))['records']
    # GeoNames IDs avoid ambiguous city names and provide reproducible WGS84 coordinates.
    ids8 = ['3060972','724443','3058531','723819','3056508','3061186','3057124','3057140',
            '3058780','723846','3058000','3056459','3058060','3058472','724144','723526',
            '3059436','3059101','724627','725168','3059050','3058202','3057789','3058986',
            '3058083','3058268','3057630','3058477']
    # Last four selected by name from the same dataset rather than guessed identifiers.
    for index, name in enumerate(['Pezinok','Senica','Skalica','Dunajská Streda'],24):
        ids8[index] = next(r[0] for r in cities.values() if r[8]=='SK' and r[1]==name)
    names9 = [('AU','Sydney'),('AU','Canberra'),('AU','Melbourne'),('AU','Perth'),('AU','Brisbane'),('AU','Adelaide'),
      ('NZ','Wellington'),('NZ','Auckland'),('NZ','Christchurch'),('AU','Darwin'),('US','Anchorage'),('CA','Yellowknife'),
      ('CA','Ottawa'),('US','Washington'),('US','New York City'),('CA','Toronto'),('MX','Mexico City'),('CU','Havana'),
      ('PE','Lima'),('CL','Santiago'),('BR','Brasília'),('AR','Buenos Aires'),('BR','Rio de Janeiro'),('US','Chicago'),
      ('US','Los Angeles'),('CA','Montréal'),('US','Miami'),('UY','Montevideo')]
    ids9=[]
    for cc,name in names9:
        matches=[r for r in cities.values() if r[8]==cc and (r[1]==name or r[2]==name or name in r[3].split(','))]
        if not matches: raise ValueError((cc,name))
        ids9.append(max(matches,key=lambda r:int(r[14]))[0])
    lessons=[]
    (ROOT/'assets/content/places.json').write_text(json.dumps(dict(
        source='https://download.geonames.org/export/dump/cities15000.zip',
        license='https://creativecommons.org/licenses/by/4.0/',
        attribution='GeoNames, snapshot 2026-10-26; city coordinates retained without modification.',
        records={id:cities[id] for id in ids8+ids9}),ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    for grade in [8,9]:
        for day in range(1,15):
            for area,subject in enumerate(['math','slovak','geo']):
                if subject=='math': topic,section,questions=math_questions(grade,day)
                elif subject=='slovak':
                    topic,rows=SLOVAK[grade][day-1]
                    section='s. 71–84 – prehľad pojmov; aplikácia a opakovanie pre '+str(grade)+'. ročník'
                    questions=[choices(row,day+i) for i,row in enumerate(rows)]
                else:
                    topic,rows=GEO_CHOICES[grade][day-1]
                    section='s. 17–19 – Slovensko' if grade==8 else 's. 20–23 – Austrália, polárne oblasti a Amerika'
                    questions=[]
                    for id in (ids8 if grade==8 else ids9)[(day-1)*2:day*2]:
                        r=cities[id]
                        display=r[1]
                        if display=='Washington': display='Washington, D. C.'
                        if display=='New York City': display='New York'
                        questions.append(dict(kind='map',prompt=f'Nájdi na slepej mape mesto {display}.',
                          target={'lat':float(r[4]),'lon':float(r[5])}, solution=display,
                          explanation=f'{display}: správnu polohu ukazuje zelená značka. Oranžová označuje tvoj tip.',
                          region='sk' if grade==8 else ('oceania' if day<=5 else 'america'),
                          fullCreditKm=10 if grade==8 else 70, zeroCreditKm=250 if grade==8 else 2200,
                          coordinateSource='https://www.geonames.org/'+id+'/'))
                    questions += [choices(row,day+i) for i,row in enumerate(rows)]
                lesson_id=grade*10000+day*10+area
                for i,q in enumerate(questions):
                    q.update(id=str(uuid.uuid5(uuid.NAMESPACE_URL,f'https://vedomax.sk/v2/{lesson_id}/{i}')),
                             topic=topic, source=SOURCES[subject], section=section)
                lessons.append(dict(id=lesson_id,grade=grade,day=day,subject=subject,title=topic,questions=questions))
    data=dict(version=2,year=2026,description='Autorské precvičovanie podľa tematických a výkonových štandardov iŠVP; nie ministerská certifikácia.',
              sources=SOURCES,lessons=lessons)
    OUT.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    assert len(lessons)==84 and sum(len(l['questions']) for l in lessons)==336
    print('84 lessons / 336 questions written.')

if __name__=='__main__': build()
