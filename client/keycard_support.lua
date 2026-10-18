if TSBridgeValidation and not TSBridgeValidation.valid then return end
-- Ondersteuning voor lokale uitgifte-NPC's; de resource blijft eigenaar van de ped.
local entities = {}
local function remove(entity, name)
    if GetResourceState(TSBridgeConfig.TargetResource) == 'started' then
        exports[TSBridgeConfig.TargetResource]:removeLocalEntity(entity, name)
    end
end
exports('AddLocalEntity', function(entity, options)
    local owner = GetInvokingResource()
    if not owner or type(entity) ~= 'number' or not DoesEntityExist(entity) or type(options) ~= 'table' then return false end
    if GetResourceState(TSBridgeConfig.TargetResource) ~= 'started' then return false end
    local names = {}
    for _, option in ipairs(options) do
        if type(option.name) ~= 'string' or option.name:sub(1, #owner + 1) ~= owner .. '_' then
            return false, 'invalid_option_name'
        end
        names[#names + 1] = option.name
    end
    exports[TSBridgeConfig.TargetResource]:addLocalEntity(entity, options)
    entities[owner] = entities[owner] or {}
    entities[owner][entity] = entities[owner][entity] or {}
    for index, name in ipairs(names) do entities[owner][entity][name] = options[index] end
    return true
end)
exports('RemoveLocalEntity', function(entity, name)
    local owner = GetInvokingResource()
    local options = owner and entities[owner] and entities[owner][entity]
    if not options or not options[name] then return false end
    remove(entity, name)
    options[name] = nil
    if not next(options) then entities[owner][entity] = nil end
    return true
end)
AddEventHandler('onClientResourceStop', function(name)
    if name == TSBridgeConfig.TargetResource then return end
    for owner, list in pairs(entities) do
        if name == owner or name == GetCurrentResourceName() then
            for entity, options in pairs(list) do
                for option in pairs(options) do remove(entity, option) end
            end
            entities[owner] = nil
        end
    end
end)
exports('UseItem', function(data, callback)
    local mt = type(callback) == 'table' and getmetatable(callback)
    if type(callback) ~= 'function' and not (type(mt) == 'table' and mt.__call) then return false, 'invalid_callback' end
    if GetResourceState(TSBridgeConfig.InventoryResource) ~= 'started' then
        callback(nil)
        return false, 'inventory_unavailable'
    end
    exports[TSBridgeConfig.InventoryResource]:useItem(data, callback)
    return true -- Afhandeling volgt via callback; geen bewijs dat het item is gebruikt.
end)
exports('ProgressCircle', function(options) return lib.progressCircle(options) end)
exports('InputDialog', function(title, rows, options) return lib.inputDialog(title, rows, options) end)
exports('AlertDialog', function(options) return lib.alertDialog(options) end)

AddEventHandler('onClientResourceStart', function(name)
    if name ~= TSBridgeConfig.TargetResource then return end
    for owner, list in pairs(entities) do
        if GetResourceState(owner) ~= 'started' then entities[owner] = nil
        else
            for entity, options in pairs(list) do
                if DoesEntityExist(entity) then
                    local restored = {}; for _, option in pairs(options) do restored[#restored+1] = option end
                    exports[name]:addLocalEntity(entity, restored)
                else list[entity] = nil end
            end
        end
    end
end)
