TSBridgeConfig = {
    Version = '0.0.6', -- configschema; alleen wijzigen na overnemen van nieuwe velden
    Locale = 'nl', -- Hoofdtaal; teksten staan in locales/nl.lua
    NotificationTitle = TSL('config_troy_scripts'),
    NotificationDuration = 5000,
    WaypointKey = 'G',
    AlertDismissKey = 'BACK', -- Backspace; per speler opnieuw te binden in FiveM
    AlertLocation = {
        MapResource = 'ts_gemertmap',
        ShowArea = true,
        ShowPostcode = true,
        ShowStreet = false,
        MaxPostcodeDistance = 1500.0 -- meter; 0 = geen afstandslimiet
    },
    AlertBlip = true, -- tijdelijke incidentblip; geen automatische route

    InventoryResource = 'ox_inventory', -- client useItem; gelijk houden aan server_config.lua
    TargetResource = 'ox_target', -- alleen een ox_target-compatibele resource
    DeadStateKeys = { 'dead', 'isDead', 'laststand' }
}
