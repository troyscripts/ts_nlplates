# Troy Scripts — ts_nlplates 1.0.5

Nederlandse kentekens en toonbare kentekenbewijzen voor ESX/ox_inventory.
Configversie: 1.0.2.

## Benodigd

- ESX Legacy met owned_vehicles, users en jobs.
- ox_lib, oxmysql, ox_inventory en OneSync.
- Voor betaalde vervangingen: esx_addonaccount met society_police.
- Optionele meegeleverde aansluiting: JG Dealerships en JG Advanced Garages.
- ts_bridge 1.0.1, met de meegeleverde voertuigadapters voor JG en MrNewbVehicleKeys.
- De map ts_nlplates in dit pakket bevat ook de oorspronkelijke client.lua, stream/ en textures/.

Koppelingen lopen nu via ts_bridge. Zie ../INSTALLATIE.md en ../ts_bridge/VOERTUIGEN.md voor centrale selectie en uitbreiding.

## Installatie

Lees **docs/INSTALLATIE.md** voor de update, SQL, eenmalige omzetting van bestaande streepjeskentekens,
plaatsing van het loket en tests. Importeer install.sql in dezelfde database als ESX.
Behoud exact de resourcenaam ts_nlplates.

Start na oxmysql, ox_lib, ESX, esx_addonaccount, ox_inventory en ts_bridge; start JG daarna.
Nieuwe kentekens hebben standaard de vorm **O 396 MV**. Streepjes zijn in het formaat niet toegestaan.

## Koppelingen voor andere downloaders

Gebruik je eigen configuratiebestanden. JG-configs worden bewust niet meegeleverd; pas de regels hieronder toe op je eigen config.

### ox_inventory

Voeg aan data/items.lua toe:

```lua
['kentekenbewijs'] = {
    label = 'Kentekenbewijs', weight = 0, stack = false, close = true, consume = 0,
    description = 'Gebruik om het kentekenbewijs te bekijken of te tonen.',
    client = { export = 'ts_nlplates.useRegistration', image = 'kentekenbewijs.png' },
},
```

Neem ook het icoon kentekenbewijs.png uit dit pakket over naar web/images.
De server maakt het bewijs automatisch aan bij de eerste opening van een ondersteund dashboardkastje.
Een meegenomen bewijs wordt niet bij iedere opening opnieuw aangemaakt.

### JG Dealerships

Stel Config.PlateFormat in op **"A 111 AA"**.

Voeg bovenaan Framework.Server.VehicleGeneratePlate(seed, checkIfExists) in framework/sv-functions.lua toe:

```lua
if seed == Config.PlateFormat or seed == nil then
    if GetResourceState('ts_bridge') ~= 'started' then return false end
    local ok, plate = pcall(function()
        return exports.ts_bridge:GenerateVehiclePlate()
    end)
    return ok and plate or false
end
```

Dit staat al in het meegeleverde framework/sv-functions.lua. Vervang het oudere blok; voeg het niet dubbel toe.
Proefritten behouden hun eigen seed. De centrale export reserveert een uniek nummer.

### JG Advanced Garages — bedrijfsnaam bij spawners

Voeg aan config/config-sv.lua toe:

```lua
exports('TSGetJobGarages', function()
    return Config.JobGarageLocations or {}
end)
```

ts_bridge vertaalt het bestaande TakeOutVehicle:config-event naar het interne jobSpawned-event voor nlplates.
De server controleert de job, rang, het model en de locatie tegen de serverconfig.
De client mag geen willekeurige bedrijfsnaam als eigenaar doorgeven.

Opgeslagen jobvoertuigen worden herkend via job_vehicle/owner.
Het label komt uit jobs.label; Config.CompanyNames kan dit overschrijven.
Dynamische garageproviders en andere garagesystemen hebben een eigen bridge-adapter nodig.

### Andere dealer-/spawnscripts

Vraag vóór opslaan, spawnen en sleuteluitgifte een nummer aan:

```lua
local plate = exports.ts_nlplates:GeneratePlate()
if not plate then return end
-- Gebruik exact dit kenteken in voertuigproperties, database en sleutels.
```

Deze serverexport kan wachten op MySQL. Bestaande voertuigen worden niet tijdens het rijden hernummerd.

### Mechanic / tuning

Beperk de keuzes tot 0 = gewoon, 6 = oldtimer met witte letters en 3 = luxe.
De oude indices 1 en 2 worden omgezet naar 6. Witte oldtimerletters vereisen gamebuild 3095 of hoger.
Pas de keuzelijst in je eigen mechanic-resource aan; daarvan bestaat geen universele configregel.

## Kentekenloket

- /kentekenpunt: plaatsen of verplaatsen op je huidige positie.
- /kentekenpunt verwijder: verwijderen.
- Beide vereisen de ACE-permissie admin; locatie wordt in SQL bewaard.
- Prijs via Config.Replacement.price, betaalrekening via account.
- Opbrengst gaat naar Config.Replacement.society, standaard society_police.
- Vervangen wijzigt het documentnummer, niet het voertuigkenteken.
- Oude bewijzen blijven zichtbaar en tonen bij gebruik rood **NIETIG VERKLAARD**.
- Alleen de geregistreerde eigenaar of bevoegde medewerker van hetzelfde bedrijf mag vervangen.

## Commando's

- Serverconsole: ts_nlplates_check
- In voertuig: /nlplaatinfo
- Font: /nlplaatfont aan | uit | status
- Bewijs in dashboardkastje bekijken/tonen: /kentekenbewijs
- Eenmalige migratiehulp: zie docs/INSTALLATIE.md

Test garage, sleutels, politiebetaling en de twee kaartweergaven na installatie op je eigen server.

JG-sleutelfuncties moeten eveneens naar de bridge verwijzen. Zie de hoofdhandleiding voor de twee functies en behoud eigen wijzigingen in overige JG-code.
