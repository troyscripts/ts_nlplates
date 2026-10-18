# Troy Scripts — ts_nlplates 1.0.3

Nederlandse kentekenplaattextures en lettertype, met nieuwe kentekengenerator en toonbaar kentekenbewijs voor ESX en ox_inventory.

## Installatie

Gebruik de resourcenaam **ts_nlplates**. Deze versie vereist ox_lib, oxmysql, es_extended,
ox_inventory en OneSync. Start na deze dependencies en vóór JG Dealerships.

Bij dit updatepakket hoort INSTALLATIE.md in de hoofdmap. Volg die instructies:
ook JG Dealerships en de ox_inventory-itemdefinitie worden aangepast.
Voor een losse/publiceerbare release moet je deze update samenvoegen met het volledige
bestaande ts_nlplates-pakket, inclusief client.lua, stream/ en textures/.

## Kentekens en bewijs

- Instelbaar formaat in config.lua: standaard A-111-AA, bijvoorbeeld K-482-TR.
- Nieuwe JG-aankopen en nieuw NPC-verkeer gebruiken gereserveerde nummers.
- Bestaande spelerskentekens, script-/jobvoertuigen en proefritten blijven behouden.
- Geen automatische databasemigratie of wijziging van bestaande sleutelitems.
- Een kentekenbewijs wordt eenmalig toegevoegd bij eerste opening van het dashboardkastje.
- Gebruik het item vanuit je inventaris, of /kentekenbewijs vanuit het voertuig nadat je het kastje hebt geopend.
- Bekijken en tonen aan een speler binnen de ingestelde afstand.
- Actuele geregistreerde eigenaar uit ESX; onbekende eigenaar bij NPC's.
- Uitgenomen bewijzen worden niet telkens opnieuw aangemaakt.
- Alleen voertuigen met dashboardopslag in ox_inventory worden ondersteund.

De automatisch aangemaakte tabellen ts_nlplates_numbers en ts_nlplates_documents
bewaren nummerreserveringen en de eenmalige documentuitgifte.

## Mechanic/tuning

Plaatkeuzes: 0 = gewoon, 6 = oldtimer met witte letters, 3 = luxe.
Gebruik voor witte oldtimerletters minimaal gamebuild 3095.
Legacy oldtimerindices 1 en 2 worden door client.lua omgezet naar 6.
Beperk de keuzes in je mechanic/tuning-resource zelf tot deze drie opties.
De exacte configuratie daarvoor hangt af van je mechanic-resource; die is niet meegeleverd.

## Serverexport voor andere aankoopscripts

```lua
local plate = exports.ts_nlplates:GeneratePlate()
if not plate then return end
-- Gebruik dit nummer bij opslaan/spawnen en geef daarna pas sleutels uit.
```

De export kan wachten op de database en retourneert false als uitgifte niet mogelijk is.
Gebruik hem vóór de voertuigregistratie. Hergebruik nooit willekeurig een bestaande reservering.

## Commando's

- Serverconsole: ts_nlplates_check
- In voertuig: /nlplaatinfo
- Fonttest: /nlplaatfont aan | uit | status
- Kentekenbewijs: /kentekenbewijs

Script 1.0.3; config 1.0.1. De bestaande GitHub-versiecontrole blijft actief.
Geen ts_bridge nodig. Wijzig bij een ander ESX-naamschema Config.OwnerQuery.
