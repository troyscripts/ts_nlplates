# Voertuigadapters — 1.0.1

vehicle_config.lua is de centrale selectie voor de nieuwe voertuigmodule. Bestaande bridgegebruikers kunnen Enabled = false zetten als ze deze module niet gebruiken. Er is geen nieuwe verplichte oxmysql-dependency voor andere bridgefuncties; databaseaanroepen worden pas bij gebruik gedaan. nlplates vereist wel oxmysql en een actieve voertuigmodule.

| Onderdeel | Instelling | Geïmplementeerd |
| --- | --- | --- |
| Framework | server_config.lua Framework / ESXResource | ESX |
| Inventarisresource | config.lua én server_config.lua InventoryResource | ox_inventory API |
| Inventarisadapter | vehicle_config.lua Inventory | ox |
| Eigenaarsgegevens | Ownership | esx: owned_vehicles, users, jobs |
| Dealer | Dealer.Provider / Resource | jg / jg-dealerships |
| Garage | Garage.Provider / Resource | jg / jg-advancedgarages |
| Sleutels | Keys.Provider / Resource | mrnewb / MrNewbVehicleKeys; none schakelt uit |
| Kentekenleverancier | PlatesResource | ts_nlplates |
| Bankbetaling | server_config.lua Banking | bestaande esx/apex/okok-adapters |

Alleen de genoemde adapters zijn nu geïmplementeerd. Een nieuwe naam invullen maakt geen ondersteuning. Provider-ID kiest het protocol; Resource kiest de resourcenaam. Houd de standaard JG-resourcenamen aan: JG gebruikt ook vaste interne eventnamen.

Serverexports: VehicleExists(plate), GetVehicleOwner(plate), GetCompanyLabel(job), GetJobGarages(), GenerateVehiclePlate(), GetGloveboxId(rawPlate), VehicleIntegrationReady(). GetVehicleOwner retourneert nil voor onbekend, {identifier,name} voor persoonlijk of {job} voor bedrijf. Database-/adapterfouten stoppen de aanroep; behandel ze niet als een onbekende eigenaar. GenerateVehiclePlate accepteert uitsluitend de geselecteerde dealerresource als aanroeper.

Inventaris: GetInventory, GetInventoryItems zijn toegevoegd; bestaande GetInventorySlot, SetItemMetadata, AddItem, RemoveItem en RegisterInventoryHook worden hergebruikt. Hooks horen bij de aanroepende resource. Na inventoryStopped/inventoryReady meldt nlplates zijn hook opnieuw aan.

Clientexports: CloseInventory(), GiveVehicleKeys(entity), RemoveVehicleKeys(entity). De sleuteladapter roept dezelfde MrNewb GiveKeys/RemoveKeys aan als de oorspronkelijke JG-integratie. Het bestaande JG-jobgarage-event wordt vertaald naar het lokale ts_bridge:vehicle:jobSpawned-event; nlplates controleert alle bevoegdheden op de server.

Uitbreiding: voeg een adaptertak/module in de bridge toe, houd bovenstaande contracten gelijk en breid de gereedheidscontrole uit. Voeg provider-tests toe voordat je de keuze documenteert. nlplates hoeft niet te weten welke externe tabel, export of garage-event de adapter gebruikt. De eigen documentregistratie en SQL van nlplates blijven van nlplates.

Er is geen netwerkexport voor vrij uitgeven van kentekens of wijzigen van eigendom toegevoegd. Sleutelbeveiliging blijft bij het bestaande MrNewb-systeem.
