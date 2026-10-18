if TSBridgeValidation and not TSBridgeValidation.valid then return end
-- Eén menu per aanroepende resource/id; IDs worden automatisch gescheiden.
local menus = {}
local function menuKey(owner, id) return owner .. ':' .. id end
local function remove(owner, id)
    local owned = menus[owner]
    if not owned or not owned[id] then return false end
    local key = menuKey(owner, id)
    if GetResourceState('ox_lib') == 'started' then
        lib.removeRadialItem(key)
        lib.registerRadial({ id = key, items = {} })
    end
    owned[id] = nil
    return true
end
exports('RegisterRadialMenu', function(data)
    local owner = GetInvokingResource()
    if not owner or type(data) ~= 'table' or type(data.id) ~= 'string'
        or data.id == '' or type(data.label) ~= 'string' or type(data.items) ~= 'table' then return false end
    local key = menuKey(owner, data.id)
    lib.registerRadial({ id = key, items = data.items })
    lib.addRadialItem({ id = key, label = data.label, icon = data.icon or 'circle', menu = key })
    menus[owner] = menus[owner] or {}
    menus[owner][data.id] = { label = data.label, icon = data.icon or 'circle', items = data.items }
    return true
end)
exports('RemoveRadialMenu', function(id)
    local owner = GetInvokingResource()
    if not owner or type(id) ~= 'string' then return false end
    return remove(owner, id)
end)
AddEventHandler('onClientResourceStop', function(name)
    for owner, ids in pairs(menus) do
        if name == owner or name == GetCurrentResourceName() then
            for id in pairs(ids) do remove(owner, id) end
            menus[owner] = nil
        end
    end
end)

AddEventHandler('onClientResourceStart', function(name)
    if name ~= 'ox_lib' then return end
    for owner, ids in pairs(menus) do
        if GetResourceState(owner) ~= 'started' then menus[owner] = nil
        else
            for id, data in pairs(ids) do
                local key = menuKey(owner, id)
                lib.registerRadial({ id = key, items = data.items })
                lib.addRadialItem({ id = key, menu = key, label = data.label, icon = data.icon })
            end
        end
    end
end)
