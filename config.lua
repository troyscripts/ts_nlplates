Config = {}
Config.Version = '1.0.1'

-- Een controle bij starten; handmatig vanuit console: ts_nlplates_check
Config.VersionCheck = true

-- Onderstaande textures veranderen alleen het uiterlijk.
-- Nieuwe nummers en kentekenbewijzen worden onderaan ingesteld.
-- JG-menu: 0 = gewoon, 1 = oldtimer, 3 = luxe.
-- Andere bestaande basisstijlen krijgen een passende Nederlandse achtergrond.
-- DLC-platen vanaf index 6 worden niet vervangen (zie README).
Config.Textures = {
    { original = 'plate01', style = 'gewoon' },
    { original = 'plate02', style = 'oldtimer' },
    { original = 'plate03', style = 'oldtimer' },
    { original = 'plate04', style = 'luxe' },
    { original = 'plate05', style = 'gewoon' },
    { original = 'yankton_plate', style = 'gewoon' },
}

Config.DebugCommand = 'nlplaatinfo' -- false om uit te schakelen; alleen uitlezen

-- A = willekeurige letter; 1 = willekeurig cijfer. Maximaal 8 tekens incl. streepjes.
Config.PlateFormat = 'A-111-AA'
Config.NPCPlates = true
Config.NPCScanInterval = 2000

Config.Registration = {
    enabled = true,
    item = 'kentekenbewijs',
    showDistance = 3.0,
    command = 'kentekenbewijs', -- bekijken/tonen vanuit het dashboardkastje
    unknownOwner = 'Onbekend',
}
-- ESX: deze queries gebruiken uitsluitend parameters voor speler-/voertuiggegevens.
Config.OwnerQuery = [[
    SELECT v.owner, COALESCE(NULLIF(TRIM(CONCAT_WS(' ', u.firstname, u.lastname)), ''), ?) AS owner_name
    FROM owned_vehicles v LEFT JOIN users u ON u.identifier = v.owner
    WHERE v.plate = ? LIMIT 1
]]
