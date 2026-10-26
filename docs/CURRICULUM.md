# Denný plán – školský rok 2026/2027

Samostatný plán pre 8. a 9. ročník: 14 dní × 3 oblasti × 4 otázky. Spolu **336 autorských otázok v 84 lekciách**. Každá otázka obsahuje správnu odpoveď, vysvetlenie, tému, zdroj a časť štandardu. Otázky sa neopisujú z ministerských dokumentov; štandardy určujú tematickú väzbu.

## Oficiálne zdroje

- [Konsolidované znenie ŠVP pre nižšie stredné vzdelávanie 2026](https://www.minedu.sk/data/att/c77/37120.7389f3.pdf), zverejnené ministerstvom 29. 7. 2026.
- [Predmetové štandardy pre 2. stupeň ZŠ](https://www.minedu.sk/vzdelavacie-standardy-pre-2-stupen-zs/).
- [Matematika](https://www.minedu.sk/data/att/c58/22649.c42d94.pdf): 8. ročník s. 23–29; 9. ročník s. 30–39. Pytagorova veta je zaradená do 9. ročníka, s. 33.
- [Slovenský jazyk a literatúra](https://www.minedu.sk/data/att/f5c/22654.ca4c58.pdf): aplikačné jazykové a čitateľské kompetencie a záverečné ročníkové prehľady pojmov, s. 71–84. Plán kombinuje nové učivo a opakovanie už zavedených javov.
- [Geografia](https://www.minedu.sk/data/att/98c/22665.52e294.pdf): Slovensko v 8. ročníku, s. 17–19; Austrália/Oceánia, polárne oblasti a Amerika v 9. ročníku, s. 20–23. Mestá slúžia aj na doplnkový tréning orientácie v príslušných regiónoch.
- [Plán postupného zavádzania nového ŠVP](https://www.minedu.sk/data/att/c52/26566.4a7df1.pdf): nový program sa zavádza od prvého ročníka; nejde o automatické preradenie dnešných ôsmakov a deviatakov na prvý cyklus reformy.

Tento balík je precvičovanie vybraných oblastí, nie úplné pokrytie všetkých predmetov či celoročných osnov. Tematická väzba na štandard nie je ministerská certifikácia. Rozloženie do jednotlivých dní je autorské; učiteľ má zosúladiť použitie so školským ŠkVP. Databázové témy ostávajú označené `draft`, kým neprejdú pedagogickým schválením.

## Témy

| Deň | Matematika 8 | Matematika 9 | Slovenčina 8 | Slovenčina 9 | Geografia 8 | Geografia 9 |
|---|---|---|---|---|---|---|
| 1 | Celé čísla | Mocniny | Pravopis | Syntax | Poloha SR | Poloha Austrálie |
| 2 | Racionálne čísla | Odmocnina | Podstatné mená | Priraďovacie súvetie | Povrch SR | Príroda Austrálie |
| 3 | Výrazy | Rovnice | Prídavné mená, zámená | Podraďovacie súvetie | Vodstvo | Sídla Austrálie |
| 4 | Slovné úlohy | Nerovnice | Slovesá | Jazykové štýly | Podnebie | Oceánia |
| 5 | Trojuholník | Pytagorova veta | Neohybné druhy | Slohové postupy | Pohoria | Nový Zéland |
| 6 | Rovnobežník | Podobnosť | Podmet, prísudok | Národný jazyk | Kraje | Polárne oblasti |
| 7 | Lichobežník | Valec | Rozvíjacie členy | Dráma | Sídla | Severná Amerika |
| 8 | Kruh | Kužeľ | Jednoduchá veta | Lyrika | Hospodárstvo | USA, Kanada |
| 9 | Hranol | Ihlan | Slovná zásoba | Kompozícia | Ochrana prírody | Stredná Amerika |
| 10 | Pravdepodobnosť | Guľa | Lyrika | Pravopis | Cestovný ruch | Južná Amerika |
| 11 | Priemer | Štatistika | Epika | Argumentácia | Regióny | Brazília, Argentína |
| 12 | Súradnice | Grafy, závislosti | Komunikácia | Porozumenie textu | Mapa | Obyvateľstvo Ameriky |
| 13 | Číselné výrazy | Slovné úlohy | Porozumenie textu | Sloh | Obyvateľstvo | Prírodné riziká |
| 14 | Opakovanie | Opakovanie | Jazykový mix | Záverečná výzva | Súvislosti | Svetové súvislosti |

## Mapy a skóre

Každá geografická lekcia má dve mapové a dve výberové otázky. Hranice sú z Natural Earth, súradnice miest z GeoNames. Používa sa rovnaká projekcia pre tip aj cieľ, vzdialenosť sa počíta haversinovým vzorcom v kilometroch. Žiadne normalizované súradnice obrázka sa nepredstierajú ako skutočná vzdialenosť.

Plné body: do 10 km v SR, do 70 km v zahraničí. Lineárny pokles k nule: 250 km / 2 200 km. Najprv sa ukáže cieľ a vzdialenosť; až po ďalšom kliknutí sa odhalia body. Rovnaké pravidlá platia lokálne aj na serveri.

## Úpravy

Zdroj: `assets/content/fortnight.json`; reprodukcia: `python scripts/create_curriculum.py`. Snímka 56 miest je v `assets/content/places.json`, takže nie je potrebné sťahovať celý GeoNames archív. Pred publikáciou zmien overiť znenie, odpovede, jednotky, jednoznačnosť a ročník. Už nasadený obsah aktualizovať novou migráciou.
