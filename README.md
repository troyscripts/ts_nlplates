# ts_nlplates 1.0.0

Zelfstandige Nederlandse plaatachtergronden voor FiveM. Geen ts_bridge,
ESX, ox_lib of database nodig voor deze resource. JG Mechanic blijft
zelf verantwoordelijk voor toegang, aankoop en opslag van plateIndex.

## Installatie

Plaats ts_nlplates in je resources en voeg `ensure ts_nlplates` boven
`ensure jg-mechanic` toe in server.cfg. Bij een update de volledige
resource overschrijven en `restart ts_nlplates` uitvoeren.

Het volledige pakket bevat ook jg-mechanic/config/config.mods.lua voor de
geleverde JG Mechanic 1.9.0. Dit is alleen de aangepaste config, niet JG zelf.
Als deze integratie al is geplaatst, hoef je JG niet opnieuw aan te passen.
Maak anders een back-up, plaats de config en herstart JG wanneer niemand
aan het tunen is. Bewaar eventuele eigen latere configaanpassingen.

## JG-keuzes

- Index 0: Gewone Nederlandse plaat.
- Index 1: Oldtimerplaat.
- Index 3: Luxe plaat.

Alle overige keuzes zijn uit dit JG-keuzemenu verwijderd.
De native kentekennummers blijven behouden; er staan geen vaste nummers
in de textures. Dit pakket genereert geen nieuwe nummers en herstelt
geen reeds bestaande dubbele kentekens.

## Versiechecker

Scriptversie: 1.0.0. Config.Version: 1.0.0.
De server controleert bij starten de lokale configversie en eenmaal de
GitHub-versie. Handmatig controleren vanuit de SERVERCONSOLE:

```
ts_nlplates_check
```

Upload de INHOUD van de map ts_nlplates naar de hoofdmap van:
https://github.com/troyscripts/ts_nlplates

Daar moeten dus fxmanifest.lua en version.json rechtstreeks staan, niet
in nog een extra ts_nlplates-map. De repository moet openbaar zijn.
De checker probeert main/version.json en bij HTTP 404 master/version.json.
Andere branchnamen vragen een aanpassing van server.lua.
Bij toekomstige releases wijzig je de scriptversie in fxmanifest.lua en
version.json. Verhoog de configversie alleen als de configuratie wijzigt;
pas dan ook expectedConfig in server.lua en configVersion in version.json aan.
De lokale configcontrole gebruikt expectedConfig uit de geïnstalleerde
server.lua, niet de configversie van een nog niet geïnstalleerde update.

Config.VersionCheck = false schakelt de online controle uit.
Maximaal één controle per minuut; een antwoord na 15 seconden wordt genegeerd.
Geen tokens nodig, geen automatische updates of externe code-uitvoering.
Een GitHub-fout blokkeert de textures niet.

## Weergave en grenzen

De normale en luxe platen hebben een gele achtergrond met NL/EU-strook.
Oldtimer heeft een donkerblauwe achtergrond zonder EU-strook.
GTA-lettervormen en kleuren blijven behouden: oldtimerletters kunnen
geelachtig zijn en moderne letters donkerblauw. Luxe heeft een luxere
achtergrond/rand, geen echte opgelegde 3D-letters.

De NL/EU-symbolen zijn gecorrigeerd voor standaard GTA-plaatverhoudingen.
De fysieke breedte/hoogte en de kentekenletters worden niet aangepast.
Een langwerpige Europese plaatvorm vraagt aanpassing van het voertuigmodel.

NPC-auto's met de standaard basistextures krijgen dezelfde vervangingen,
met behoud van hun eigen kentekennummer. Er is geen NPC-stijldwang.
Bestaande DLC-indices 6 t/m 12 blijven hun eigen texture gebruiken; kies
voor die voertuigen een van de drie stijlen bij JG. Modellen met eigen of
vast ingebakken platen vragen afzonderlijke model-/textureaanpassingen.
Gebruik geen tweede resource die dezelfde vehshare-plaattextures vervangt.

## Controle in FiveM

1. Controleer de serverconsole op script 1.0.0 en config 1.0.0 / config OK.
2. Zet twee auto's met verschillende kentekens naast elkaar.
3. Koop iedere stijl bij JG en test ook annuleren van een preview.
4. Parkeer in/uit en verbind opnieuw: de garage moet plateIndex terugzetten.
5. Laat een tweede speler de platen bekijken.
6. /nlplaatinfo in een auto toont kenteken en index in de F8-console.

Lua-syntax, bestanden en textures lokaal gecontroleerd. De versiechecker
is met 12 gesimuleerde scenario's getest, inclusief nieuwere/oudere versie,
foutieve JSON, HTTP-fouten, timeout, master-fallback en configverschil.
Geen live FiveM-test uitgevoerd. De GitHub-repository was tijdens deze
sessie niet bereikbaar; de live controle is pas te bevestigen na upload.

## Technische bronnen

- https://github.com/citizenfx/fivem/blob/master/ext/native-decls/CreateRuntimeTextureFromImage.md
- https://github.com/citizenfx/fivem/blob/master/ext/native-decls/AddReplaceTexture.md
- Meegeleverde JG Mechanic 1.9.0-bron: cl-vehicleprops.lua en framework/sv-functions.lua.
