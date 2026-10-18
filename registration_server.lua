local bridge = exports.ts_bridge
local ready, hooksInstalled = false, false
local npcBusy, npcDone, issuing, lastUse = {}, {}, {}, {}
local normalize = TSPlate.normalize
local replacementBusy, replacementUse, born = {}, {}, {}
local counter
local versionsQuery = "SELECT revision, DATE_FORMAT(issued_at, '%d-%m-%Y') AS issued_date FROM ts_nlplates_document_versions WHERE document_id = ?"

local function loadVersion(row)
    local version = MySQL.single.await(versionsQuery, {row.id})
    row.revision = version and tonumber(version.revision) or 1
    row.current_date = version and version.issued_date or row.issued_date
    return row
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Kentekenbewijs', description = message, type = kind or 'inform'
    })
end

local function reservePlate()
    if not ready then return false end
    for _ = 1, 100 do
        local plate = TSPlate.generate(Config.PlateFormat)
        if not bridge:VehicleExists(plate) then
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
        if bridge:VehicleExists(oldPlate) then
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
    born[entity] = GetGameTimer()
    SetTimeout(750, function() formatNPC(entity) end)
end)
AddEventHandler('entityRemoved', function(entity)
    npcDone[entity], npcBusy[entity], born[entity] = nil, nil, nil
end)

local function companyLabel(job)
    return Config.CompanyNames[job]
        or bridge:GetCompanyLabel(job)
        or job
end

local function ownership(plate)
    local row = bridge:GetVehicleOwner(plate)
    if row then
        if row.job then return {name = companyLabel(row.job), job = row.job} end
        return {name = row.name and row.name:match('%S') and row.name
            or Config.Registration.unknownOwner, identifier = row.identifier}
    end
    local business = MySQL.single.await('SELECT job FROM ts_nlplates_business_vehicles WHERE plate = ?', {plate})
    if business then return {name = companyLabel(business.job), job = business.job} end
    return {name = Config.Registration.unknownOwner}
end

local function ownerOf(plate) return ownership(plate).name end

local function metadataFor(row, owner, old)
    local revision = old and (tonumber(old.revision) or 1) or row.revision or 1
    old = old or {}
    local valid = revision == (row.revision or 1)
    local number = ('TS-%07d'):format(row.id)
    if revision > 1 then number = number .. ('-%02d'):format(revision) end
    local status = valid and 'GELDIG' or 'NIETIG VERKLAARD'
    return {
        plate = row.plate, documentId = tostring(row.id), revision = revision,
        documentNumber = number, valid = valid, status = status,
        model = tonumber(row.model), owner = owner,
        issued = valid and (row.current_date or row.issued_date) or old.issued or row.issued_date,
        description = ('%s | %s\nKenteken: %s\nGeregistreerde eigenaar: %s'):format(status, number, row.plate, owner)
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
        loadVersion(row)
        local items = bridge:GetInventoryItems(payload.inventoryId) or {}
        local current
        for _, item in pairs(items) do
            if item.name == Config.Registration.item and item.metadata
                and tostring(item.metadata.documentId) == tostring(row.id) then
                current = item
                break
            end
        end
        if current then
            bridge:SetItemMetadata(payload.inventoryId, current.slot, metadataFor(row, ownerOf(plate), current.metadata))
            if tonumber(row.issued) ~= 1 then
                MySQL.update.await('UPDATE ts_nlplates_documents SET issued = 1 WHERE id = ?', {row.id})
            end
        elseif tonumber(row.issued) ~= 1 then
            local success, reason = bridge:AddItem(payload.inventoryId, Config.Registration.item, 1,
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
    if hooksInstalled then return end
    hooksInstalled = bridge:RegisterInventoryHook('openInventory', ensureDocument, {typeFilter = {glovebox = true, trunk = true}}) ~= nil
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
        inventory = bridge:GetGloveboxId(raw)
        local inv = bridge:GetInventory(inventory)
        if not inv then return end
    end
    local item = bridge:GetInventorySlot(inventory, slot)
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
    loadVersion(row)
    local owner = ownerOf(row.plate)
    -- Na database-await opnieuw bezit en afstand controleren.
    local held = resolveHeldItem(src, request)
    if not held or tostring(held.metadata.documentId) ~= tostring(row.id) or not validTarget(src, target) then return end
    -- Reissue kan tijdens de owner-query afgerond zijn: lees de geldigheid opnieuw.
    loadVersion(row)
    local data = metadataFor(row, owner, held.metadata)
    bridge:SetItemMetadata(inventory, item.slot, data)
    TriggerClientEvent('ts_nlplates:document:display', target, data, target == src)
    if target ~= src then notify(src, 'Kentekenbewijs getoond aan de speler.') end
end)

-- De command-route gebruikt uitsluitend een bestaand bewijs in het eigen dashboardkastje.
lib.callback.register('ts_nlplates:document:glovebox', function(src, netId)
    if not ready or not Config.Registration.enabled then return end
    local entity = vehicleFromId(netId)
    if not entity or GetVehiclePedIsIn(GetPlayerPed(src), false) ~= entity then return end
    local raw = GetVehicleNumberPlateText(entity)
    local id = bridge:GetGloveboxId(raw)
    local inv = bridge:GetInventory(id)
    if not inv then return end
    for _, item in pairs(inv.items or {}) do
        if item.name == Config.Registration.item then return item.slot end
    end
end)

AddEventHandler('playerDropped', function() lastUse[source], replacementUse[source] = nil, nil end)
AddEventHandler('ts_bridge:inventoryStopped', function() hooksInstalled = false end)
AddEventHandler('ts_bridge:inventoryReady', function() SetTimeout(1000, installHooks) end)

-- Koppeling voor jobgarage-spawners: controleer echte serverconfig, job, model en locatie.
RegisterNetEvent('ts_nlplates:business:register', function(netId)
    local src = source
    if not ready then return end
    local vehicle = vehicleFromId(netId)
    local player = bridge:GetPlayerData(src)
    local ped = GetPlayerPed(src)
    if not vehicle or not player or ped == 0 or not born[vehicle]
        or GetGameTimer() - born[vehicle] > 60000 then return end
    if GetPlayerRoutingBucket(src) ~= GetEntityRoutingBucket(vehicle)
        or #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) > 10 then return end
    local plate = normalize(GetVehicleNumberPlateText(vehicle))
    if plate == '' or #plate > 8 then return end
    if bridge:VehicleExists(plate) then return end
    local ok, garages = pcall(function() return bridge:GetJobGarages() end)
    if not ok or type(garages) ~= 'table' then return end
    local job = player.job
    if not job then return end
    for name, garage in pairs(garages) do
        local allowed = false
        if type(garage.job) == 'string' then allowed = garage.job == job.name end
        if type(garage.job) == 'table' then
            for _, candidate in pairs(garage.job) do if candidate == job.name then allowed = true end end
        end
        if allowed and garage.vehiclesType == 'spawner' and garage.coords
            and #(GetEntityCoords(vehicle) - vector3(garage.coords.x, garage.coords.y, garage.coords.z)) <= 50 then
            for _, definition in pairs(garage.vehicles or {}) do
                local model = type(definition.model) == 'number' and definition.model or joaat(definition.model or '')
                if model == GetEntityModel(vehicle) and (tonumber(job.grade) or 0) >= (definition.minJobGrade or 0) then
                    -- Persoonlijke voertuigen hebben hierboven voorrang; geen clientnaam gebruiken.
                    MySQL.query.await([[
                        INSERT INTO ts_nlplates_business_vehicles (plate, job, model, garage) VALUES (?, ?, ?, ?)
                        ON DUPLICATE KEY UPDATE job = VALUES(job), model = VALUES(model), garage = VALUES(garage)
                    ]], {plate, job.name, tostring(model), name})
                    return
                end
            end
        end
    end
end)

local function atCounter(src)
    local ped, c = GetPlayerPed(src), counter
    return c and ped ~= 0 and GetPlayerRoutingBucket(src) == 0
        and #(GetEntityCoords(ped) - vector3(c.x, c.y, c.z)) <= Config.Replacement.serverDistance
end

lib.callback.register('ts_nlplates:counter:get', function() return counter end)

RegisterCommand(Config.Replacement.placeCommand, function(src, args)
    if src == 0 then return print('[ts_nlplates] Gebruik dit commando ingame.') end
    if not bridge:HasPermission(src, {groups = Config.Replacement.adminGroups}) then
        return notify(src, 'Geen toegang: admin, owner, superadmin of god vereist.', 'error')
    end
    if not ready then return notify(src, 'Registratie is nog niet gereed.', 'error') end
    if GetPlayerRoutingBucket(src) ~= 0 then return notify(src, 'Plaats het loket in de normale wereld.', 'error') end
    local location
    if args[1] ~= 'verwijder' then
        local ped = GetPlayerPed(src)
        if ped == 0 then return end
        local pos = GetEntityCoords(ped)
        location = {x = pos.x, y = pos.y, z = pos.z}
    end
    local ok = pcall(MySQL.query.await,
        'INSERT INTO ts_nlplates_settings (id, value) VALUES (?, ?) ON DUPLICATE KEY UPDATE value = VALUES(value)',
        {'counter', json.encode(location or false)})
    if not ok then return notify(src, 'Locatie opslaan mislukt; controleer de serverconsole.', 'error') end
    counter = location
    TriggerClientEvent('ts_nlplates:counter:update', -1, counter or false)
    notify(src, location and 'Kentekenloket geplaatst en opgeslagen.' or 'Kentekenloket verwijderd.')
end, false)

local function mayReplace(src, plate)
    local player = bridge:GetPlayerData(src)
    if not player then return false end
    local record = ownership(plate)
    if record.identifier then return player.identifier == record.identifier end
    if record.job then
        local job = player.job
        return job and job.name == record.job and (tonumber(job.grade) or 0) >= Config.Replacement.companyMinGrade
    end
    return false
end

lib.callback.register('ts_nlplates:document:replace', function(src, rawPlate)
    if not ready or not Config.Registration.enabled or not Config.Replacement.enabled then
        return {ok = false, message = 'Het loket is niet beschikbaar.'}
    end
    if type(rawPlate) ~= 'string' or #rawPlate > 32 or not atCounter(src) then
        return {ok = false, message = 'Ga naar het kentekenloket.'}
    end
    local plate = normalize(rawPlate)
    if #plate == 0 or #plate > 8 or not plate:match('^[A-Z0-9 ]+$') then
        return {ok = false, message = 'Vul het kenteken in met spaties, bijvoorbeeld O 396 MV.'}
    end
    if replacementBusy[plate] or issuing[plate] then
        return {ok = false, message = 'Voor dit kenteken loopt al een aanvraag.'}
    end
    local now = GetGameTimer()
    if replacementUse[src] and now - replacementUse[src] < Config.Replacement.cooldownSeconds * 1000 then
        return {ok = false, message = 'Wacht even voordat je opnieuw een aanvraag doet.'}
    end
    replacementUse[src] = now
    replacementBusy[plate], issuing[plate] = true, true
    local result, chargedPlayer, chargedAmount
    local committed = false
    local paymentKey = 'payment:' .. plate
    local function clearPayment()
        MySQL.query.await('DELETE FROM ts_nlplates_settings WHERE id = ?', {paymentKey})
    end
    local ok, err = pcall(function()
        if MySQL.scalar.await('SELECT value FROM ts_nlplates_settings WHERE id = ?', {paymentKey}) then
            result = {ok = false, message = 'Een eerdere betaling moet eerst door een beheerder worden gecontroleerd.'}
            return
        end
        if not mayReplace(src, plate) then
            result = {ok = false, message = 'Dit voertuig staat niet op jouw naam, of je bedrijfsrang is te laag.'}
            return
        end
        local row = MySQL.single.await(
            "SELECT *, DATE_FORMAT(created_at, '%d-%m-%Y') AS issued_date FROM ts_nlplates_documents WHERE plate = ?", {plate})
        if not row then
            result = {ok = false, message = 'Er is nog geen bewijs uitgegeven. Open eerst het dashboardkastje.'}
            return
        end
        loadVersion(row)
        local data = metadataFor(row, ownerOf(plate))
        if not atCounter(src) or not mayReplace(src, plate) then
            result = {ok = false, message = 'De aanvraag is vervallen. Blijf bij het loket.'}
            return
        end
        -- Uniek uitgiftenummer; mislukte aanvragen worden nooit opnieuw geactiveerd.
        local issueId = MySQL.insert.await('INSERT INTO ts_nlplates_document_issues (document_id) VALUES (?)', {row.id})
        if not issueId or issueId < 1 then error('Geen uitgiftenummer beschikbaar') end
        row.revision = issueId + 1
        row.current_date = os.date('%d-%m-%Y')
        data = metadataFor(row, data.owner)
        local cost = Config.Replacement.price
        local account = Config.Replacement.account == 'money' and 'cash' or Config.Replacement.account
        local balance = bridge:GetMoney(src, account)
        if not balance or balance < cost then
            result = {ok = false, message = 'Onvoldoende of niet beschikbaar saldo.'}
            return
        end
        if cost > 0 then
            if bridge:GetSocietyBalance(Config.Replacement.society) == nil then
                result = {ok = false, message = 'De politierekening is niet beschikbaar. Er is niets afgeschreven.'}
                return
            end
            -- Bewaar vóór de eerste geldmutatie; ook na een crash geen automatische herhaling.
            local payer = bridge:GetPlayerData(src)
            MySQL.query.await('INSERT INTO ts_nlplates_settings (id, value) VALUES (?, ?)',
                {paymentKey, json.encode({identifier = payer and payer.identifier, plate = plate,
                    amount = cost, account = account, society = Config.Replacement.society,
                    document = data.documentNumber, created = os.time()})})
            local debit = bridge:RemoveMoney(src, account, cost, 'Vervangend kentekenbewijs')
            if not debit or not debit.ok then
                if not debit or debit.uncertain then
                    print(('[ts_nlplates] BETALING CONTROLEREN speler=%s kenteken=%s bedrag=%s: %s'):format(src, plate, cost, json.encode(debit or {})))
                end
                if debit and not debit.uncertain then clearPayment() end
                result = {ok = false, message = 'Betaling niet bevestigd. Laat een beheerder de betaling controleren voordat je opnieuw aanvraagt.'}
                return
            end
            chargedPlayer, chargedAmount = src, cost
        end
        local added, response = bridge:AddItem(src, Config.Registration.item, 1, data)
        if not added then
            result = {ok = false, message = 'Geen vrije inventarisruimte. Je oude bewijs blijft geldig; een afschrijving wordt terugbetaald.'}
            return
        end
        -- Voeg eerst toe: een volle inventaris maakt het oude bewijs niet ongeldig.
        -- Bij DB-falen is de nieuwe revisie nooit geactiveerd en blijft de oude geldig.
        committed = MySQL.transaction.await({
            {query = [[INSERT INTO ts_nlplates_document_versions (document_id, revision, issued_at)
                VALUES (?, ?, CURRENT_TIMESTAMP) ON DUPLICATE KEY UPDATE
                revision = VALUES(revision), issued_at = CURRENT_TIMESTAMP]], values = {row.id, row.revision}},
            {query = 'UPDATE ts_nlplates_documents SET issued = 1 WHERE id = ?', values = {row.id}}
        })
        if not committed then
            bridge:RemoveItem(src, Config.Registration.item, 1, data)
            result = {ok = false, message = 'Opslaan mislukt. Het oude bewijs blijft geldig.'}
            return
        end
        if cost > 0 then
            local paid = bridge:AddSocietyMoney(Config.Replacement.society, cost)
            if not paid or not paid.ok then
                print(('[ts_nlplates] POLITIEBETALING CONTROLEREN document=%s bedrag=%s: %s'):format(data.documentNumber, cost, json.encode(paid or {})))
                result = {ok = true, message = 'Nieuw bewijs ontvangen; het vorige is nietig. Meld de niet-bevestigde politiebetaling bij een beheerder.'}
                return
            end
        end
        if cost > 0 then clearPayment() end
        result = {ok = true, message = ('Nieuw bewijs %s ontvangen. Het vorige bewijs is nietig verklaard.'):format(data.documentNumber)}
    end)
    if chargedPlayer and not committed then
        local refundedOk, refund = pcall(function()
            return bridge:AddMoney(chargedPlayer, Config.Replacement.account == 'money' and 'cash' or Config.Replacement.account,
                chargedAmount, 'Terugbetaling kentekenbewijs')
        end)
        if refundedOk and refund and refund.ok then
            local cleared = pcall(clearPayment)
            if not cleared then print('[ts_nlplates] Terugbetaald; betaalmarkering handmatig controleren: ' .. paymentKey) end
        end
        if not refundedOk or not refund or not refund.ok then
            print(('[ts_nlplates] TERUGBETALING CONTROLEREN speler=%s kenteken=%s bedrag=%s'):format(src, plate, chargedAmount))
            result = {ok = false, message = 'Aanvraag mislukt; terugbetaling niet bevestigd. Neem contact op met een beheerder.'}
        end
    end
    replacementBusy[plate], issuing[plate] = nil, nil
    if not ok then
        print('[ts_nlplates] Vervanging mislukt: ' .. tostring(err))
        return {ok = false, message = 'Aanvraag mislukt. Controleer de serverconsole.'}
    end
    return result
end)

MySQL.ready(function()
    local ok, err = pcall(function()
        assert(bridge:VehicleIntegrationReady())
        TSPlate.generate(Config.PlateFormat)
        assert(type(Config.Replacement.price) == 'number' and Config.Replacement.price >= 0
            and Config.Replacement.price % 1 == 0, 'Replacement.price moet een geheel bedrag >= 0 zijn')
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
        local extra = {
            ts_nlplates_settings = [[CREATE TABLE IF NOT EXISTS ts_nlplates_settings (
                id VARCHAR(32) NOT NULL PRIMARY KEY,
                value LONGTEXT NOT NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
            ts_nlplates_document_issues = [[CREATE TABLE IF NOT EXISTS ts_nlplates_document_issues (
                id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                document_id INT UNSIGNED NOT NULL,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
            ts_nlplates_document_versions = [[CREATE TABLE IF NOT EXISTS ts_nlplates_document_versions (
                document_id INT UNSIGNED NOT NULL PRIMARY KEY,
                revision INT UNSIGNED NOT NULL DEFAULT 1,
                issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
            ts_nlplates_business_vehicles = [[CREATE TABLE IF NOT EXISTS ts_nlplates_business_vehicles (
                plate VARCHAR(8) NOT NULL PRIMARY KEY,
                job VARCHAR(64) NOT NULL,
                model VARCHAR(32) NOT NULL,
                garage VARCHAR(100) NOT NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]
        }
        for name, ddl in pairs(extra) do
            if not pcall(MySQL.query.await, 'SELECT * FROM ' .. name .. ' LIMIT 0') then
                MySQL.query.await(ddl)
            end
        end
        local saved = MySQL.scalar.await("SELECT value FROM ts_nlplates_settings WHERE id = 'counter'")
        if saved then
            local decoded, value = pcall(json.decode, saved)
            if decoded and type(value) == 'table' and type(value.x) == 'number'
                and type(value.y) == 'number' and type(value.z) == 'number' then counter = value end
        end
        TriggerClientEvent('ts_nlplates:counter:update', -1, counter or false)
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
