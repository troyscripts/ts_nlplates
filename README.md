# Troy Scripts — ts_nlplates 1.0.9

Nederlandse kentekens en toonbare kentekenbewijzen voor ESX/ox_inventory.
Configversie: 1.0.5.

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
- Beide vereisen de frameworkgroep admin, owner, superadmin of god; locatie wordt in SQL bewaard.
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

## Webhook voor kentekenbewijzen

Zie ../WEBHOOK_INSTALLATIE.md: kaartafbeelding bij eerste en vervangende uitgifte, met optionele voertuigfoto. URL uitsluitend server-side instellen.


Zie [SKY-MECHANIC.md](SKY-MECHANIC.md) voor Sky-ondersteuning en installatie.

## Bijwerken naar 1.0.9

Bewaar je eigen config.lua en webhook_config.lua. Configversie blijft 1.0.4. Verwijder bij een bestaande installatie alle oude Lua-, SQL-, JSON- en Markdownbestanden uit `textures/`; behoud de zes PNG-bestanden. Alleen het fxmanifest.lua in de hoofdmap hoort bij deze resource. De dubbele scriptkopie onder textures is verwijderd.

De openbare versie bevat geen vaste ElectronAC-includeregel meer. ElectronAC of een andere anti-cheatresource is niet vereist; er hoeft geen Gemert RP-specifieke includeregel te worden toegevoegd. JG- en Sky-koppelingen zijn ongewijzigd.

## Taxiplaten — 1.0.9 / config 1.0.5

- `Config.Taxi.models` bevat spawnnamen die altijd een blauwe taxiplaat krijgen, ook als NPC of persoonlijk voertuig. Standaard: `taxi`.
- Voeg bijvoorbeeld toe: `models = { 'taxi', 'schafter2', 'stretch' }`.
- `Config.Taxi.jobs` en `Config.Taxi.garages` herkennen bedrijfsvoertuigen uit de gecontroleerde JG jobgarage-spawner. Taxi Gemert en job taxi zijn ingesteld. Een andere jobnaam/garagenaam kun je hier toevoegen.
- Garagevoertuigen worden gecontroleerd op job, rang, model, afstand en recent spawnen. Alleen in een taxi gaan zitten maakt een privévoertuig geen bedrijfsauto.
- JG's bestaande `TakeOutVehicle:config`-event wordt direct opgevangen. De meegeleverde JG bevat de benodigde serverexport `TSGetJobGarages` al; JG hoeft niet vervangen te worden. ts_bridge moet de bestaande `GetJobGarages`-adapter beschikbaar hebben.
- Plaatindex 4 is nu exclusief taxi (blauw, donkere letters). Gewone voertuigen met oude index 4 worden naar gewone index 0 gezet. Gewoon 0, oldtimer 6 en luxe 3 blijven beschikbaar. De keuze van taxi's wordt automatisch hersteld na tuning.
- Taxi-kentekenbewijzen krijgen een blauwe stijl en een volledig blauw kentekenvlak zonder EU-strook. Bestaande bewijzen worden bij bekijken of openen van het dashboardkastje bijgewerkt; een nieuwe kaart is niet nodig.
- Kentekennummers blijven gelijk; geen omzetting van bestaande kentekens of nieuwe SQL nodig. De bestaande bedrijventabel wordt gebruikt.

### Installeren en testen
1. Maak een backup en vervang de volledige map `ts_nlplates` door deze versie.
2. Neem eigen instellingen over in de NIEUWE config (versie 1.0.5), inclusief de nieuwe taxi-texture bij `plate05` en `Config.Taxi`.
3. Herstart de server, of herstart ts_nlplates en spawn testvoertuigen opnieuw.
4. Test taxi uit Taxi Gemert, een extra model uit die garage, een los gespawnde taxi en een gewone privéauto. Controleer ook met een tweede speler.
5. Open het dashboardkastje en bekijk/toon het kentekenbewijs. Controleer vervolgens terugplaatsen/uitnemen en een resourceherstart.

Voertuigen met een eigen vaste kentekentexture in het voertuigmodel kunnen de standaard GTA-plaattextures negeren. Visuele controle in FiveM blijft nodig.
