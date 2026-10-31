local function openMenu(request)
    lib.registerContext({
        id = 'ts_nlplates_document', title = 'Kentekenbewijs',
        options = {
            {title = 'Bekijken', icon = 'id-card', onSelect = function()
                TriggerServerEvent('ts_nlplates:document:show', request)
            end},
            {title = 'Tonen aan speler', description = 'Kies iemand binnen 3 meter', icon = 'user',
                onSelect = function()
                    local options = {}
                    for _, nearby in ipairs(lib.getNearbyPlayers(GetEntityCoords(PlayerPedId()),
                        Config.Registration.showDistance, false)) do
                        local serverId = GetPlayerServerId(nearby.id)
                        options[#options + 1] = {
                            title = ('Speler %s'):format(serverId),
                            onSelect = function()
                                TriggerServerEvent('ts_nlplates:document:show', request, serverId)
                            end
                        }
                    end
                    if #options == 0 then
                        return lib.notify({description = 'Er staat niemand dichtbij genoeg.', type = 'error'})
                    end
                    lib.registerContext({id = 'ts_nlplates_players', title = 'Aan wie tonen?',
                        menu = 'ts_nlplates_document', options = options})
                    lib.showContext('ts_nlplates_players')
                end
            }
        }
    })
    lib.showContext('ts_nlplates_document')
end

exports('useRegistration', function(data, slot)
    if not Config.Registration.enabled then return end
    exports.ts_bridge:UseItem(data, function(used)
        if used then openMenu({slot = data.slot or (type(slot) == 'table' and slot.slot)}) end
    end)
end)

if Config.Registration.command then
    RegisterCommand(Config.Registration.command, function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == 0 then
            return lib.notify({description = 'Stap in een voertuig of gebruik het bewijs in je inventaris.', type = 'error'})
        end
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        local slot = lib.callback.await('ts_nlplates:document:glovebox', false, netId)
        if not slot then
            return lib.notify({description = 'Open eerst het dashboardkastje. Is het bewijs meegenomen? Gebruik het vanuit je inventaris.', type = 'error'})
        end
        exports.ts_bridge:CloseInventory()
        openMenu({slot = slot, netId = netId})
    end, false)
end

local visible, focused, displayToken = false, false, 0
local function closeCard()
    visible = false
    if focused then SetNuiFocus(false, false) end
    focused = false
    SendNUIMessage({action = 'close'})
end

RegisterNetEvent('ts_nlplates:document:display', function(data, own)
    local model = tonumber(data.model)
    local modelName = model and GetDisplayNameFromVehicleModel(model) or ''
    local brandName = model and GetMakeNameFromVehicleModel(model) or ''
    local function label(name)
        if name == '' or name == 'CARNOTFOUND' then return 'Onbekend' end
        local translated = GetLabelText(name)
        return translated ~= 'NULL' and translated or name
    end
    data.modelName, data.brandName = label(modelName), label(brandName)
    -- Sluit eigen document bij een nieuwe weergave; ontvanger krijgt geen muisblokkade.
    if focused then SetNuiFocus(false, false) end
    visible, focused = true, own == true
    displayToken = displayToken + 1
    local token = displayToken
    SendNUIMessage({action = 'open', data = data, own = own})
    if focused then SetNuiFocus(true, true) end
    SetTimeout(15000, function() if token == displayToken then closeCard() end end)
end)
RegisterNUICallback('close', function(_, cb) closeCard(); cb({ok = true}) end)
CreateThread(function()
    while true do
        Wait(visible and 0 or 500)
        if visible and not focused and IsControlJustReleased(0, 177) then closeCard() end
    end
end)
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then closeCard() end
end)

-- JG geeft geen bedrijfsnaam aan ons door. De server controleert zelf zijn garageconfig.
AddEventHandler('ts_bridge:vehicle:jobSpawned', function(vehicle)
    if not DoesEntityExist(vehicle) then return end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    SetTimeout(1000, function()
        if DoesEntityExist(vehicle) then TriggerServerEvent('ts_nlplates:business:register', netId) end
    end)
end)


if Config.Replacement.enabled then
    local counter, blip, prompt, applying
    local function updateCounter(data)
        if blip then RemoveBlip(blip); blip = nil end
        counter = type(data) == 'table' and data or nil
        if prompt then lib.hideTextUI(); prompt = false end
        if counter and Config.Replacement.blip then
            blip = AddBlipForCoord(counter.x, counter.y, counter.z)
            SetBlipSprite(blip, 525)
            SetBlipColour(blip, 2)
            SetBlipScale(blip, 0.75)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(Config.Replacement.label)
            EndTextCommandSetBlipName(blip)
        end
    end
    RegisterNetEvent('ts_nlplates:counter:update', updateCounter)
    CreateThread(function()
        updateCounter(lib.callback.await('ts_nlplates:counter:get', false))
        while true do
            local c = counter
            local distance = c and #(GetEntityCoords(PlayerPedId()) - vector3(c.x, c.y, c.z)) or 9999
            if c and distance < 20 then
                DrawMarker(1, c.x, c.y, c.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.8, 0.8, 0.2, 65, 175, 115, 160, false, false, 2, false, nil, nil, false)
            end
            if distance <= Config.Replacement.interactDistance and not applying then
                if not prompt then lib.showTextUI('[E] ' .. Config.Replacement.label); prompt = true end
                if IsControlJustReleased(0, 38) then
                    applying = true
                    lib.hideTextUI(); prompt = false
                    local input = lib.inputDialog(Config.Replacement.label, {
                        {type = 'input', label = 'Kenteken', description = 'Met spaties, bijvoorbeeld O 396 MV',
                            required = true, min = 1, max = 8},
                        {type = 'checkbox', label = ('Nieuw bewijs: €%s. Vorig bewijs nietig verklaren.'):format(Config.Replacement.price),
                            required = true}
                    })
                    if input and input[2] then
                        local ok, result = pcall(lib.callback.await, 'ts_nlplates:document:replace', false, input[1])
                        lib.notify({title = Config.Replacement.label,
                            description = ok and result and result.message or 'Het loket reageert niet.',
                            type = ok and result and result.ok and 'success' or 'error'})
                    end
                    applying = false
                end
            elseif prompt then
                lib.hideTextUI(); prompt = false
            end
            Wait(distance < 20 and 0 or 750)
        end
    end)
    AddEventHandler('onResourceStop', function(name)
        if name == GetCurrentResourceName() then
            if prompt then lib.hideTextUI() end
            if blip then RemoveBlip(blip) end
        end
    end)
end
