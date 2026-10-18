# Aanvullende installatie en migratie

Lees eerst ../../INSTALLATIE.md voor de bridge-update 1.0.1 en nlplates 1.0.5.

## Bestaande kentekens met streepjes omzetten

**Alleen het formaat aanpassen repareert een al opgeslagen voertuig niet.**
De hulpresource `ts_nlplates_migrate` is daarom meegeleverd. Deze wordt niet permanent gestart.

1. Zet de server in onderhoud zodat niemand kan joinen; maak een databaseback-up.
2. Zorg dat alle spelers uitgelogd zijn, zodat inventarissen zijn opgeslagen.
3. Stop ts_nlplates, ts_bridge, JG Dealerships, JG Advanced Garages, MrNewbVehicleKeys, ox_inventory en es_extended.
   Laat oxmysql draaien. Stop ook andere resources die voertuigen/inventarissen opslaan.
4. Plaats de map ts_nlplates_migrate in resources en voer in de serverconsole uit:

   ```
   refresh
   ensure ts_nlplates_migrate
   ts_nlplates_spaties controle
   ```

5. De controle toont de omzettingen en schrijft niets. Bij een botsing met een bestaand kenteken wordt gestopt.
6. Is de controle goed en heb je de back-up? Voer uit:

   ```
   ts_nlplates_spaties uitvoeren
   ```

7. Herstart daarna de **volledige server**. Verwijder de tijdelijke hulpresource uit je startconfig.

De omzetting selecteert het oude door dit script gegenereerde patroon, zoals O-396-MV.
Ze wijzigt de gevonden plate-kolommen, ESX voertuigproperties, inventaris-JSON, opgeslagen
ox-stashnamen en exacte JSON-kentekenwaarden in gevonden key/lock-tabellen, binnen één transactie.
Niet-InnoDB-tabellen en gevonden kentekenbotsingen stoppen de omzetting.

Externe opslag, KVP-bestanden, versleutelde data en hashes zijn niet te reconstrueren met deze hulpresource.
MrNewbVehicleKeys bevat versleutelde onderdelen: de omzetting van iedere mogelijke interne sleutelopslag
kan daarom niet worden gegarandeerd. Test na de omzetting garage, slot en sleutelitems.
Andere eigen scripts met afwijkende kolomnamen hebben een aanvullende koppeling nodig.
De install.sql zelf zet geen voertuigkentekens om.

## Kentekenloket plaatsen

Geef je beheerders de ACE-permissie `admin`, bijvoorbeeld in server.cfg:

```cfg
add_ace group.admin admin allow
```

Je speler moet uiteraard al aan die principal gekoppeld zijn.

- Ga naar de gewenste locatie en gebruik **/kentekenpunt**.
- Verplaatsen: voer hetzelfde commando op de nieuwe locatie uit.
- Verwijderen: **/kentekenpunt verwijder**.
- De server gebruikt je echte positie en controleert ACE admin.
- De locatie wordt opgeslagen in ts_nlplates_settings en opnieuw geladen na een herstart.
- Er is één gedeeld loket in de normale wereld (routing bucket 0).

Spelers lopen naar het loket, drukken E en vullen hun kenteken met spaties in.
Alleen de geregistreerde eigenaar of een werknemer met dezelfde job en voldoende rang mag vervangen.

## Kosten en politiebetaling

In ts_nlplates/config.lua:

```lua
Config.Replacement = {
    enabled = true,
    price = 250,
    account = 'bank', -- 'money' voor contant
    society = 'society_police',
    placeCommand = 'kentekenpunt',
    adminAce = 'admin',
    interactDistance = 2.0,
    serverDistance = 3.0,
    label = 'Kentekenloket',
    blip = true,
    companyMinGrade = 3,
    cooldownSeconds = 30,
}
```

Verander price naar het gewenste bedrag; 0 betekent gratis.
Betaalde vervanging vereist een bestaande gedeelde esx_addonaccount-rekening society_police.
Bij ontbrekende rekening of onvoldoende saldo start de uitgifte niet.
Een volle inventaris of mislukte databaseopslag start een gecontroleerde terugbetaling. Bij onzekere resultaten blijft een betaalmarkering staan voor handmatige controle (zie de hoofdhandleiding).
Na een geslaagde uitgifte wordt het bedrag aan de politierekening toegevoegd.
De betaling loopt via de geldexports van ts_bridge. De bestaande bridgebankprovider bepaalt de persoonlijke bankrekening; de societyrekening loopt via de bridge naar esx_addonaccount.
Koppel/synchroniseer een eventueel ander bankscript met deze bestaande societyrekening.

## Nieuw document, oud bewijs nietig

- Eerste bewijs: bijvoorbeeld TS-0000042.
- Vervanging: bijvoorbeeld TS-0000042-05.
- Uitgiftenummers worden niet hergebruikt; mislukte aanvragen kunnen gaten veroorzaken.
- Het oude item wordt niet onzichtbaar verwijderd: het blijft als ongeldig bewijs bestaan.
- Bij gebruik wordt de actuele geldigheid serverzijdig gecontroleerd, ook als iemand anders het oude bewijs bezit.
- De inventorybeschrijving wordt bijgewerkt wanneer het bewijs wordt gebruikt of in het geopende kastje wordt gevonden.
  Een ongeopende inventaris kan dus nog de oudere omschrijving tonen; de kaartweergave controleert altijd de registratie.
- Een document dat al vóór de update openstond wordt niet live hertekend; opnieuw openen toont de nieuwe status.
- Is er nog nooit een bewijs uitgegeven? Open eerst het dashboardkastje.

## Bedrijfsnaam

Voor opgeslagen JG-jobvoertuigen wordt job_vehicle/owner uit owned_vehicles gebruikt.
Voor jobgarage-spawners wordt het JG TakeOutVehicle-event verwerkt; de server controleert
de job, minimumrang, het model en de nabijheid van de garage tegen Config.JobGarageLocations.

Het bedrijfslabel komt uit ESX jobs.label, met voorrang voor Config.CompanyNames.
Je kunt daar bijvoorbeeld `taxi = 'Cab & Co'` instellen.
Een persoonlijke auto wordt niet zomaar een bedrijfsauto omdat de bestuurder een job heeft.
Spawner-voertuigen die vóór deze update al buiten stonden moeten opnieuw uit de garage worden gehaald.
Dit ondersteunt de jobgarages in Config.JobGarageLocations; dynamische/afwijkende garageproviders
hebben een eigen serverkoppeling nodig. Foutief dubbele vaste kentekens blijven ongeschikt als unieke registratie.

## Testen

Lokaal gecontroleerd met Lua-/JS-syntaxcontroles en tests met nagebootste FiveM/ESX/ox/mysql-interfaces:
spaties, oude documenten zonder revisie, nietigverklaring, nieuwe serienummers, ACE-rechten,
locatiecontrole, eigendom, bedrijfsrangen, prijs, politiebetaling, terugbetaling en migratiebotsingen.

Nog live te testen op jouw server:
- Koop en spawn een nieuwe auto; garage en sleutel werken.
- Zet een oud streepjeskenteken om en haal de auto weer uit de garage.
- Plaats/verplaats het loket als admin; een gewone speler mag dit niet.
- Vervang een bewijs; saldo daalt en society_police stijgt met dezelfde prijs.
- Toon het oude bewijs aan een tweede speler: NIETIG VERKLAARD.
- Haal een bedrijfsauto op en controleer de bedrijfsnaam.
- Herstart: loket, documentgeldigheid en kentekens blijven behouden.
