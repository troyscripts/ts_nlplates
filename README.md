# Troy Scripts — ts_bridge

**Versie 1.0.1** · FiveM · ts_antipunch 1.8.2, ts_hostage 1.1.9 en ts_keycard 1.1.7

## Nieuw in 1.0.1

Centrale voertuigadapters voor ts_nlplates 1.0.5, JG en MrNewb. Zie VOERTUIGEN.md en ../INSTALLATIE.md. Bestaande configschema blijft 0.0.6; nieuwe selectie staat in vehicle_config.lua.

## Nieuw in 1.0.0: binaire foto-upload

Foto's gaan server-side via de ingebouwde Node.js-runtime met een Buffer en
expliciete Content-Length naar Discord. Dit vermijdt de Lua HTTP-uploadroute
die nulbytes in JPEG-data kan afkappen. Geen externe pakketten, uploadprovider
of API-sleutel nodig. Screenshotopname, wachtrij en tekstfallback blijven bestaan.
Foutdetails uit FiveM's errorData worden nu ook uitgelezen.
Zie UPDATE-1.0.0.md voor installatie over 0.0.9. Config blijft ongewijzigd.

## Nieuw in 0.0.9: Discord-bevestiging en diagnose

Discord-verzending gebruikt `wait=true`. Bij een expliciete afwijzing van een
fotobericht (HTTP 400/413/415/422) volgt eenmaal een tekstbericht zonder foto.
`ts_bridge_check` toont nu ook het laatste screenshotresultaat, de laatste
Discord-uitkomst en de laatste Discord-fout, ook bij een lege wachtrij.
De precieze oorzaak van een uploadfout moet uit de nieuwe diagnose blijken.
Zie `UPDATE-0.0.9.md` voor installatie. Configuratie blijft ongewijzigd.

## Nieuw in 0.0.8: screenshottransport

Screenshots worden lokaal opgenomen via `requestScreenshot` en met een begrensd
latent FiveM-event naar de server gestuurd. De HTTP-upload naar het gameserverendpoint
vervalt. Discord-webhooks blijven server-side. Alleen aangevraagde antwoorden van
de juiste speler worden verwerkt; time-outs en ongeldige foto's geven een tekstlog.
Bij gelijktijdige opnames voor dezelfde speler kan een tekstlog met melding 'bezig'
volgen. Dit voorkomt dat screenshot-basic een nog lopende opname overschrijft.
De lokale screenshot-basic NUI-callback moet nog steeds werken. Een fout daarin
vereist controle van screenshot-basic zelf. Geen live FiveM-test uitgevoerd.

## Nieuw in 0.0.7: ambulancerekening

De serverconfig bevat de alias `ambulance = { 'society_ambulance' }` voor
betaalde ambulancekaarten uit ts_keycard 1.1.7. Controleer of die gedeelde
rekening in ESX bestaat. De gedeelde `config.lua` en de configschemaversie
blijven 0.0.6; bestaande bridge-exports blijven hetzelfde.

## Nieuw in 0.0.6: locaties, postcodes en persoonlijk negeren

Zie **UPDATE-LOCATIES.md** voor de actuele update-instructies en instellingen.
Meldingen via AlertJobs tonen optioneel een kaartgebied en dichtstbijzijnde postcode.
G zet een waypoint naar de exacte incidentlocatie; Backspace verwijdert alleen op
je eigen client de melding, tijdelijke blip en G-bestemming. Bestaande routes en
meldingen van collega's blijven intact. Het nieuwe paneel neemt geen invoerfocus.

Scriptversie en configschema zijn nu 0.0.6: de config bevat nieuwe velden.
server_config.lua blijft ongewijzigd. Hostage/antipunch/keycard hoeven niet bijgewerkt
te worden voor deze functie. De kaartupdate ts_gemertmap 1.0.6 levert de locaties.
Bij afwezige kaartgegevens blijft een fallbackmelding werken.
De onderstaande eerdere releasehoofdstukken beschrijven de voorgaande functies.


## Nieuw in 0.0.5: gedeelde camera en combatcontexten

De bridge beheert aanvragen van antipunch 1.8.2 en hostage 1.1.9. First person
blijft actief totdat de laatste deelnemer loslaat. De ped- en voertuigcamera
hebben ieder eigen aanvragen en een oorspronkelijke stand. De worker draait
iedere frame zolang aanvragen/contexten of een herstelvertraging actief zijn.
Er is geen cameraloop nodig als deze niet worden gebruikt.

Het updatepakket bevat alleen gewijzigde/nieuwe bestanden voor bridge 0.0.4.
Zie INSTALLATIE.md. Scriptversie en version.json zijn 0.0.5; configschema blijft
0.0.3. Bestaande config.lua/server_config.lua en de server-API blijven behouden.
Keycard 1.1.5 blijft compatibel. De oudere release-uitleg hieronder beschrijft
voorgaande uitbreidingen; de huidige installatie-informatie staat hier en in
INSTALLATIE.md.

### Nieuwe client-API

```lua
exports.ts_bridge:RequestFirstPerson('aim', {
    scope = 'ped', -- 'ped' of 'vehicle'
    restore = true,
    restoreDelayMs = 50, -- geheel getal 0 t/m 60000
    defaultCamera = 1 -- 0, 1, 2 of 4
})
-- Aanvragen bij statuswisseling; de bridge blijft zelf iedere frame forceren.
exports.ts_bridge:ReleaseFirstPerson('aim')

-- Gerichte integratie met antipunch. Schiet-/slagblokkeringen blijven actief.
exports.ts_bridge:SetCombatContext('animation', {
    suspendCamera = false,
    suspendMeleeCancel = true
})
exports.ts_bridge:SetCombatContext('animation', nil)
local context = exports.ts_bridge:GetCombatContext()
```

RequestFirstPerson, ReleaseFirstPerson en SetCombatContext geven true bij
acceptatie en false bij ongeldige parameters/ontbrekende aanroeper. Een ontbrekende,
dode of fataal gewonde ped krijgt geen camera-aanvraag. Keys zijn strings van 1
t/m 100 tekens. Dezelfde key vervangt de eigen aanvraag binnen dezelfde scope.
Een ander script kan jouw aanvraag of context niet verwijderen.

ReleaseFirstPerson verwijdert beide scopes van de eigen key. Een tweede argument
true vraagt onmiddellijk herstel; andere deelnemers behouden hun aanvraag.
Herstel gebeurt alleen wanneer de bridge zelf de camera wijzigde en deze nog in
first person staat. Vooraf zelf gekozen first person blijft behouden. De vertraging
van de laatste vrijgave geldt; opnieuw aanvragen annuleert het geplande herstel.

Als minstens één vrijgegeven deelnemer herstel vroeg, wordt de oorspronkelijke
stand na de laatste aanvraag hersteld. Anders blijft first person staan. De bridge
forceert voertuigaanvragen alleen in voertuigen en ped-aanvragen alleen te voet.

Resource-stop verwijdert alleen aanvragen/contexten van die resource. Overlijden,
pedwissel en bridge-stop ruimen alles op met herstel van actieve eigen
camerawijzigingen. Afnemers gebruiken daarnaast IsDead voor de geconfigureerde
ambulance-statekeys. Na bridgeherstart moeten de afnemers opnieuw starten.

GetCombatContext geeft de samengevoegde booleans suspendCamera en
suspendMeleeCancel. Bij wijziging volgt het lokale event
ts_bridge:combatContextChanged. Antipunch respecteert die pauzes als
Config.RespectCombatContexts = true. Hostage pauzeert alleen de melee-noodrem.
Er zijn geen net-events voor deze API toegevoegd; het is clientbesturing, geen
serverbeveiliging. Directe camerawijzigingen van andere scripts kunnen nog botsen.

De integratie is lokaal met gesimuleerde FiveM-functies getest; geen live FiveM-test.


Centrale ondersteuningsresource voor Troy Scripts. Lees INSTALLATIE.md voor installatie,
configuratie, teststappen en terugzetten.

Deze versie ondersteunt ESX-jobcontrole, ox_lib-meldingen, ox_target, politiemeldingen met
locatie en waypoint, Discord-webhooks en screenshot-basic. De gijzelingsregels,
handen-omhoog-functie en animaties blijven in ts_hostage.

Voor de keycard-aansluiting zijn inventory-, ESX-speler/rechten-, cash/bank- en
societyfuncties toegevoegd. Zie **KEYCARD-BANKING-BILLING.md** voor de volledige API.
Persoonlijke bankmutaties gebruiken Apex Banking. Society-mutaties gebruiken alleen
esx_addonaccount. Facturen aanmaken en opvragen gebruikt Apex Billing. Automatische
factuurbetaling is nog niet aangesloten; zie de concrete Apex-beperking in die handleiding. QBCore en Qbox zijn niet geïmplementeerd.
De bijbehorende scriptupdates vereisen deze bridgebuild. Start ts_bridge vóór beide scripts.
Er is geen Fiveguard-adapter toegevoegd; geen anticheatinstellingen worden gewijzigd.

## Bestanden

| Bestand | Functie |
| --- | --- |
| config.lua | Gedeelde instellingen zonder geheimen |
| server_config.lua | ESX, screenshotlimieten en centrale webhookroutes |
| client/main.lua | Meldingen, doodstatus en targetopties |
| client/alerts.lua | Straatnaam, meldingslocatie en waypoint |
| server/main.lua | Jobcontrole, jobmeldingen en diagnosecommand |
| server/webhooks.lua | Wachtrij, upload, JPEG-validatie en time-outs |

## Gebruik door andere resources

Zet `dependency 'ts_bridge'` in hun fxmanifest.lua en start ts_bridge eerst.
De onderstaande exports zijn de API van deze versie; hun namen zijn hoofdlettergevoelig.

### Client

```lua
exports['ts_bridge']:Notify({
    title = 'Troy Scripts', description = 'Actie uitgevoerd.', type = 'success'
})
local dead = exports['ts_bridge']:IsDead(PlayerPedId())
```

| Export | Resultaat / afspraken |
| --- | --- |
| Notify(string of table) | boolean; table gebruikt ox_lib-notificatievelden |
| IsDead(ped) | boolean; lokale dood/laststand-state geldt alleen voor eigen ped |
| GetTargetResource() | ingestelde ox_target-resourcenaam |
| AddGlobalPlayer(options) | boolean; ox_target-opties inclusief callbacks |
| AddGlobalVehicle(options) | boolean; ox_target-opties inclusief callbacks |
| RemoveGlobalPlayer(name) | boolean; uitsluitend eigen geregistreerde optie |
| RemoveGlobalVehicle(name) | boolean; uitsluitend eigen geregistreerde optie |

Targetnamen moeten beginnen met de aanroepende resource plus `_`, bijvoorbeeld
`ts_hostage_player`. De bridge verwijdert opties bij het stoppen van de aanroeper
of zichzelf. Na een targetresource-herstart moet het aangesloten script zijn opties
opnieuw aanmelden; ts_hostage doet dit al.

### Server

```lua
local job, reason = exports['ts_bridge']:GetJob(playerId)
exports['ts_bridge']:Notify(playerId, { description = 'Actie uitgevoerd.' })
local sent = exports['ts_bridge']:AlertJobs(
    { police = true },
    { title = 'Politiemelding', description = 'Hulp gevraagd.', type = 'warning' },
    { x = 100.0, y = 200.0, z = 30.0 }, 60
)
```

GetJob geeft `{ name, grade, label }` of nil; een tweede waarde kan de ontbrekende
koppeling verklaren. Standalone geeft nil. AlertJobs geeft het aantal ontvangers;
controle gebeurt op serverjobs en heeft geen dienststatusfilter. Coördinaten moet
het aangesloten script zelf uit een geldige serveractie bepalen. Notify accepteert
één online speler-ID, geen broadcast-ID.

```lua
local accepted, reason = exports['ts_bridge']:SendWebhook('start', '', {
    username = 'Troy Scripts',
    embeds = { { title = 'Actie gestart', description = 'Voorbeeld' } }
}, { screenshot = true, playerId = playerId })
```

SendWebhook(route, fallbackUrl, payload, options) is uitsluitend server-side.
De route wordt opgezocht in TSBridgeServer.Webhooks[aanroependeResource][route].
Zonder centrale URL wordt de server-side fallbackUrl gebruikt. payload vereist minstens
één embed; mentions worden uitgeschakeld. true betekent geaccepteerd voor verwerking,
geen bevestiging van aflevering. false plus reden betekent niet aangenomen.

Alleen HTTPS Discord-webhooks op discord.com worden geaccepteerd. Screenshots worden
als JPEG-bijlage meegestuurd; zonder beschikbare foto volgt een tekstlog. De wachtrij
is centraal begrensd, met maximaal drie retries op HTTP 429. Time-outs van een POST
worden niet opnieuw verstuurd om dubbele logs te beperken. Eén screenshot wordt hoogstens
één keer afgehandeld, ook bij late of dubbele callbacks. Er zijn geen clientevents
waarmee spelers zelf jobs kunnen kiezen of een webhook/screenshot kunnen aanvragen.
De aanroepende serverresource blijft verantwoordelijk voor autorisatie van de actie.

## Validatie

De meegeleverde Lua-testscripts in beide resources controleren samen de bestaande gijzelingscontroles,
jobselectie, waypoint, webhooktransport, screenshots, betalingen, rechten, billingcontract en targetcleanup met gesimuleerde API's.
Voer tests uit vanuit de map van de betreffende resource met Lua 5.4, bijvoorbeeld
`lua tests/client_spec.lua`. De hostage-integratietests verwachten ts_bridge ernaast.
Live controle blijft nodig; zie INSTALLATIE.md.

## okok-keuzes

okokBanking is als ESX-bankaccountadapter toegevoegd. okokBilling heeft een voorbereide
providerkeuze, maar vereist nog jouw resourcebestanden voor de daadwerkelijke serverkoppeling.
Zie **OKOK.md**. Apex blijft standaard ingesteld; society-geld blijft bij esx_addonaccount.

## Status-API en locales

GetStatus() is aan beide kanten beschikbaar: `{api=1, version, side, features}`.
De server geeft tevens framework/resources/banking terug; de client de targetresource.
De aangesloten scripts controleren deze gegevens; ts_antipunch 1.8.2 en ts_hostage 1.1.9 vereisen minimaal 0.0.5.
Herstart afhankelijke scripts na een bridgeherstart; ze blijven na uitval niet automatisch actief.

TSBridgeConfig.Locale = 'nl' is standaard. Teksten staan in locales/nl.lua en Nederlandse
fallback is ingebouwd. Configuratievelden voor teksten blijven expliciet instelbaar.

## Nieuw in stabiele versie 0.0.3

Dezelfde API 1 blijft beschikbaar. Bestaande string- en table-aanroepen van Notify
werken zonder extra wachttijd; de limiet is optioneel en geldt per aanroepende resource
én melding-ID. Houd voor alle afwijzingen van één functie dezelfde ID aan.

```lua
exports.ts_bridge:Notify({
    id = 'gijzeling', title = 'Gijzeling', description = 'Geen speler dichtbij.'
}, 5000) -- false bij onderdrukking; true bij verzenden

exports.ts_bridge:RegisterRadialMenu({
    id = 'acties', label = 'Mijn acties', icon = 'circle',
    items = { { label = 'Voorbeeld', icon = 'circle', onSelect = function() end } }
})
exports.ts_bridge:RemoveRadialMenu('acties')

local actueel = exports.ts_bridge:CheckConfigVersion(Config.Version, '1.1.8')
```

RegisterRadialMenu/RemoveRadialMenu zijn clientexports. De bridge maakt IDs uniek
per resource en verwijdert eigen menu-items en callbacks bij resource-stop.
Als de bridge blijft draaien, worden radialregistraties na ox_lib-start hersteld.
Bij een volledige bridgeherstart moeten afhankelijke resources opnieuw starten;
verloren callbacks kunnen niet automatisch worden gereconstrueerd. Registraties uit een
andere resource blijven bij een gewone resource-stop bestaan.

CheckConfigVersion is beschikbaar op beide kanten; alleen de server print de
configstatus. De export vergelijkt schemaversies exact, wijzigt de config niet en
retourneert een boolean. Scripts bepalen zelf hun defaults en benodigde versie.
De bridge zelf verwacht TSBridgeConfig.Version = '0.0.3'. Het schemaversienummer
blijft bij toekomstige scriptupdates gelijk zolang de configuratie niet wijzigt.

Voor ts_hostage: gebruik de bijbehorende bijgewerkte 1.1.8, die minimaal bridge
0.0.3 en de nieuwe features controleert. De versie van hostage blijft 1.1.8 en
zijn configversie blijft 1.1.8. Gameplayregels blijven in hostage.

## Aanvulling binnen 0.0.3

Deze aanvulling behoudt scriptversie en configversie 0.0.3. Wie de eerdere 0.0.3
gebruikt, vervangt deze bestanden handmatig. De GitHub-versiecontrole kan twee
verschillende builds met hetzelfde versienummer niet onderscheiden.

### Configinhoud en diagnose

De bridge controleert nu ook de inhoud van config.lua en server_config.lua:
verplichte velden, providernamen, resourcenamen, tabellen, booleans, numerieke limieten
en centrale webhook-URL's. Onbruikbare configuratie blokkeert de operationele exports;
GetStatus retourneert dan ready=false en een lege featurelijst. Er worden geen
bankinstellingen automatisch vervangen. Herstel het gemelde veld en herstart.
Configversie en configinhoud zijn afzonderlijke controles.

`ts_bridge_check` is uitsluitend voor de serverconsole. Het toont configfouten,
providerstatus, billingbeschikbaarheid, aantallen wachtende logs/screenshots en of
GitHub is ingesteld. Webhook-URL's en tokens worden niet getoond. Via de serverexports
`GetDiagnostics()` en `GetWebhookStatus()` zijn deze gegevens ook opvraagbaar.
Billingbeschikbaarheid betekent dat de resource en vereiste adapter beschikbaar zijn;
de diagnose maakt geen testfactuur en voert geen geldmutaties uit.

### Servermeldingen met optionele limiet

```lua
exports.ts_bridge:Notify(playerId, {
    id = 'mijn_actie', title = 'Melding', description = 'Voorbeeld'
}, 5000)
```

De limiet geldt per resource, speler en melding-ID. Alle afwijzingen van dezelfde
actie kunnen dezelfde ID delen. Zonder cooldown blijven bestaande aanroepen werken.
Player-disconnect en resource-stop ruimen de bijbehorende limieten op.

### Webhooks en screenshots

Elke webhookbestemming heeft een eigen wachtrij. Een time-out of HTTP 429 bij één
bestemming houdt de andere bestemmingen niet op; dezelfde bestemming behoudt
verzendvolgorde zodra de logs in de wachtrij staan. Screenshotverwerking is asynchroon.
MaxQueue blijft een gezamenlijke bovengrens inclusief gereserveerde screenshotplekken.
Een volle totale wachtrij kan dus nog logs weigeren. Dit is geen onbeperkte buffering.
Bij screenshotfalen blijft de oorspronkelijke embedbeschrijving behouden; er komt een
extra Screenshot-veld bij. Is de embed al vol, dan wordt beschikbare berichttekst
gebruikt; de bestaande inhoud wordt niet vervangen. De console vermeldt de fout ook.
Onzekere POST-time-outs worden niet automatisch opnieuw verstuurd.

### Herstel van registraties

Bij een herstart van ox_target registreert een draaiende bridge de bewaarde globale
player-/vehicle-opties en nog bestaande lokale NPC-opties opnieuw. Na ox_lib-start
worden bewaarde radialmenu's opnieuw geplaatst, als de bridge zelf nog draait.
Gestopte eigenaars worden niet hersteld. Resource-stop verwijdert hun registraties.
Als ox_lib-uitval ook de bridge of afhankelijke scripts stopt, start die resources
opnieuw. Na een volledige bridgeherstart is opnieuw starten van scripts zoals
hostage nog nodig wegens hun eigen stopcontrole. Lopende gijzelingen worden niet hervat.

### GitHub-versiecontrole

Standaard controleert de server één keer, drie seconden na de start:
https://github.com/troyscripts/ts_brigde

Plaats de meegeleverde version.json in de **hoofdmap van de standaardbranch**,
naast fxmanifest.lua. Het bestand bevat version en download. De controle vergelijkt
stabiele versies numeriek, toont een repositorylink bij een nieuwere versie en
installeert niets automatisch. HTTP-fouten, ongeldige JSON en een time-out stoppen
het script niet. De repository en version.json moeten publiek leesbaar zijn.

Optioneel in TSBridgeServer (server_config.lua):
```lua
UpdateCheck = { Enabled = true, Repository = 'troyscripts/ts_brigde' },
```
Een oude server_config.lua zonder dit blok gebruikt dezelfde standaardwaarden.
Enabled=false schakelt de controle uit. De GitHub-naam ts_brigde is bewust overgenomen;
de FiveM-resourcemap blijft ts_bridge. Bij een volgende release werk je zowel de
manifestversie als version.json bij. Publiceren op GitHub is niet in deze download uitgevoerd.

Technische API-bron: [GitHub repository contents](https://docs.github.com/en/rest/repos/contents#get-repository-content).
De openbare repository kon vanuit deze omgeving niet live worden opgehaald;
versievergelijking en foutafhandeling zijn met gesimuleerde HTTP-antwoorden getest.

## Nieuw in 0.0.4: gedeelde GitHub-updatecontrole

De serverexport `CheckForUpdates(settings)` controleert de versie van de aanroepende
resource. De bridge gebruikt dezelfde code voor zijn eigen versiecheck. API 1 blijft
behouden en bestaande exports blijven werken. De configschema-versie blijft **0.0.3**:
config.lua en server_config.lua hoeven voor deze stap niet te worden vervangen.

```lua
exports.ts_bridge:CheckForUpdates({
    Enabled = true,
    Repository = 'troyscripts/ts_keycard',
    File = 'version.txt', -- version.txt of version.json; standaard version.json
    Branch = 'main' -- optioneel; zonder Branch gebruikt GitHub de standaardbranch
})
```

De bridge leest de lokale versie uit het manifest van de aanroeper. Per resource
wordt eenmaal per start gecontroleerd; dubbele aanroepen starten geen tweede aanvraag.
De export retourneert true bij plannen, false bij uitschakelen, ongeldige instellingen
of een al geplande controle. GitHub wordt na drie seconden benaderd met een time-out
van vijftien seconden. Resource-stop maakt oude callbacks ongeldig. Geen automatische
installatie; alleen stabiele X.Y.Z-versies en een veilige repository-downloadlink.
JSON bevat version en optioneel download; een tekstbestand bevat alleen het versienummer.

Keycard 1.1.5 gebruikt deze nieuwe export en vereist daarom minimaal bridge 0.0.4.
Hostage 1.1.8 blijft compatibel en houdt voorlopig zijn bestaande eigen updatechecker.
Kaartspecifieke rechten, uitgifte en intrekking blijven in keycard.
