# Middagsplanen

Planlegg middager for måneden, få handlelista regnet ut automatisk, og del alt med resten av husstanden. Appen kjører fra GitHub Pages og lagrer data i Supabase.

## Det du trenger

- En GitHub-konto
- En Supabase-konto med et prosjekt (gratisplanen holder)

Oppsettet tar rundt 15 minutter.

---

## 1. Sett opp databasen i Supabase

1. Åpne prosjektet ditt på supabase.com.
2. Gå til **SQL Editor** i menyen til venstre og trykk **New query**.
3. Åpne filen `supabase/schema.sql` fra denne mappen, kopier alt og lim det inn.
4. Trykk **Run**. Nederst skal det stå «Success. No rows returned».

Dette lager tabellene, tilgangsreglene (hver husstand ser bare sine egne data) og sanntidsoppdatering mellom telefonene.

## 2. Hent adressen og nøkkelen

1. I Supabase trykker du **Connect** øverst på siden, eller går til **Project Settings → API Keys**.
2. Kopier **Project URL**, som ser slik ut: `https://abcdefgh.supabase.co`.
3. Kopier den offentlige nøkkelen. Den heter **anon public** eller **publishable**.
   Ikke bruk nøkkelen som heter **service_role** eller **secret**. Den skal aldri ligge i appen.
4. Åpne `config.js` og lim inn begge verdiene:

```js
window.MIDDAG_CONFIG = {
  supabaseUrl: "https://abcdefgh.supabase.co",
  supabaseAnonKey: "eyJhbGciOi..."
};
```

Den offentlige nøkkelen er laget for å ligge i nettleseren. Det er tilgangsreglene fra steg 1 som beskytter dataene.

## 3. Last opp til GitHub

1. På github.com trykker du **+** øverst til høyre og velger **New repository**.
2. Kall det for eksempel `middagsplanen` og velg **Public**. GitHub Pages er gratis for offentlige repoer.
3. Trykk **Create repository**, og deretter lenken **uploading an existing file**.
4. Dra inn **alt innholdet i denne mappen**: filene og mappene `icons`, `data` og `supabase`. Ikke dra inn selve mappen.
5. Trykk **Commit changes**.

## 4. Slå på GitHub Pages

1. I repoet går du til **Settings → Pages**.
2. Under **Build and deployment** velger du **Source: Deploy from a branch**, så **Branch: main** og mappen **/ (root)**. Trykk **Save**.
3. Etter et minutt eller to står adressen øverst på siden, for eksempel
   `https://BRUKERNAVN.github.io/middagsplanen/`

## 5. Fortell Supabase hvor appen ligger

Dette gjør at lenkene i e-poster (bekreftelse og glemt passord) går tilbake til appen.

1. I Supabase går du til **Authentication → URL Configuration**.
2. Sett **Site URL** til adressen fra steg 4.
3. Legg til den samme adressen under **Redirect URLs**.

**Anbefalt:** Supabase sin innebygde e-post kan bare sende noen få e-poster i timen. Det enkleste for en husstand er å slå av e-postbekreftelse. Gå til **Authentication → Sign In / Providers → Email** og skru av **Confirm email**. Da kan man logge inn med en gang man har laget bruker.

## 6. Ta i bruk appen

1. Åpne adressen og trykk **Ny her? Opprett bruker**.
2. Velg **Opprett husstand**. La avhukingen for å ta med rettene og menyen fra den gamle appen stå på.
3. Nederst i appen står **husstandskoden**, som er seks tegn. Send den til kona.
4. Hun åpner samme adresse, lager sin egen bruker og velger **Bli med i en husstand** med koden.

Nå ser dere det samme, og endringer dukker opp på den andre telefonen med en gang.

## 7. Legg appen på hjemskjermen

**iPhone:** Åpne adressen i **Safari**, trykk på Del-knappen og velg **Legg til på Hjem-skjerm**.

**Android:** Åpne adressen i **Chrome**, trykk på ⋮ og velg **Installer app** eller **Legg til på startskjermen**.

Appen får da ikonet og åpnes i fullskjerm uten adresselinje.

---

## Endringer senere

Rediger eller last opp nye filer i GitHub-repoet. GitHub Pages oppdaterer seg selv i løpet av et par minutter, og telefonene får den nye versjonen neste gang appen åpnes.

## Godt å vite

- **Hva som er offentlig:** repoet er offentlig, så koden og `data/startdata.json` (rettene fra den gamle appen) kan ses av alle som finner det. Menyene og alt dere legger inn senere ligger bare i Supabase. Vil du, kan du slette `data/startdata.json` fra GitHub etter at husstanden er opprettet.
- **Den gamle appen** på claude.ai blir ikke oppdatert når dere bruker denne, og omvendt.
- **Gratisplanen hos Supabase** pauser prosjekter som ikke er brukt på en uke. Bruker dere appen jevnlig, skjer ikke det. Skjer det likevel, trykker du **Restore** i Supabase.

## Filene

| Fil | Hva den er |
|---|---|
| `index.html` | Selve appen |
| `config.js` | Adressen og nøkkelen til Supabase |
| `supabase/schema.sql` | Databasen og tilgangsreglene, kjøres én gang |
| `data/startdata.json` | Rettene og menyen fra den gamle appen |
| `manifest.webmanifest`, `sw.js`, `icons/` | Gjør at appen kan installeres på telefonen |
