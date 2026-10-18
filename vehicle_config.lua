-- Centrale voertuigadapters. Alleen hieronder genoemde providers zijn geïmplementeerd.
-- Framework, InventoryResource en Banking blijven in de bestaande bridgeconfig staan.
TSBridgeVehicles = {
    Enabled = true,
    Ownership = 'esx', -- owned_vehicles + users + jobs
    Inventory = 'ox', -- ox_inventory API; resourcenaam in bestaande config
    DatabaseResource = 'oxmysql',
    Dealer = { Provider = 'jg', Resource = 'jg-dealerships' },
    Garage = { Provider = 'jg', Resource = 'jg-advancedgarages' },
    Keys = { Provider = 'mrnewb', Resource = 'MrNewbVehicleKeys' }, -- of Provider = 'none'
    PlatesResource = 'ts_nlplates'
}
