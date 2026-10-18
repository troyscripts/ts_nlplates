# 1.0.1

- Centrale voertuigadapters voor ts_nlplates 1.0.5, JG en MrNewbVehicleKeys.
- GetInventory/GetInventoryItems en inventarisstopmelding toegevoegd.
- Nieuwe vehicle_config.lua; bestaande configschema 0.0.6 behouden.
- Zie VOERTUIGEN.md en ../VERWIJDERD.md.

## 1.0.0 — binaire Discord-foto-upload

- Nieuwe server/screenshot_upload.js gebruikt ingebouwde Node https en Buffer met expliciete Content-Length voor JPEG-uploads.
- Alleen base64-tekst gaat tussen Lua en JavaScript; de webhook blijft server-side.
- Wachtrij, berichtbevestiging, rate-limitafhandeling en tekstfallback blijven behouden.
- Geen automatische herhaling bij onzekere netwerkuitkomsten.
- Herstelt uitlezen van errorData bij mislukte Lua HTTP-aanvragen, inclusief HTTP-prefix en retry_after.
- Geen configwijziging of configversieverhoging, geen extra resource of npm-installatie.
- Gecontroleerd met Lua-tests en een multipart-rondtest die alle 256 bytewaarden, nulbytes en UTF-8-tekst exact terugleest. Live FiveM/Discord-test nog nodig.

## 0.0.9 — Discord-bevestiging en screenshotdiagnose

- Discord-webhooks vragen nu met wait=true om bevestiging van het opgeslagen bericht.
- Expliciet afgewezen fotoberichten (HTTP 400/413/415/422) worden eenmaal zonder foto aangeboden; originele loginhoud blijft behouden.
- Geen automatische herhaling bij onzekere netwerkuitkomsten of time-outs, om dubbele logs te voorkomen.
- ts_bridge_check toont de laatste screenshotstatus en het laatste Discord-resultaat, ook wanneer de wachtrij leeg is.
- HTTP-status, Discord-foutcode en foutvelden worden gelogd zonder webhook-URL, screenshotdata of berichtinhoud.
- Configuratie en configversie blijven ongewijzigd. Geen FiveManage-sleutel nodig.

# Changelog — ts_bridge

## 0.0.8

- Screenshotopname lokaal met requestScreenshot; JPEG-overdracht via een begrensd latent FiveM-event in plaats van HTTP-upload naar het gameserverendpoint.
- Server accepteert uitsluitend een eenmalig antwoord van de aangevraagde speler; JPEG- en groottelimieten blijven gelden.
- Opruiming bij timeout/disconnect en gerichte foutmeldingen; tekstlogging blijft beschikbaar.
- Discord-webhooks blijven uitsluitend server-side. Configuratie en configschema ongewijzigd.
- Gesimuleerde tests; live controle op de FiveM-server blijft nodig.

## 0.0.7

- Alias `ambulance` toegevoegd voor de gedeelde rekening `society_ambulance`.
- Compatibel met betaalde ambulancekaartuitgifte in ts_keycard 1.1.7.
- Script- en GitHub-versie verhoogd; gedeelde `config.lua` en configschema blijven 0.0.6.

## 0.0.6

- Kaartgebied en dichtstbijzijnde postcode bij de incidentlocatie via optionele ts_gemertmap-export.
- Afzonderlijk instelbare gebiedsnaam, postcode, straatnaam en postcode-afstandsgrens.
- Afsluitbaar NUI-paneel zonder muisfocus of rijblokkering, met G/Backspace en resterende tijd.
- Individueel negeren wist uitsluitend de eigen melding, tijdelijke blip en G-bestemming.
- Ontvangst/negeren/verlopen laten bestaande routes en meldingen van collega's intact.
- Nieuwste melding vervangt de vorige; verlopen of vervangen meldingen kunnen geen waypoint zetten.
- Configschema naar 0.0.6 vanwege nieuwe instellingen; server_config.lua ongewijzigd.
- Manifest/version.json naar 0.0.6. Bestaande camera- en server-API behouden.


## 0.0.5 — Gedeelde camera en combatcontexten

- RequestFirstPerson/ReleaseFirstPerson: aanvragen per resource en aparte ped-/voertuigcamera.
- Herstel pas na de laatste vrijgave; eigen first person, vertraging en snelle hervatting behouden.
- Aanvragen en contexten opruimen bij stop, dood of pedwissel.
- SetCombatContext/GetCombatContext voor gerichte camera- en melee-noodrempauzes.
- Nieuwe clientfuncties vermeld in GetStatus; bestaande server-API blijft behouden.
- Manifest en version.json naar 0.0.5 voor de GitHub-updatecontrole.
- Configschema blijft 0.0.3; bestaande config.lua en server_config.lua behouden.
- Antipunch 1.8.2 en hostage 1.1.9 gebruiken de nieuwe functies.
- Lokale integratie-/config-/updatecontroles uitgevoerd; geen live FiveM-test.

## 0.0.4 — Gedeelde GitHub-updatecontrole
- Nieuwe serverexport CheckForUpdates voor de aanroepende resource.
- version.txt en version.json, optionele branch, numerieke versievergelijking.
- Eén controle per resourcestart, timeout, beperkte antwoordgrootte en veilige downloadlink.
- Oude callbacks na resource-stop genegeerd; herstart kan opnieuw controleren.
- Eigen bridge-updatecontrole gebruikt dezelfde gedeelde implementatie.
- Keycard 1.1.5 aangesloten; eerdere script-API's blijven compatibel.
- Configschema blijft 0.0.3; geen vervanging van bestaande bridgeconfig nodig.


## Aanvulling binnen 0.0.3 — geen versieverhoging
- Configinhoud valideren; onbruikbare configuratie blokkeert operationele exports.
- Server-Notify ondersteunt cooldown per resource, speler en melding-ID.
- ts_bridge_check/GetDiagnostics: config-, provider-, billing- en wachtrijstatus zonder geheimen.
- Webhookwachtrijen per bestemming; totale bovengrens en screenshotreserveringen behouden.
- Screenshotfalen behoudt oorspronkelijke logtekst en voegt een foutveld toe.
- Bewaarde target-/NPC-/radialregistraties herstellen bij providerstart als bridge blijft draaien.
- Geen automatische hervatting van gestopte resources of lopende sessies na volledige bridgeherstart.
- GitHub-updatecontrole voor troyscripts/ts_brigde, version.json, veilige downloadlink en time-out.
- Apex Banking/Billing blijven de standaard. Geen nieuwe okok-integratie.
- Configschema blijft 0.0.3; bestaand server_config.lua werkt, UpdateCheck-blok is optioneel.
- Eerdere build 0.0.3 handmatig vervangen: versiecontrole onderscheidt gelijke versies niet.

## 0.0.3 — Stabiele release
- Beta-aanduiding verwijderd uit manifest, opstartmeldingen en actuele documentatie.
- Notify behoudt string/table-aanroepen en ondersteunt een optionele cooldown per resource en melding-ID.
- Invoer voor Notify wordt gekopieerd; de oorspronkelijke tabel wordt niet gewijzigd.
- RegisterRadialMenu/RemoveRadialMenu: eigen menu's per resource, inclusief opruimen van callbacks bij stop.
- CheckConfigVersion beschikbaar op client en server; bridgeconfigversie 0.0.3.
- GetStatus blijft API 1, met de nieuwe functies in features.
- ts_hostage 1.1.8 gebruikt nu de gedeelde meldingslimiet, configcontrole en radialadapter.
- Bestaande banking-, billing-, inventory- en target-API's behouden.
- Config.lua bijwerken: JA (Version toevoegen). Server_config.lua: geen nieuwe instellingen.
- Bestaande beperkingen voor QBCore/Qbox en automatische factuurbetaling blijven gelden.
- Lua 5.4 syntax en mock-/integratietests geslaagd; geen live FiveM/providertest.

## 0.0.2(BETA) — Aansluiting scripts, status-API en locales
- GetStatus-export op client en server met API 1, versie, functies en providergegevens.
- Ondersteunt verplichte controles in ts_hostage 1.1.7 en ts_keycard 1.1.4.
- Aanpasbare locales/nl.lua; Nederlands standaard en fallback.
- Bestaande Apex-, addonaccount-, inventory-, target- en webhookfuncties behouden.
- okokBilling blijft voorbereid; concrete adapter vereist de resourcebestanden.
- Installatiehandleidingen en tests bijgewerkt.


## 0.0.1(BETA)
- Eerste centrale bridge voor ts_hostage 1.1.6.
- Client/servermeldingen, lokale doodstatus en ESX-jobcontrole.
- Jobmeldingen met straatnaam, locatie en centraal waypointcommand.
- ox_target-exports met eigenaarschap en automatisch opruimen van opties.
- Server-side Discord-webhooks met centrale routes en bestaande URL als fallback.
- screenshot-basic-koppeling, JPEG-controle, timeout en tekstfallback.
- Begrensde gezamenlijke wachtrij en afhandeling van Discord HTTP 429.
- Consolecommand ts_bridge_check, API-documentatie en testinstructies.

### Aanvulling binnen dezelfde beta — geen versiewijziging
- Voorbereiding voor ts_keycard, zonder het kaartscript zelf aan te passen.
- ESX-persoonsgegevens, expliciete ACE/groep/jobrechten en rangen.
- ox_inventory-items, metadata en hooks met opruimen per aanroepende resource.
- NPC-targetopties, itemgebruik en ox_lib voortgang/dialogen.
- Cash- en bankmutaties met saldocontrole en herkenbare onzekere resultaten.
- esx_addonaccount-societyadapter met verse snapshots en rekeningaliases.
- Apex Banking-adapter voor persoonlijk banksaldo en mutaties, zonder fallback-afschrijving.
- Society-mutaties uitsluitend via esx_addonaccount; standaard society_police vóór oude spelling.
- Apex Billing-adapter voor aanmaken en opvragen, plus optioneel custom providercontract.
- Geen automatische factuurbetaling: de geconstateerde Apex-bijschrijvingscontrole vereist later werk in Apex.
- Tests voor mislukte mutaties, rechten, providerrestarts en invoicefouten.

### okok-aanvulling binnen 0.0.1(BETA)
- Instelbare okokBanking-provider voor het persoonlijke ESX-bankaccount.
- Geen gebruik van okok-societyexports; society blijft via esx_addonaccount.
- okokBilling-providerkeuze voorbereid; aanvragen worden geweigerd totdat de echte adapter is aangesloten.
- Instructies, beperkingen en providerregressietest toegevoegd. Apex-defaults behouden.
