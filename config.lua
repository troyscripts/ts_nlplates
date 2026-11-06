Config = {}
Config.Version = '1.0.5'

-- Een controle bij starten; handmatig vanuit console: ts_nlplates_check
Config.VersionCheck = true

-- Onderstaande textures veranderen alleen het uiterlijk.
-- Nieuwe nummers en kentekenbewijzen worden onderaan ingesteld.
-- JG/Sky-menu: 0 = gewoon, 6 = oldtimer (build 3095+), 3 = luxe.
-- Oude oldtimerindices 1/2 worden automatisch naar 6 omgezet.
-- Index 4 = taxi; andere bestaande basisstijlen krijgen een Nederlandse achtergrond.
-- Index 6 wordt voor oldtimer gebruikt; overige DLC-platen blijven ongewijzigd.
Config.Textures = {
    { original = 'plate01', style = 'gewoon' },
    { original = 'plate02', style = 'oldtimer' },
    { original = 'plate03', style = 'oldtimer' },
    { original = 'plate04', style = 'luxe' },
    { original = 'plate05', style = 'taxi' },
    { original = 'yankton_plate', style = 'gewoon' },
}

Config.DebugCommand = 'nlplaatinfo' -- false om uit te schakelen; alleen uitlezen

-- A = willekeurige letter; 1 = willekeurig cijfer. Maximaal 8 tekens incl. spaties.
Config.PlateFormat = 'A 111 AA'
Config.NPCPlates = true
Config.NPCScanInterval = 2000

Config.Registration = {
    enabled = true,
    item = 'kentekenbewijs',
    showDistance = 3.0,
    command = 'kentekenbewijs', -- bekijken/tonen vanuit het dashboardkastje
    unknownOwner = 'Onbekend',
}

-- Jobnamen krijgen het label uit ESX jobs, met optionele eigen bedrijfsnaam.
Config.CompanyNames = {
    taxi = 'Cab & Co',
    police = 'Politie',
    ambulance = 'Ambulance',
    mechanic = 'Mechanic',
}
Config.Replacement = {
    enabled = true,
    price = 250, -- euro; 0 = gratis
    account = 'bank', -- ESX account: bank of money
    society = 'society_police', -- ontvangt de kosten van een nieuwe kaart
    placeCommand = 'kentekenpunt',
    adminGroups = { admin = true, owner = true, superadmin = true, god = true },
    interactDistance = 2.0,
    serverDistance = 3.0,
    label = 'Kentekenloket',
    blip = true,
    companyMinGrade = 3, -- bedrijfsbewijs vervangen: eigen job + minimaal deze rang
    cooldownSeconds = 30,
}

-- Taxiplaten: index 4 is gereserveerd voor blauw met donkere letters.
-- Voeg spawnnamen toe; deze modellen krijgen ALTIJD een taxiplaat (ook NPC's).
-- Andere modellen uit een gecontroleerde taxi-jobgarage krijgen dit automatisch.
Config.Taxi = {
    enabled = true,
    models = { 'taxi' }, -- voorbeeld: 'taxi', 'schafter2', 'stretch'
    jobs = { taxi = true },
    garages = { ['Taxi Gemert'] = true },
}
