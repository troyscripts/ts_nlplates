-- Dit bestand wordt NOOIT naar clients gestuurd.
TSBridgeServer = {
    UpdateCheck = { Enabled = true, Repository = 'troyscripts/ts_brigde' }, -- controle, geen automatische installatie
    Banking = { Provider = 'apex', Resource = 'apex_banking' }, -- 'apex', 'esx' of 'okok' (Resource = 'okokBanking')
    Billing = { Provider = 'apex', Resource = 'apex_billing' }, -- 'apex', 'custom', 'none'; 'okok' vereist nog versiegebonden adapter

    -- okokBanking: persoonlijk ESX-bankaccount; society altijd via addonaccount hieronder.
    -- okokBilling: Resource = 'okokBilling'; eerst de echte serveradapter aansluiten.
    Framework = 'esx', -- 'esx' of 'standalone'; standalone heeft geen jobontvangers
    ESXResource = 'es_extended',
    InventoryResource = 'ox_inventory',
    SocietyResource = 'esx_addonaccount', -- gebruikt het ESX getSharedAccount-event
    SocietyAccounts = {
        -- Standaardrekening eerst; oude spelling uitsluitend als fallback.
        police = { 'society_police', 'socity_police' },
        ambulance = { 'society_ambulance' }
    },
    ScreenshotResource = 'screenshot-basic', -- screenshot-basic-compatibele export
    Screenshots = true,
    ScreenshotTimeoutMs = 8000,
    MaxImageBytes = 4 * 1024 * 1024,
    MaxQueue = 32, -- gezamenlijke bovengrens voor alle aangesloten scripts
    -- Optionele centrale webhookroutes, per aanroepende resource.
    -- Lege route: gebruik de bestaande server-side URL van het aangesloten script.
    Webhooks = {
        ts_hostage = { start = '', actions = '' }
    }
}
