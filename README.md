# ts_nlplates 1.0.2

Zelfstandige Nederlandse plaatachtergronden voor FiveM. Geen ts_bridge,
ESX, ox_lib of database nodig voor deze resource. JG Mechanic blijft
zelf verantwoordelijk voor toegang, aankoop en opslag van plateIndex.

## Installatie

Plaats ts_nlplates in je resources en voeg `ensure ts_nlplates` boven
`ensure jg-mechanic` toe in server.cfg. Kopieer bij het updatepakket alleen de meegeleverde bestanden over de
bestaande resource en voer `restart ts_nlplates` uit. Behoud je eigen config.

**Witte oldtimerletters vereisen gamebuild 3095 of hoger.** Controleer de
bestaande `sv_enforceGameBuild` in server.cfg. Verlaag een hogere build niet.
Bij een oudere build blijven de oude platen geel en meldt F8 waarom.
Een wijziging van de gamebuild vereist een volledige serverherstart.
Wijzig ook de oldtimerkeuze bij de mechanic van index 1 naar **6** (zie hieronder).

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
  { modIndex = 6, name = "Oldtimerplaat" },
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
| Oldtimerplaat | `6` |
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

Oude oldtimerindices 1 en 2 worden op build 3095+ automatisch naar 6 omgezet,
voor zover hun texture in Config.Textures aan oldtimer is gekoppeld. De controle
loopt eenmaal per seconde, alleen voor voertuigen waar de client controle over
heeft (of lokale NPC-voertuigen). De nummers veranderen niet. Het garagescript
slaat de nieuwe stijl op via zijn normale voertuigopslag; er is geen SQL-migratie.
Staat nog 1 of 2 opgeslagen, dan volgt de omzetting opnieuw na het spawnen.
Gebruik index 6 in het tuningmenu zodat preview, annuleren en aankoop geen
verouderde stijl gebruiken. Bestaande eCola-platen (6) krijgen ook de
oldtimerachtergrond. Andere DLC-platen veranderen niet automatisch.

## Versiechecker

Scriptversie: 1.0.2. Config.Version: 1.0.0.
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
De gedeelde GTA-lettertexture wordt vervangen door een eigen, lagere en
stevigere letterset (TS Plate Sans, afgeleid van DejaVu Sans Bold).
De kentekentekst zelf verandert niet. Oldtimer gebruikt op build 3095+
plaatindex 6 met GTA-fontkleur #FEFEFE (vrijwel wit). Dit verwijdert de gele
letters door een andere plaatbasis te gebruiken. Het is **geen instelbare
crème-tint**: de achtergrond-PNG bepaalt de letterkleur niet. Op oudere builds
blijven de oude oldtimerindices 1 en 2 geel. De index-6-plaat deelt de
North Yankton-normal map; die wordt niet afzonderlijk aangepast.
Moderne letters blijven donkerblauw. Luxe heeft een luxere
achtergrond/rand, geen echte opgelegde 3D-letters.

De herziene moderne textures hebben een beter zichtbare NL/EU-strook,
een donkere rand en rustiger geel. De symbolen staan hoger dan in de eerste 1.0.2. De nieuwe diffuse
textures zijn 1024x512; de bestaande normal maps blijven behouden.
De fysieke breedte/hoogte van de voertuigplaat wordt niet aangepast.
De nieuwe letterset verandert de vorm en hoogte van de zichtbare tekens;
de positie en tussenruimte blijven door GTA bepaald.
Een langwerpige Europese plaatvorm vraagt aanpassing van het voertuigmodel.

NPC-auto's met de standaard basistextures krijgen dezelfde vervangingen,
met behoud van hun eigen kentekennummer. Ook NPC-oldtimerindices 1/2 worden
naar 6 omgezet. Bestaande DLC-indices 7 t/m 12 blijven hun eigen texture gebruiken; kies
voor die voertuigen een van de drie stijlen bij JG. Modellen met eigen of
vast ingebakken platen vragen afzonderlijke model-/textureaanpassingen.
Gebruik geen tweede resource die dezelfde vehshare-plaattextures vervangt.

## Controle in FiveM

1. Controleer de serverconsole op script 1.0.2 en config 1.0.0 / config OK.
2. Zet twee auto's met verschillende kentekens naast elkaar.
3. Koop iedere stijl bij JG en test ook annuleren van een preview.
4. Parkeer in/uit en verbind opnieuw: de garage moet plateIndex terugzetten.
5. Laat een tweede speler de platen bekijken.
6. /nlplaatinfo in een auto toont kenteken en index in de F8-console.

Voor 1.0.2 zijn de nieuwe textures visueel en het updatearchief op inhoud gecontroleerd.
Fontladen, timeout en herstel bij stoppen zijn met nagebootste natives getest.
Geen live FiveM-test uitgevoerd: controleer vooral
of lange kentekens vrij van de blauwe strook blijven op jouw voertuigen.
Herstart de resource en verbind opnieuw voordat je dezelfde voertuigen vergelijkt.
De fontcorrectie is op aangeleverde in-game screenshots zichtbaar. De fysieke
afmetingen van de platen blijven ongewijzigd.

## Technische bronnen

- https://github.com/citizenfx/fivem/blob/master/ext/native-decls/CreateRuntimeTextureFromImage.md
- https://github.com/citizenfx/fivem/blob/master/ext/native-decls/AddReplaceTexture.md
- Integratie gecontroleerd aan de hand van JG Mechanic 1.9.0: cl-vehicleprops.lua en framework/sv-functions.lua.

## Fontcorrectie in 1.0.2

Kopieer ook `client.lua` en de volledige nieuwe `stream`-map uit het pakket.
`stream/ts_nlplates_font.ytd` wordt automatisch door FiveM gestreamd; geen
extra ensure of data_file-regel nodig. Config blijft 1.0.0.

1. Voer `restart ts_nlplates` uit en verbind opnieuw.
2. Controleer in F8 de melding `Kentekenfont actief`.
3. Gebruik opnieuw gespawnde voertuigen: bestaande gegenereerde platen kunnen
   de oude letters nog in de cache hebben.
4. Controleer verschillende nummers, onder andere met 0/O, 1/I, M/W en acht tekens.
5. Controleer gewone, luxe en oldtimerstijl en laat een tweede speler kijken.

Met de bestaande debugoptie ingeschakeld: `/nlplaatfont status`,
`/nlplaatfont uit` (standaard GTA-font op jouw client) en `/nlplaatfont aan`.
Spawn na wisselen een voertuig opnieuw om de fontcache niet mee te vergelijken.
De keuze wordt niet opgeslagen; een resourceherstart laadt weer het nieuwe font.

Het font is gedeeld: ook andere platen die `vehicle_generic_plate_font` gebruiken
krijgen deze lettervorm, inclusief DLC-platen met ongewijzigde achtergrond.
De kentekentekst en database worden niet door deze resource gewijzigd.
Voor witte oldtimerletters verandert de gebruikte plaatindex wel: 1/2 naar 6.
Pas de mechanic-config handmatig aan zoals hierboven beschreven.
Bij een laadtimeout blijft het standaardfont actief en verschijnt een melding.

De witte oldtimerroute is lokaal getest met nagebootste FiveM-natives voor
buildcontrole, selectieve omzetting, netwerkcontrole, laadfouten en stoppen.
De weergave en garage-/mechanic-integratie moeten nog in FiveM worden getest.
Test oldtimerindex 6, annuleren van tuning, opslaan/uitparkeren en zichtbaarheid
voor een tweede speler. Exact crème-wit is met deze route niet instelbaar.
Bij stoppen wordt de texture vervangen door de oorspronkelijke GTA-texture;
omgezette plaatindices blijven 6. Bij opnieuw starten keert het blauwe uiterlijk terug.

Kleurreferentie: https://github.com/DurtyFree/gta-v-data-dumps/blob/master/vehicleColors.json
(index 6, FontColorHex FFFEFEFE).
