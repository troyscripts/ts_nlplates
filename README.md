# ts_nlplates 1.0.1

Zelfstandige Nederlandse plaatachtergronden voor FiveM. Geen ts_bridge,
ESX, ox_lib of database nodig voor deze resource. JG Mechanic blijft
zelf verantwoordelijk voor toegang, aankoop en opslag van plateIndex.

## Installatie

Plaats ts_nlplates in je resources en voeg `ensure ts_nlplates` boven
`ensure jg-mechanic` toe in server.cfg. Bij een update de volledige
resource overschrijven en `restart ts_nlplates` uitvoeren.

## Mechanic-/tuningscript instellen

Er wordt **geen mechanic-config meegeleverd**. Pas de plaatkeuzes aan in
je eigen mechanic-/tuningscript. ts_nlplates vervangt de textures, maar
voegt zelf geen tuningmenu toe en regelt geen betaling of voertuigopslag.

### JG Mechanic

Onderstaande instructies zijn gebaseerd op JG Mechanic 1.9.0.

1. Maak een back-up van `jg-mechanic/config/config.mods.lua`.
2. Zoek in dat bestand de bestaande tabel `Config.Mods.PlateIndexes`.
3. **Vervang die volledige tabel** door onderstaande code. Voeg geen tweede
   tabel toe en laat de oude plaatkeuzes niet staan:

```lua
Config.Mods.PlateIndexes = {
  { modIndex = 0, name = "Gewone Nederlandse plaat" },
  { modIndex = 1, name = "Oldtimerplaat" },
  { modIndex = 3, name = "Luxe plaat" }
}
```

4. Zoek de bestaande regel met `modType = "PLATE_INDEX"` in hetzelfde
   bestand. Je kunt de menunaam wijzigen naar `Kentekenplaat`:

```lua
{ modType = "PLATE_INDEX", name = "Kentekenplaat", ignorePriceMult = true },
```

Vervang alleen de bestaande regel; voeg geen extra menuonderdeel toe.
Laat de overige tuninginstellingen en prijzen staan zoals ze zijn.
Zorg dat cosmetische tuning voor de gewenste mechaniclocatie is ingeschakeld.

5. Zet de startvolgorde in `server.cfg` als volgt, naast de bestaande
   dependencies van JG Mechanic:

```cfg
ensure ts_nlplates
ensure jg-mechanic
```

6. Herstart JG Mechanic wanneer niemand aan het tunen is. Start ook
   ts_nlplates als die nog niet actief is. In het plaatkeuzemenu horen nu
   uitsluitend de drie Nederlandse stijlen te staan.

JG Mechanic gebruikt zijn bestaande aankoop- en opslagfuncties.
Controleer na aankoop, inparkeren en uitparkeren of de stijl behouden blijft.
De garage moet het opgeslagen veld `plateIndex` ook weer toepassen.

### Andere mechanic-/tuningscripts

De bestandsnamen en menuopbouw verschillen per script. Gebruik daar deze
**GTA-plaatindices** voor de drie keuzes:

| Naam in het menu | GTA-plaatindex |
| --- | --- |
| Gewone Nederlandse plaat | `0` |
| Oldtimerplaat | `1` |
| Luxe plaat | `3` |

Dit zijn de waarden die aan `SetVehicleNumberPlateTextIndex` worden
meegegeven, niet de volgnummers 1, 2 en 3 van de menuregels. Verwijder
andere plaatkeuzes uit het betreffende menu. Kopieer de JG-tabel hierboven
alleen naar JG Mechanic; andere scripts kunnen een andere configuratievorm hebben.

Gebruik de bestaande preview-, betaal-, annuleer- en opslaglogica van je
mechanic. De gekozen plaatindex moet worden opgeslagen bij de voertuiggegevens
en bij het spawnen door de garage worden teruggezet. Een losse clientaanroep
van `SetVehicleNumberPlateTextIndex` regelt die opslag niet.
Bij een afgeschermd menu zonder configureerbare plaatkeuzes is ondersteuning
van de maker van dat mechanic-script nodig.

### Kentekennummers en bestaande voertuigen

Verander voor deze integratie uitsluitend de **plaatstijl**, niet het
kentekennummer. De nummers blijven per voertuig behouden; er staan geen
vaste nummers in de textures. Dit pakket genereert geen nieuwe nummers
en herstelt geen reeds bestaande dubbele kentekens.

Het verwijderen van menuopties zet bestaande opgeslagen plaatindices niet
automatisch om. Kies voor een voertuig met een oude DLC-plaat een van de
drie Nederlandse stijlen en sla die via het mechanic-menu op.

## Versiechecker

Scriptversie: 1.0.1. Config.Version: 1.0.0.
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

1. Controleer de serverconsole op script 1.0.1 en config 1.0.0 / config OK.
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
- Integratie gecontroleerd aan de hand van JG Mechanic 1.9.0: cl-vehicleprops.lua en framework/sv-functions.lua.
