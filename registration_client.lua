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
    exports.ox_inventory:useItem(data, function(used)
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
        exports.ox_inventory:closeInventory()
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
