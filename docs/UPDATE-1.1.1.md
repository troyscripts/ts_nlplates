# Update 1.1.1: Nederlands standaard spawnpatroon

Deze update stelt de standaard FiveM-generator in op `Config.PlateFormat`, standaard `A 111 AA` (bijvoorbeeld `K 482 RT`). De achtergrond en het font waren al Nederlands.

## Reikwijdte

Dit werkt voor voertuigen die hun nummer van de standaard FiveM-generator krijgen. Een expliciet door JG of een ander script ingesteld nummer wordt NIET vervangen. De JG-spawncode in het eerder gedeelde pakket is afgeschermd; daarmee is niet vastgesteld welke generator jouw voertuig gebruikt. Dit is dus nog geen bewezen oplossing voor jouw specifieke JG-spawn.

Opgeslagen kentekens worden niet gemigreerd. Er wordt geen SetVehicleNumberPlateText aangeroepen. De standaardweergave van voertuigen zonder expliciet nummer kan wel veranderen; installeer daarom met een volledige serverherstart en laat alle spelers opnieuw verbinden. Alle clients moeten hetzelfde patroon gebruiken.

## Installatie

Gebaseerd op ts_nlplates 1.1.0 van GitHub. Maak een back-up. De zip bevat alleen gewijzigde/nieuwe bestanden met hun volledige resourcepad.

1. Vervang fxmanifest.lua, version.json en server/main.lua; voeg client/plate_pattern.lua toe. Neem de documentatie over.
2. Behoud je eigen config/config.lua. Zet daarin `Config.Version = '1.0.6'` en voeg `Config.DefaultPlatePattern = true` toe. Behoud `Config.PlateFormat = 'A 111 AA'` of je eigen formaat. De meegeleverde config is uitsluitend een standaardvoorbeeld; overschrijf daarmee niet je eigen taxi's, bedrijfsnamen en overige instellingen.
3. Start es_extended vóór ts_nlplates. Herstart de volledige server en verbind opnieuw.
4. Haal een nieuw spawnvoertuig uit JG. Controleer met /nlplaatinfo en met een tweede speler het nummer. Test sleutels, dashboardkastje/kentekenbewijs en terugplaatsen/uitnemen. Test ook een opgeslagen privéauto en een taxi.

Blijft het nieuwe JG-voertuig een willekeurig nummer zonder spaties krijgen? Dan wordt dat nummer expliciet ingesteld of overschrijft een andere resource het patroon. Een JG-generatorkoppeling is dan nog nodig. Verander het nummer niet achteraf: sleutels en inventaris kunnen al aan het oude nummer gekoppeld zijn.

Geen SQL-update nodig. Configversie 1.0.6, scriptversie 1.1.1. Niet ingame getest.

## Uitschakelen

Zet Config.DefaultPlatePattern op false en herstart de server; laat iedereen opnieuw verbinden. Een resource-stop reset bewust geen patronen van andere scripts.
