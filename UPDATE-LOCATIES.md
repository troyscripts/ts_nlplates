# ts_bridge 0.0.5 → 0.0.6

Alleen gewijzigde/nieuwe bestanden. Vereist de bestaande complete bridge 0.0.5,
inclusief de eerdere camera-update. Kopieer deze update over die map; laat alle
andere bestanden staan. Geen bestanden verwijderen.

## Installatie

1. Maak een backup van de bridge en de kaart, inclusief eigen configuratie.
2. Beëindig actieve gijzelingen. Stop afhankelijke scripts (hostage, antipunch,
   keycard) en daarna ts_bridge. Stop ts_gemertmap voor het bijwerken.
3. Kopieer beide updatepakketten over hun bestaande resourcemappen.
4. Neem in ts_bridge/config.lua de nieuwe AlertDismissKey, AlertLocation en
   AlertBlip over en zet Version op '0.0.6'. Behoud eigen bestaande instellingen.
5. Neem in ts_gemertmap/config.lua Version en UpdateCheck over. Behoud je eigen
   ZoneNames en Points. De GitHub-repository mag voorlopig leeg blijven.
6. Start de kaart, de bridge en daarna de afhankelijke scripts opnieuw.

```cfg
ensure ox_lib
# Bestaande providers zoals ESX/ox_target/ox_inventory blijven in hun eigen volgorde.
ensure ts_gemertmap
ensure ts_bridge
ensure ts_antipunch
ensure ts_hostage
ensure ts_keycard
```

Start alleen geïnstalleerde scripts. server_config.lua hoeft niet te veranderen.
Hostage 1.1.9, antipunch 1.8.2 en keycard 1.1.5 krijgen geen eigen update voor deze
wijziging: de politiemeldingen lopen al via de bridge.

## Bediening

- G: stel een waypoint naar de exacte incidentcoördinaten in; sluit het paneel.
- Backspace: negeer de actuele melding ALLEEN voor jezelf. Paneel, tijdelijke blip
  en opgeslagen G-bestemming verdwijnen. Een bestaande route blijft onaangeraakt.
- Andere agenten behouden hun melding en kunnen die wel aannemen.
- De melding verloopt na de opgegeven termijn (standaard 60 seconden).
- Een nieuwe melding vervangt de vorige op dezelfde client; er is geen verborgen
  wachtrij waar G later per ongeluk een oude bestemming uit kan ophalen.
- Als G en Backspace in dezelfde frame worden verwerkt, krijgt negeren voorrang.
  Een al eerder bevestigde route wordt door Backspace niet teruggedraaid.

Alleen G bevestigt een route; ontvangst, verlopen of negeren wijzigen geen route.
Het paneel gebruikt geen muisfocus en neemt geen rijbediening over. Toetsen kunnen
per speler bij FiveM-keybindings worden gewijzigd; het paneel toont de configdefaults.
Nieuwe defaults overschrijven geen al opgeslagen persoonlijke keybindings.

## Instellingen

De configschema-versie is 0.0.6 omdat de config nieuwe velden bevat. De scriptversie
is eveneens 0.0.6. Een volgende update zonder nieuwe configvelden hoeft deze
schema-versie niet te verhogen. Een oude config krijgt een versiewaarschuwing en
kan de ingebouwde defaults gebruiken; neem de nieuwe velden alsnog over.

| Instelling | Standaard | Werking |
| --- | --- | --- |
| AlertDismissKey | 'BACK' | Backspace; afzonderlijk binden via FiveM mogelijk. |
| AlertLocation.MapResource | 'ts_gemertmap' | Optionele provider van kaartgebied/postcode. |
| AlertLocation.ShowArea | true | Toon gebiedsnaam uit de mapconfig. |
| AlertLocation.ShowPostcode | true | Toon dichtstbijzijnde postcode bij het incident. |
| AlertLocation.ShowStreet | false | Voeg GTA-straat/kruising toe. |
| AlertLocation.MaxPostcodeDistance | 1500.0 | Verberg postcode als deze verder weg ligt; 0 = geen limiet. |
| AlertBlip | true | Tijdelijke incidentblip zonder route tot de melding wordt afgehandeld. |

Gebiedsnamen en postcodes komen via clientexport GetLocation uit de kaartresource.
De bridge kopieert geen postcodebestand. Gegevens worden per melding opgehaald,
niet iedere frame. Bij afwezige/oude/foutieve kaartprovider blijft de melding
werken met een native gebiedsnaam en/of coördinaten; postcode wordt dan weggelaten.
Postcodes blijven strings zodat bijvoorbeeld 001 zijn nullen behoudt.

Het afsluitbare paneel vervangt voor jobAlert de eerdere ox_lib-notificatie.
Andere Notify-meldingen blijven via ox_lib lopen. Uiterlijk: web/alerts.css;
Nederlandse teksten: locales/nl.lua. Het bestaande AlertJobs-contract blijft gelijk.
Dispatchmeldingen buiten deze bridge worden niet automatisch aangepast.

## GitHub en testen

Upload ook fxmanifest.lua en version.json met 0.0.6 naar je bestaande bridgerepository.
Deze ZIP publiceert niets. De kaart heeft eigen GitHub-instructies.

Getest met twee gesimuleerde agenten, echte 946-postcodedata, Lua-syntaxis en
JavaScript-tests. Geen live FiveM-/visuele game-test: controleer met twee spelers
negeren versus aannemen, bestaande achtervolgingsroute, time-out, twee opeenvolgende
meldingen en de locatie-/postcodenaam. Blijf de oorspronkelijke kaarttextures gebruiken.
