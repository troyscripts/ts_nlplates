Config = {}
Config.Version = '1.0.0'

-- Een controle bij starten; handmatig vanuit console: ts_nlplates_check
Config.VersionCheck = true

-- Alleen het uiterlijk verandert. Kentekennummers en plateIndex blijven intact.
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
