local resource = GetCurrentResourceName()
local dictionary = resource .. '_textures'
local replacements = {}
local fontDictionary = 'ts_nlplates_font'
local fontReplaced = false
local fontNames = { 'vehicle_generic_plate_font', 'vehicle_generic_plate_font_n' }
local oldtimerActive = false
local legacyOldtimerIndexes = {}
local oldtimerIndex = 6 -- eCola: vaste GTA-fontkleur #FEFEFE, vanaf build 3095.

local function removeFont()
    if fontReplaced then
        for _, name in ipairs(fontNames) do RemoveReplaceTexture('vehshare', name) end
        fontReplaced = false
    end
end

local function applyFont()
    if fontReplaced then return true end
    RequestStreamedTextureDict(fontDictionary, false)
    local startedAt = GetGameTimer()
    while not HasStreamedTextureDictLoaded(fontDictionary) do
        if GetGameTimer() - startedAt > 10000 then
            print(('[%s] Font kon niet laden; standaard GTA-letters blijven actief. Controleer stream/ts_nlplates_font.ytd.')
                :format(resource))
            return false
        end
        Wait(50)
    end
    for _, name in ipairs(fontNames) do
        AddReplaceTexture('vehshare', name, fontDictionary, name)
    end
    fontReplaced = true
    print(('[%s] Kentekenfont actief: lagere, stevigere tekens; bestaande kentekennummers behouden.')
        :format(resource))
    return true
end

local function removeTextures()
    oldtimerActive = false
    for _, name in ipairs(replacements) do
        RemoveReplaceTexture('vehshare', name)
    end
    replacements = {}
    removeFont()
    SetStreamedTextureDictAsNoLongerNeeded(fontDictionary)
end

CreateThread(function()
    local txd = CreateRuntimeTxd(dictionary)
    local loaded = {}
    for _, entry in ipairs(Config.Textures) do
        if not loaded[entry.style] then
            local diffuse = CreateRuntimeTextureFromImage(txd, entry.style,
                ('textures/%s.png'):format(entry.style))
            local normal = CreateRuntimeTextureFromImage(txd, entry.style .. '_n',
                ('textures/%s_n.png'):format(entry.style))
            if not diffuse or diffuse == 0 or not normal or normal == 0 then
                removeTextures()
                print(('[%s] FOUT: texture %s kon niet geladen worden.'):format(resource, entry.style))
                return
            end
            loaded[entry.style] = true
        end
        AddReplaceTexture('vehshare', entry.original, dictionary, entry.style)
        replacements[#replacements + 1] = entry.original
        AddReplaceTexture('vehshare', entry.original .. '_n', dictionary, entry.style .. '_n')
        replacements[#replacements + 1] = entry.original .. '_n'
        if entry.style == 'oldtimer' then
            if entry.original == 'plate02' then legacyOldtimerIndexes[1] = true end
            if entry.original == 'plate03' then legacyOldtimerIndexes[2] = true end
        end
    end
    if loaded.oldtimer then
        if GetGameBuildNumber() >= 3095 then
            AddReplaceTexture('vehshare', 'plate_mod_01', dictionary, 'oldtimer')
            replacements[#replacements + 1] = 'plate_mod_01'
            -- Deze DLC-plaat deelt yankton_plate_n; vervang geen fictieve plate_mod_01_n.
            oldtimerActive = true
            print(('[%s] Oldtimer: witte letters via plaatindex 6. Zet de mechanic-keuze op 6; oude indices worden omgezet.'):format(resource))
        else
            print(('[%s] Oldtimerletters blijven geel: witte stijl vereist gamebuild 3095 of hoger (huidig %s).'):format(resource, GetGameBuildNumber()))
        end
    end
    print(('[%s] %s | config %s | Nederlandse plaattextures geladen; kentekens behouden.')
        :format(resource, GetResourceMetadata(resource, 'version', 0), Config.Version))
    applyFont()
end)

CreateThread(function()
    while true do
        Wait(1000)
        if oldtimerActive then
            for _, vehicle in ipairs(GetGamePool('CVehicle')) do
                -- Alleen de eigenaar schrijft gesynchroniseerde voertuiggegevens.
                -- Geen controle opeisen, kentekentekst wijzigen of database bijwerken.
                if DoesEntityExist(vehicle)
                    and (not NetworkGetEntityIsNetworked(vehicle) or NetworkHasControlOfEntity(vehicle))
                    and legacyOldtimerIndexes[GetVehicleNumberPlateTextIndex(vehicle)] then
                    SetVehicleNumberPlateTextIndex(vehicle, oldtimerIndex)
                end
            end
        end
    end
end)

AddEventHandler('onClientResourceStop', function(stoppedResource)
    if stoppedResource == resource then removeTextures() end
end)

if Config.DebugCommand then
    RegisterCommand('nlplaatfont', function(_, args)
        local mode = (args[1] or 'status'):lower()
        if mode == 'uit' then
            removeFont()
        elseif mode == 'aan' then
            applyFont()
        elseif mode ~= 'status' then
            print(('[%s] Gebruik: /nlplaatfont aan | uit | status'):format(resource))
            return
        end
        print(('[%s] Font: %s. Test met een opnieuw gespawnd voertuig; bestaande platen kunnen gecachet zijn.')
            :format(resource, fontReplaced and 'aangepast' or 'standaard GTA'))
    end, false)
    RegisterCommand(Config.DebugCommand, function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == 0 then
            print(('[%s] Stap in een voertuig en voer het commando opnieuw uit.'):format(resource))
            return
        end
        print(('[%s] Kenteken: %s | plaatindex: %s'):format(resource,
            GetVehicleNumberPlateText(vehicle), GetVehicleNumberPlateTextIndex(vehicle)))
    end, false)
end
