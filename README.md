# Vedomax (React)

Vzdelávacia webová hra a precvičovanie učiva pre 8.–9. ročník základných škôl prepísaná z pôvodného Flutter projektu do moderného React + Vite + TypeScript prostredia s Tailwind CSS.

## Funkcie a herné mechaniky

1. **Matematika • Zachráň prieskumníka (Pytagorova veta)**
   - Vizuálne znázornenie pravouhlého trojuholníka (odvesny 3 m a 4 m, prepona = rebrík k prieskumníkovi).
   - Pomôcka $a^2 + b^2 = c^2$, validácia desatinných čísel (vrátane desatinnej čiarky) a tolerancie výpočtu.

2. **Slovenčina • Vetriť chybu (Detektívny režim)**
   - Školský príspevok s interaktívnymi slovnými tokenmi.
   - Tréning pravopisu s okamžitou spätnou väzbou a potvrdením nálezu.

3. **Geografia • Slepá mapa**
   - Interaktívna slepá mapa Slovenska (pomer strán 2:1) s lokalizáciou Bojnického zámku.
   - Možnosť umiestniť a posúvať špendlík pred potvrdením polohy s overením tolerancie.

4. **Herný cyklus a hodnotenie**
   - Časový limit (odpočítavanie s lineárnym indikátorom).
   - Zobrazenie skóre a XP odmien.
   - Vstavaná Lottie animácia hviezdy pre úspešné splnenie s podporou `prefers-reduced-motion`.
   - Možnosť opakovania výzvy alebo návratu do zoznamu úloh.

5. **Režimy používania**
   - **Demo režim:** Okamžité hranie bez registrácie (skóre pre aktuálny pokus, bez ukladania XP).
   - **Režim s účtom:** Prihlásenie/registrácia e-mailom a heslom, sledovanie XP, série dní (streak) a voliteľný rebríček najlepších hráčov (Top 50).

## Spustenie

```bash
npm run dev
```

Aplikácia beží na porte 3000 (`http://0.0.0.0:3000`).
