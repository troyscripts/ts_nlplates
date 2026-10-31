# Sky Mechanic — installatie en controle

Deze update bevat ts_bridge 1.1.3, ts_keycard 1.3.1 en ts_nlplates 1.0.7.
Configversies: bridge 0.1.0, keycard 1.2.1, nlplates 1.0.4. Script- en configversies zijn onafhankelijk. Elk deel is maximaal 9: na 0.0.9 volgt 0.1.0; na 0.9.9 volgt 1.0.0. Versiecontrole en actuele documentatie zijn bijgewerkt.

Vervang de drie volledige resources uit dit pakket en herstart de server. Bewaar eigen instellingen en webhook-URLs als die sinds de aangeleverde bestanden zijn gewijzigd. Deze update behoudt de aangeleverde waarden. Start ts_bridge vóór ts_keycard en ts_nlplates; Sky vereist daarnaast zijn eigen sky_base/sky_jobs_base afhankelijkheden. Geen SQL-migratie nodig.

## Monteurkaarten en betaling
De monteurafdeling bestaat al: ESX-job mechanic, item monteur_sleutelkaart, societyalias mechanic → society_mechanic. Hiervoor is geen aparte Sky-mechanicadapter nodig. Bij een andere jobnaam moet de betreffende afdeling plus societyalias worden aangepast. De bridge boekt via esx_addonaccount; het Sky-baasmenu moet dezelfde rekening gebruiken. Zonder jullie sky_jobs_base-config is dat laatste niet bevestigd. Er wordt geen tweede storting naar Apex gedaan.

## Kentekens
De bridge heeft GetVehicleRealPlate(vehicle) en HasVehicleFakePlate(vehicle), client en server. Vehicles.SkyFakePlates bevat Enabled en StateKey. De standaardstate is sky_fakePlate. Zonder actieve Sky-state wordt het zichtbare kenteken gebruikt; Sky is geen harde dependency.

Kentekenbewijzen, bedrijfsregistratie en voertuigfoto-selectie gebruiken het echte kenteken. NPC-nummergeneratie slaat voertuigen met actieve valse platen over, ook na database-wachttijd. Het zichtbare valse kenteken wordt niet overschreven. Inventaris-ID's blijven de zichtbare kentekenwaarde gebruiken, zoals in de aangeleverde ox-koppeling; deze update migreert geen dashboardkastjes. Als ox_inventory zelf is aangepast om echte kentekens te gebruiken, moet die koppeling apart worden afgestemd. De helper is geen bewijs van eigendom; bestaande servercontroles blijven gelden.

Sky tuning plate_index: gewoon 0, oldtimer 6 (gamebuild 3095+), luxe 3. Legacy 1/2 wordt door de bestaande nlplates-logica omgezet naar 6. Er wordt geen Sky-config of escrowcode gewijzigd. Een overstap van mechanic vervangt niet automatisch JG garage/dealership: die bestaande koppelingen blijven staan.

## Test op de server
1. Controleer de drie configversies bij opstarten.
2. Koop als mechanic een kaart: ontvanger betaalt €10, controleer society_mechanic én het Sky-baasmenu; gratis rang 7+ is behouden.
3. Open bij een eigen auto het dashboardkastje, plaats een Sky-valse plaat en controleer dat een bewijs het oorspronkelijke kenteken houdt. Het valse nummer blijft zichtbaar.
4. Laat een NPC-auto met valse plaat meerdere scans staan: het nummer mag niet veranderen.
5. Verwijder de valse plaat en controleer kastje/bewijs; test ook garage opslaan/ophalen en een herstart. Persistente Sky-valse platen in garages vallen onder Sky's garagekoppeling, niet onder deze update.
6. Test in Sky de stijlen 0, 6 en 3.

Offline syntax- en gerichte logische tests vervangen geen live FiveM-test.
