local ox = exports.ox_inventory
local ready, hooksInstalled = false, false
local npcBusy, npcDone, issuing, lastUse = {}, {}, {}, {}
local normalize = TSPlate.normalize

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Kentekenbewijs', description = message, type = kind or 'inform'
    })
end

local function reservePlate()
    if not ready then return false end
    for _ = 1, 100 do
        local plate = TSPlate.generate(Config.PlateFormat)
        if not MySQL.scalar.await('SELECT plate FROM owned_vehicles WHERE plate = ? LIMIT 1', {plate}) then
            local changed = MySQL.update.await(
                'INSERT IGNORE INTO ts_nlplates_numbers (plate) VALUES (?)', {plate})
            if changed == 1 then return plate end
        end
    end
    return false
end
exports('GeneratePlate', reservePlate)

local function vehicleFromId(netId)
    if type(netId) ~= 'number' or netId % 1 ~= 0 then return end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 or not DoesEntityExist(entity) or GetEntityType(entity) ~= 2 then return end
    return entity
end

local function occupiedByPlayer(entity)
    for _, id in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(id)
        if ped ~= 0 and GetVehiclePedIsIn(ped, false) == entity then return true end
    end
    return false
end

local function formatNPC(entity)
    if not ready or not Config.NPCPlates or npcBusy[entity] or npcDone[entity] then return end
    if not DoesEntityExist(entity) or GetEntityType(entity) ~= 2 then return end
    local population = GetEntityPopulationType(entity)
    -- Alleen willekeurig verkeer/geparkeerde NPC's; missie- en scriptvoertuigen overslaan.
    if population < 1 or population > 5 or occupiedByPlayer(entity) then return end
    local oldPlate = normalize(GetVehicleNumberPlateText(entity))
    if oldPlate == '' then return end
    npcBusy[entity] = true
    local ok, err = pcall(function()
        if MySQL.scalar.await('SELECT plate FROM owned_vehicles WHERE plate = ? LIMIT 1', {oldPlate}) then
            npcDone[entity] = true
            return
        end
        -- Een al door deze resource uitgegeven nummer blijft na een resourcerestart behouden.
        if MySQL.scalar.await('SELECT plate FROM ts_nlplates_numbers WHERE plate = ? LIMIT 1', {oldPlate}) then
            npcDone[entity] = true
            return
        end
        local plate = reservePlate()
        if not plate or npcDone[entity] or not DoesEntityExist(entity) or occupiedByPlayer(entity)
            or normalize(GetVehicleNumberPlateText(entity)) ~= oldPlate then return end
        local pop = GetEntityPopulationType(entity)
        if pop < 1 or pop > 5 then return end
        SetVehicleNumberPlateText(entity, plate)
        -- RPC bevestiging: geen eindeloos herschrijven van kentekens.
        for _ = 1, 20 do
            Wait(100)
            if not DoesEntityExist(entity) then return end
            if normalize(GetVehicleNumberPlateText(entity)) == plate then
                npcDone[entity] = true
                return
            end
        end
    end)
    npcBusy[entity] = nil
    if not ok then print('[ts_nlplates] NPC-kenteken overgeslagen: ' .. tostring(err)) end
end

AddEventHandler('entityCreated', function(entity)
    SetTimeout(750, function() formatNPC(entity) end)
end)
AddEventHandler('entityRemoved', function(entity)
    npcDone[entity], npcBusy[entity] = nil, nil
end)

local function ownerOf(plate)
    local row = MySQL.single.await(Config.OwnerQuery, {Config.Registration.unknownOwner, plate})
    return row and row.owner_name or Config.Registration.unknownOwner
end

local function metadataFor(row, owner)
    return {
        plate = row.plate, documentId = tostring(row.id), model = tonumber(row.model),
        owner = owner, issued = row.issued_date,
        description = ('Kenteken: %s\nGeregistreerde eigenaar: %s'):format(row.plate, owner)
    }
end

local function ensureDocument(payload)
    local vehicle = vehicleFromId(payload.netId)
    if vehicle then npcDone[vehicle] = true end
    if payload.inventoryType ~= 'glovebox' or not Config.Registration.enabled then return end
    if not ready then return false end
    if not vehicle then return false end
    if npcBusy[vehicle] then
        notify(payload.source, 'Het kenteken wordt ingesteld. Open het kastje over een moment opnieuw.')
        return false
    end
    -- Na de eerste inventaristoegang staat het kenteken vast voor deze NPC.
    npcDone[vehicle] = true
    local plate = normalize(GetVehicleNumberPlateText(vehicle))
    if plate == '' or #plate > 8 then return end
    if issuing[plate] then return false end
    issuing[plate] = true
    local ok, err = pcall(function()
        local row = MySQL.single.await(
            "SELECT *, DATE_FORMAT(created_at, '%d-%m-%Y') AS issued_date FROM ts_nlplates_documents WHERE plate = ?", {plate})
        if not row then
            MySQL.insert.await('INSERT IGNORE INTO ts_nlplates_documents (plate, model) VALUES (?, ?)',
                {plate, tostring(GetEntityModel(vehicle))})
            row = MySQL.single.await(
                "SELECT *, DATE_FORMAT(created_at, '%d-%m-%Y') AS issued_date FROM ts_nlplates_documents WHERE plate = ?", {plate})
        end
        if not row then error('Registratie kon niet worden opgeslagen') end
        local items = ox:GetInventoryItems(payload.inventoryId) or {}
        local current
        for _, item in pairs(items) do
            if item.name == Config.Registration.item and item.metadata
                and tostring(item.metadata.documentId) == tostring(row.id) then
                current = item
                break
            end
        end
        if current then
            ox:SetMetadata(payload.inventoryId, current.slot, metadataFor(row, ownerOf(plate)))
            if tonumber(row.issued) ~= 1 then
                MySQL.update.await('UPDATE ts_nlplates_documents SET issued = 1 WHERE id = ?', {row.id})
            end
        elseif tonumber(row.issued) ~= 1 then
            local success, reason = ox:AddItem(payload.inventoryId, Config.Registration.item, 1,
                metadataFor(row, ownerOf(plate)))
            if success then
                MySQL.update.await('UPDATE ts_nlplates_documents SET issued = 1 WHERE id = ?', {row.id})
            else
                notify(payload.source, 'Geen ruimte voor het kentekenbewijs. Maak een slot vrij en open het kastje opnieuw.', 'error')
                print('[ts_nlplates] Bewijs niet toegevoegd: ' .. tostring(reason))
            end
        end
    end)
    issuing[plate] = nil
    if not ok then
        print('[ts_nlplates] Kentekenbewijs: ' .. tostring(err))
        notify(payload.source, 'Het kentekenbewijs kon niet worden geladen. Controleer de serverconsole.', 'error')
    end
end

-- Het bewijs mag meegenomen worden. De uitgiftetabel voorkomt opnieuw aanmaken.
local function installHooks()
    if hooksInstalled or GetResourceState('ox_inventory') ~= 'started' then return end
    hooksInstalled = true
    ox:registerHook('openInventory', ensureDocument, {typeFilter = {glovebox = true, trunk = true}})
end

local function resolveHeldItem(src, request)
    if type(request) ~= 'table' then return end
    local slot = tonumber(request.slot)
    if not slot or slot < 1 or slot % 1 ~= 0 then return end
    local inventory = src
    if request.netId then
        local entity = vehicleFromId(request.netId)
        local ped = GetPlayerPed(src)
        if not entity or ped == 0 or GetVehiclePedIsIn(ped, false) ~= entity then return end
        if GetPlayerRoutingBucket(src) ~= GetEntityRoutingBucket(entity) then return end
        -- Gebruik de echte ox-inventaris-ID, inclusief server trimplate-instelling.
        local raw = GetVehicleNumberPlateText(entity)
        inventory = 'glove' .. (GetConvarBool('inventory:trimplate', true) and normalize(raw) or raw)
        local inv = ox:GetInventory(inventory)
        if not inv then return end
    end
    local item = ox:GetSlot(inventory, slot)
    if not item or item.name ~= Config.Registration.item or item.count < 1 then return end
    return item, inventory
end

local function validTarget(src, target)
    if target == src then return GetPlayerPed(src) ~= 0 end
    if not target or not GetPlayerName(target) then return false end
    if GetPlayerRoutingBucket(src) ~= GetPlayerRoutingBucket(target) then return false end
    local from, to = GetPlayerPed(src), GetPlayerPed(target)
    return from ~= 0 and to ~= 0
        and #(GetEntityCoords(from) - GetEntityCoords(to)) <= Config.Registration.showDistance
end

RegisterNetEvent('ts_nlplates:document:show', function(request, target)
    local src = source
    if not ready or not Config.Registration.enabled then return end
    local now = GetGameTimer()
    if lastUse[src] and now - lastUse[src] < 1500 then return end
    lastUse[src] = now
    target = tonumber(target) or src
    if not validTarget(src, target) then
        return notify(src, 'De speler is niet dichtbij genoeg.', 'error')
    end
    local item, inventory = resolveHeldItem(src, request)
    if not item then return notify(src, 'Je hebt geen toegang tot dit kentekenbewijs.', 'error') end
    local id = tonumber(item.metadata and item.metadata.documentId)
    if not id then return end
    local row = MySQL.single.await(
        "SELECT *, DATE_FORMAT(created_at, '%d-%m-%Y') AS issued_date FROM ts_nlplates_documents WHERE id = ?", {id})
    if not row or normalize(item.metadata.plate) ~= row.plate then return end
    local owner = ownerOf(row.plate)
    -- Na database-await opnieuw bezit en afstand controleren.
    local held = resolveHeldItem(src, request)
    if not held or tostring(held.metadata.documentId) ~= tostring(row.id) or not validTarget(src, target) then return end
    local data = metadataFor(row, owner)
    ox:SetMetadata(inventory, item.slot, data)
    TriggerClientEvent('ts_nlplates:document:display', target, data, target == src)
    if target ~= src then notify(src, 'Kentekenbewijs getoond aan de speler.') end
end)

-- De command-route gebruikt uitsluitend een bestaand bewijs in het eigen dashboardkastje.
lib.callback.register('ts_nlplates:document:glovebox', function(src, netId)
    if not ready or not Config.Registration.enabled then return end
    local entity = vehicleFromId(netId)
    if not entity or GetVehiclePedIsIn(GetPlayerPed(src), false) ~= entity then return end
    local raw = GetVehicleNumberPlateText(entity)
    local id = 'glove' .. (GetConvarBool('inventory:trimplate', true) and normalize(raw) or raw)
    local inv = ox:GetInventory(id)
    if not inv then return end
    for _, item in pairs(inv.items or {}) do
        if item.name == Config.Registration.item then return item.slot end
    end
end)

AddEventHandler('playerDropped', function() lastUse[source] = nil end)
AddEventHandler('onResourceStop', function(name)
    if name == 'ox_inventory' then hooksInstalled = false end
end)
AddEventHandler('onResourceStart', function(name)
    if name == 'ox_inventory' then SetTimeout(1000, installHooks) end
end)

MySQL.ready(function()
    local ok, err = pcall(function()
        TSPlate.generate(Config.PlateFormat)
        local numbersExist = pcall(MySQL.query.await, 'SELECT plate FROM ts_nlplates_numbers LIMIT 0')
        if not numbersExist then MySQL.query.await([[CREATE TABLE IF NOT EXISTS ts_nlplates_numbers (
            plate VARCHAR(8) NOT NULL PRIMARY KEY,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]) end
        local documentsExist = pcall(MySQL.query.await, 'SELECT id, plate, model, issued, created_at FROM ts_nlplates_documents LIMIT 0')
        if not documentsExist then MySQL.query.await([[CREATE TABLE IF NOT EXISTS ts_nlplates_documents (
            id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            plate VARCHAR(8) NOT NULL UNIQUE,
            model VARCHAR(32) NOT NULL,
            issued TINYINT NOT NULL DEFAULT 0,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]) end
        -- Controleer de ESX-query direct; misconfiguratie stopt uitgifte.
        ownerOf('')
        -- Reeds bestaande voertuigen kunnen al sleutels of geladen inventarissen hebben.
        -- Deze blijven bij een resourcerestart ongemoeid.
        for _, vehicle in ipairs(GetAllVehicles()) do npcDone[vehicle] = true end
        ready = true
        installHooks()
    end)
    if not ok then print('[ts_nlplates] Registratie niet gestart: ' .. tostring(err)) end
end)

CreateThread(function()
    while true do
        Wait(math.max(1000, Config.NPCScanInterval or 2000))
        if ready and Config.NPCPlates then
            for _, vehicle in ipairs(GetAllVehicles()) do
                formatNPC(vehicle)
                Wait(0)
            end
        end
    end
end)
